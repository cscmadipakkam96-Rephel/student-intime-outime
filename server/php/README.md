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

## 2. Schedule Daily Reminder cron (`cron/scheduleReminders.php`, `models/ReminderLog.php`, `sql/029_reminder_log.sql`)

Replaces the old Node `scheduleReminder.job.js` cron. Every 1-2 minutes,
checks every active student whose class meets today (`class_days`), and
fires a "check in"/"check out" reminder 5 minutes after their resolved
class time if they haven't marked attendance yet — reusing
`effectiveScheduleFor()` / `classDaysByAdmissionId()`, which already existed
in `controllers/notificationController.php`. Writes a row to `notifications`
(picked up by the app's existing poll/ack flow) and to the new
`reminder_log` table (dedup — at most one reminder per student per type per
day).

**Admin action needed:** in Hostinger hPanel → Cron Jobs, add a job that
hits this URL every 1-2 minutes:

```
https://app.cscitedu.com/server/cron/scheduleReminders.php?key=<CRON_SECRET>
```

(`CRON_SECRET` is set in the server's `.env` — not written here, ask
whoever has FTP/`.env` access for the current value.) Confirm the exact
public URL/routing prefix matches how other `/api/...` routes resolve on
this host.

## 3. Attendance-summary reverse endpoint — retired, not migrated

The old Node `GET /api/v1/attendance-summary` (which `STUDENT_APP_ATTENDANCE_API_URL`
in the PHP `.env` still points to) read from the Node backend's own
Postgres `attendance` table. Since student check-in/out now writes directly
to this PHP backend's own `student_entry_attendances` table, that data is
already native here — no reason to call back out to the old backend for it.
Once the old Node/EC2 backend is retired, anything still calling that URL
should query this backend's own tables directly instead.
