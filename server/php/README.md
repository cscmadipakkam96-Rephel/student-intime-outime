# PHP backend additions (Course Admission / app.cscitedu.com)

This folder mirrors the relative paths of the **live PHP backend on Hostinger**
(FTP root `server/`) — it is **not** run from here; it is deployed via FTP to
that server. Kept here purely so these additions are version-controlled
somewhere, since the PHP project itself isn't in this git repo.

These files fill the 3 gaps identified when migrating the Flutter app off
the old Node/EC2 backend (`server/` at the repo root) onto the PHP backend:

## 1. Class recordings (`controllers/recordingController.php`, `api/videos/recordings.php`, `api/videos/recordings-stream.php`)

Replaces the old S3-backed `/api/videos/recordings` (Node). Recordings now
live under `uploads/recordings/<comn_enrol_no>/<filename>` on the PHP
server's own disk (FTP-uploaded manually, same as before — there's no
in-app upload flow, matching the old S3 setup). Listing returns a
short-lived signed-token stream URL per file (mirrors
`course-videos/stream.php`'s existing pattern) rather than exposing the
file path directly — `uploads/.htaccess` already denies direct access to
the whole `uploads/` tree.

**Admin action needed:** upload recording files via FTP into
`server/uploads/recordings/<comn_enrol_no>/`, matching the old S3 prefix
convention.

## 2. Schedule Daily Reminder (`utils/scheduleReminderRunner.php`, `models/ReminderLog.php`, `sql/029_reminder_log.sql`, `cron/scheduleReminders.php`)

Replaces the old Node `scheduleReminder.job.js` cron. For every active
student whose class meets today (`class_days`), fires a "check in"/"check
out" reminder 5 minutes after their resolved class time if they haven't
marked attendance yet — reusing `effectiveScheduleFor()` /
`classDaysByAdmissionId()`, which already existed in
`controllers/notificationController.php`. Writes a row to `notifications`
(picked up by the app's existing poll/ack flow) and to the new
`reminder_log` table (dedup — at most one reminder per student per type per
day).

**Trigger mechanism — no cron-job access on this host (FTP + phpMyAdmin
only), so this piggybacks on ordinary app traffic instead of a real cron:**
`config/bootstrap.php` calls `maybeRunScheduleReminderCheck()` on every
request, which runs the actual check only once at least 2 minutes have
passed since the last time any request triggered it (tracked via
`uploads/.reminder_check_last_run`'s mtime). Confirmed working live —
skips on rapid repeat requests, runs again once the interval has passed.
Timing is therefore traffic-dependent (fires shortly after the next real
request past the 5-minute mark) rather than a guaranteed interval, but
needs zero hosting-panel access.

`cron/scheduleReminders.php` still exists as an optional manual-trigger
endpoint (`?key=<CRON_SECRET>`, set in `.env`) — useful for testing, or if
real Hostinger cron access becomes available later (point a cron job at it
and it'll work standalone, no code change needed).

## 3. Attendance-summary reverse endpoint — retired, not migrated

The old Node `GET /api/v1/attendance-summary` (which `STUDENT_APP_ATTENDANCE_API_URL`
in the PHP `.env` still points to) read from the Node backend's own
Postgres `attendance` table. Since student check-in/out now writes directly
to this PHP backend's own `student_entry_attendances` table, that data is
already native here — no reason to call back out to the old backend for it.
Once the old Node/EC2 backend is retired, anything still calling that URL
should query this backend's own tables directly instead.
