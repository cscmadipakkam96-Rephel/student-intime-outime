<?php
require_once __DIR__ . '/../models/StudentEntryAttendance.php';
require_once __DIR__ . '/../utils/response.php';

// Flutter Student App self-service attendance — a student checking
// themselves in/out of campus from the app, writing to the same
// student_entry_attendances table the admin's Entry Attendance page and
// kiosk QR scan already use (see StudentEntryAttendance.php), so an app
// check-in shows up there too instead of living in a separate record.

function studentAttendanceIstToday(): string
{
    return (new DateTime('now', new DateTimeZone('Asia/Kolkata')))->format('Y-m-d');
}

// marked_at/out_time are plain "YYYY-MM-DD HH:MM:SS" IST wall-clock values
// (see StudentEntryAttendance::create()/markOut()) with no timezone marker
// of their own — stamping +05:30 here is what lets the Flutter app's
// DateTime.parse(...).toLocal() convert them correctly instead of
// mis-reading them as whatever timezone the device happens to be in.
function toIstIso(?string $datetime): ?string
{
    if (!$datetime) {
        return null;
    }
    return str_replace(' ', 'T', $datetime) . '+05:30';
}

function studentAttendanceIn(array $authPayload): void
{
    $admissionId = (int) $authPayload['admissionId'];
    $today = studentAttendanceIstToday();

    $existing = StudentEntryAttendance::findTodayForAdmission($admissionId, $today);
    if ($existing) {
        jsonError('Already marked in for today', 409);
    }

    $record = StudentEntryAttendance::create($admissionId, $authPayload['admin_id'] ?? null, $today);
    jsonResponse(201, [
        'success' => true,
        'data' => [
            'id' => (int) $record['id'],
            'date' => $record['date'],
            'in_time' => toIstIso($record['marked_at']),
            'out_time' => toIstIso($record['out_time']),
        ],
    ]);
}

function studentAttendanceOut(array $authPayload): void
{
    $admissionId = (int) $authPayload['admissionId'];
    $today = studentAttendanceIstToday();

    $existing = StudentEntryAttendance::findTodayForAdmission($admissionId, $today);
    if (!$existing) {
        jsonError('You have not marked in yet today', 400);
    }
    if ($existing['out_time']) {
        jsonError('Already marked out for today', 409);
    }

    $record = StudentEntryAttendance::markOut((int) $existing['id']);
    jsonResponse(200, [
        'success' => true,
        'data' => [
            'id' => (int) $record['id'],
            'date' => $record['date'],
            'in_time' => toIstIso($record['marked_at']),
            'out_time' => toIstIso($record['out_time']),
        ],
    ]);
}

function getStudentAttendanceHistory(array $authPayload): void
{
    $admissionId = (int) $authPayload['admissionId'];
    $limit = isset($_GET['limit']) ? max(1, min(365, (int) $_GET['limit'])) : 30;

    $rows = StudentEntryAttendance::findHistoryForAdmission($admissionId, $limit);
    $data = array_map(fn($r) => [
        'id' => (int) $r['id'],
        'date' => $r['date'],
        'in_time' => toIstIso($r['marked_at']),
        'out_time' => toIstIso($r['out_time']),
    ], $rows);

    jsonSuccess($data);
}
