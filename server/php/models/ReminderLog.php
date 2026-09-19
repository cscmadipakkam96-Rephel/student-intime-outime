<?php
require_once __DIR__ . '/../config/db.php';

// Dedup guard for the schedule-reminder cron — the UNIQUE(admission_id,
// date, type) constraint on reminder_log makes a duplicate insert fail,
// which claim() treats as "already sent today, skip". Mirrors the old
// Node backend's ReminderLog model.
class ReminderLog
{
    public static function claim(int $admissionId, string $date, string $type): bool
    {
        try {
            $stmt = getDb()->prepare('INSERT INTO reminder_log (admission_id, date, type) VALUES (?, ?, ?)');
            $stmt->execute([$admissionId, $date, $type]);
            return true;
        } catch (PDOException $e) {
            if ((int) $e->errorInfo[1] === 1062) { // duplicate key — already claimed today
                return false;
            }
            throw $e;
        }
    }
}
