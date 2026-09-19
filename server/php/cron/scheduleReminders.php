<?php
require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../controllers/notificationController.php';
require_once __DIR__ . '/../models/StudentEntryAttendance.php';
require_once __DIR__ . '/../models/ReminderLog.php';
require_once __DIR__ . '/../models/Notification.php';

// Runs every 1-2 minutes via a Hostinger cron job hitting this URL with
// ?key=<CRON_SECRET> — mirrors the old Node backend's
// scheduleReminder.job.js + scheduleReminder.service.js. The effective-time
// computation (effectiveScheduleFor, classDaysByAdmissionId) already lives
// in notificationController.php — reused as-is rather than duplicated.

if (($_GET['key'] ?? '') !== env('CRON_SECRET')) {
    http_response_code(403);
    exit;
}

function nowIst(): array
{
    $now = new DateTime('now', new DateTimeZone('Asia/Kolkata'));
    return [
        'date' => $now->format('Y-m-d'),
        'minutes' => ((int) $now->format('H')) * 60 + (int) $now->format('i'),
        'dayName' => $now->format('l'), // "Monday"
    ];
}

function hhmmToMinutes(?string $hhmm): ?int
{
    if (!$hhmm) {
        return null;
    }
    [$h, $m] = array_map('intval', explode(':', $hhmm));
    return $h * 60 + $m;
}

['date' => $today, 'minutes' => $nowMinutes, 'dayName' => $dayName] = nowIst();

$admissions = getDb()->query('SELECT * FROM admissions WHERE active = 1')->fetchAll();
$admissionIds = array_column($admissions, 'id');
$classDaysByAdmission = classDaysByAdmissionId($admissionIds);

$dueToday = array_values(array_filter(
    $admissions,
    fn($a) => in_array($dayName, $classDaysByAdmission[$a['id']] ?? [], true)
));

if (empty($dueToday)) {
    jsonSuccess(['checked' => 0, 'sent' => 0]);
}

$dueIds = array_column($dueToday, 'id');
$attendanceRows = StudentEntryAttendance::findByAdmissionIdsAndDates($dueIds, [$today]);
$attendanceByAdmission = [];
foreach ($attendanceRows as $row) {
    $attendanceByAdmission[$row['admission_id']] = $row;
}

$sent = 0;
foreach ($dueToday as $admission) {
    $schedule = effectiveScheduleFor($admission);
    $record = $attendanceByAdmission[$admission['id']] ?? null;

    $checks = [
        ['type' => 'in', 'target' => hhmmToMinutes($schedule['effective_in_time']), 'done' => !empty($record['marked_at'])],
        ['type' => 'out', 'target' => hhmmToMinutes($schedule['effective_out_time']), 'done' => !empty($record['out_time'])],
    ];

    foreach ($checks as $check) {
        if ($check['target'] === null || $check['done']) {
            continue;
        }
        if ($nowMinutes < $check['target'] + 5) {
            continue;
        }
        if (!ReminderLog::claim((int) $admission['id'], $today, $check['type'])) {
            continue; // already reminded today
        }

        $isCustom = $schedule['source'] === 'schedule';
        $title = $isCustom
            ? $admission['notification_title']
            : ($check['type'] === 'in' ? 'Time to check in' : 'Time to check out');
        $description = $isCustom
            ? $admission['notification_description']
            : ($check['type'] === 'in'
                ? "It's time to check in for your class. Please open the app and check in."
                : "It's time to check out. Please open the app and check out.");

        if (!$title || !$description) {
            continue;
        }

        $notification = Notification::create($admission['admin_id'], (int) $admission['id'], $title, $description);

        try {
            $pushResult = pushNotificationToStudentApp($admission['comn_enrol_no'], $title, $description, $notification['id']);
            if ($pushResult['delivered']) {
                Notification::markDelivered($notification['id']);
            }
        } catch (Exception $e) {
            // Best-effort — the app's own poll/ack still picks this up regardless.
        }

        $sent++;
    }
}

jsonSuccess(['checked' => count($dueToday), 'sent' => $sent]);
