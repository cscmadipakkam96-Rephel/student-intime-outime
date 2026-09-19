<?php
require_once __DIR__ . '/../controllers/notificationController.php';
require_once __DIR__ . '/../models/StudentEntryAttendance.php';
require_once __DIR__ . '/../models/ReminderLog.php';
require_once __DIR__ . '/../models/Notification.php';

define('REMINDER_CHECK_INTERVAL_SECONDS', 120);
define('REMINDER_CHECK_MARKER_FILE', __DIR__ . '/../uploads/.reminder_check_last_run');

// Called from bootstrap.php on every request. This host has no cron-job
// access (FTP + phpMyAdmin only), so instead of a real cron, real app
// traffic itself triggers the check: cheap no-op most of the time (one
// filemtime() stat), only running the actual loop once at least
// REMINDER_CHECK_INTERVAL_SECONDS have passed since the last time any
// request triggered it. Timing is therefore traffic-dependent rather than
// a guaranteed interval — acceptable here since the app sees frequent
// traffic during class hours, which is when this matters. Swap back to a
// real cron hitting server/cron/scheduleReminders.php later with zero
// other changes if hPanel access becomes available.
function maybeRunScheduleReminderCheck(): void
{
    $last = is_file(REMINDER_CHECK_MARKER_FILE) ? filemtime(REMINDER_CHECK_MARKER_FILE) : 0;
    if (time() - $last < REMINDER_CHECK_INTERVAL_SECONDS) {
        return;
    }
    // Touch the marker before doing the work, so two near-simultaneous
    // requests don't both decide to run — ReminderLog's unique constraint
    // would still prevent any duplicate notification even if that
    // happened, but no reason to do the work twice.
    @touch(REMINDER_CHECK_MARKER_FILE);

    try {
        runScheduleReminderCheck();
    } catch (Exception $e) {
        error_log('Schedule reminder check failed: ' . $e->getMessage());
    }
}

function hhmmToMinutesForReminder(?string $hhmm): ?int
{
    if (!$hhmm) {
        return null;
    }
    [$h, $m] = array_map('intval', explode(':', $hhmm));
    return $h * 60 + $m;
}

// The actual check — every active student whose class meets today, 5
// minutes past their resolved class time, reminded once per day per type.
// Shared by the piggyback trigger above and the standalone cron endpoint
// (server/cron/scheduleReminders.php), so there's exactly one copy of this
// logic regardless of which trigger mechanism is in use.
function runScheduleReminderCheck(): array
{
    $now = new DateTime('now', new DateTimeZone('Asia/Kolkata'));
    $today = $now->format('Y-m-d');
    $nowMinutes = ((int) $now->format('H')) * 60 + (int) $now->format('i');
    $dayName = $now->format('l');

    $admissions = getDb()->query('SELECT * FROM admissions WHERE active = 1')->fetchAll();
    $admissionIds = array_column($admissions, 'id');
    $classDaysByAdmission = classDaysByAdmissionId($admissionIds);

    $dueToday = array_values(array_filter(
        $admissions,
        fn($a) => in_array($dayName, $classDaysByAdmission[$a['id']] ?? [], true)
    ));

    if (empty($dueToday)) {
        return ['checked' => 0, 'sent' => 0];
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
            ['type' => 'in', 'target' => hhmmToMinutesForReminder($schedule['effective_in_time']), 'done' => !empty($record['marked_at'])],
            ['type' => 'out', 'target' => hhmmToMinutesForReminder($schedule['effective_out_time']), 'done' => !empty($record['out_time'])],
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

    return ['checked' => count($dueToday), 'sent' => $sent];
}
