<?php
require_once __DIR__ . '/../config/bootstrap.php';
require_once __DIR__ . '/../utils/scheduleReminderRunner.php';

// Optional manual/real-cron trigger. The primary mechanism is now the
// piggyback check in bootstrap.php (maybeRunScheduleReminderCheck()) —
// this host has no cron-job access. This endpoint still works for manually
// forcing a check, or if real cron access becomes available later.
if (($_GET['key'] ?? '') !== env('CRON_SECRET')) {
    http_response_code(403);
    exit;
}

jsonSuccess(runScheduleReminderCheck());
