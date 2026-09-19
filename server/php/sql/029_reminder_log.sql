-- Prevents the schedule-reminder cron from re-firing the same "check
-- in"/"check out" nudge every poll cycle once it's already gone out for
-- that student, that day. Mirrors the old Node backend's ReminderLog table.
CREATE TABLE IF NOT EXISTS reminder_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admission_id INT NOT NULL,
    date DATE NOT NULL,
    type ENUM('in','out') NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_reminder (admission_id, date, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
