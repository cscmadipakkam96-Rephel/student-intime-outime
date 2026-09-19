<?php
require_once __DIR__ . '/../config/db.php';

// Mirrors server/models/StudentEntryAttendance.js — campus gate entry,
// independent of teacher-marked class attendance (Attendance.php).
class StudentEntryAttendance
{
    public static function findAllByAdmin(string $adminId): array
    {
        $stmt = getDb()->prepare('SELECT admission_id, date FROM student_entry_attendances WHERE admin_id = ?');
        $stmt->execute([$adminId]);
        return $stmt->fetchAll();
    }

    public static function findByAdmissionIdsAndDates(array $admissionIds, array $dates): array
    {
        if (empty($admissionIds) || empty($dates)) {
            return [];
        }
        $admissionPh = implode(',', array_fill(0, count($admissionIds), '?'));
        $datePh = implode(',', array_fill(0, count($dates), '?'));
        $stmt = getDb()->prepare(
            "SELECT admission_id, date FROM student_entry_attendances WHERE admission_id IN ($admissionPh) AND date IN ($datePh)"
        );
        $stmt->execute([...$admissionIds, ...$dates]);
        return $stmt->fetchAll();
    }

    // marked_at is computed explicitly in Asia/Kolkata, rather than left to
    // MySQL's CURRENT_TIMESTAMP default — this host's DB session timezone
    // is UTC, which was silently storing a time ~5:30 hours behind real
    // IST wall-clock time (the app then displayed that UTC value as if it
    // were already local, with no further conversion, since the returned
    // string carried no timezone marker for it to convert from).
    public static function create(int $admissionId, string $adminId, string $date): array
    {
        $markedAt = (new DateTime('now', new DateTimeZone('Asia/Kolkata')))->format('Y-m-d H:i:s');
        $stmt = getDb()->prepare('INSERT INTO student_entry_attendances (admission_id, admin_id, date, marked_at) VALUES (?, ?, ?, ?)');
        $stmt->execute([$admissionId, $adminId, $date, $markedAt]);
        $id = (int) getDb()->lastInsertId();
        $stmt = getDb()->prepare('SELECT * FROM student_entry_attendances WHERE id = ?');
        $stmt->execute([$id]);
        return $stmt->fetch();
    }

    public static function findAllWithNamesForAdmin(string $adminId, ?string $date = null): array
    {
        $sql = 'SELECT sea.id, sea.date, sea.marked_at, sea.out_time, a.applicant_name, a.comn_enrol_no
                FROM student_entry_attendances sea
                JOIN admissions a ON a.id = sea.admission_id
                WHERE sea.admin_id = ?';
        $params = [$adminId];
        if ($date !== null) {
            $sql .= ' AND sea.date = ?';
            $params[] = $date;
        }
        $sql .= ' ORDER BY sea.marked_at DESC';
        $stmt = getDb()->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    // Below: the Flutter Student App's own self-service in/out, writing to
    // this same table (marked_at doubles as "in_time") so the admin's Entry
    // Attendance page picks these up too, with no separate app-only record.

    public static function findTodayForAdmission(int $admissionId, string $date): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM student_entry_attendances WHERE admission_id = ? AND date = ?');
        $stmt->execute([$admissionId, $date]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    // Same reasoning as create() above — explicit Asia/Kolkata time instead
    // of MySQL's NOW() (this host's DB session timezone is UTC).
    public static function markOut(int $id): array
    {
        $outTime = (new DateTime('now', new DateTimeZone('Asia/Kolkata')))->format('Y-m-d H:i:s');
        $stmt = getDb()->prepare('UPDATE student_entry_attendances SET out_time = ? WHERE id = ?');
        $stmt->execute([$outTime, $id]);
        $stmt = getDb()->prepare('SELECT * FROM student_entry_attendances WHERE id = ?');
        $stmt->execute([$id]);
        return $stmt->fetch();
    }

    public static function findHistoryForAdmission(int $admissionId, int $limit = 30): array
    {
        $stmt = getDb()->prepare(
            'SELECT id, date, marked_at, out_time FROM student_entry_attendances
             WHERE admission_id = ? ORDER BY date DESC LIMIT ' . (int) $limit
        );
        $stmt->execute([$admissionId]);
        return $stmt->fetchAll();
    }
}
