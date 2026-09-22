<?php
require_once __DIR__ . '/../config/db.php';

// Mirrors server/models/Admission.js — same column list, same
// `active` soft-delete flag, same auto-generated `slug` on create.
class Admission
{
    public static $columns = [
        'admin_id', 'comn_enrol_no', 'course_name', 'session', 'applicant_name',
        'initial', 'father_husband_name', 'father_initial', 'guardian_occupation',
        'date_of_birth', 'age', 'sex', 'educational_qualification', 'religion',
        'community', 'occupation', 'aadhar_no', 'company_name', 'address',
        'mobile_no', 'mother_mobile_no', 'telephone_no', 'email', 'total_fee', 'first_installment_amount',
        'bill_no', 'admission_date', 'scheme', 'timings', 'scheduled_in_time',
        'scheduled_out_time', 'notification_title', 'notification_description',
        'active', 'slug', 'otp', 'otp_expires', 'is_verified', 'published_to_student_app',
        'current_session_id',
    ];

    public static function findAllActive(string $adminId, bool $active = true): array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE admin_id = ? AND active = ? ORDER BY id ASC');
        $stmt->execute([$adminId, $active ? 1 : 0]);
        return $stmt->fetchAll();
    }

    public static function findById(int $id, string $adminId): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE id = ? AND admin_id = ? LIMIT 1');
        $stmt->execute([$id, $adminId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public static function findByAadhar(string $aadharNo, string $adminId): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE aadhar_no = ? AND admin_id = ? LIMIT 1');
        $stmt->execute([$aadharNo, $adminId]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public static function findBySlug(string $slug): ?array
    {
        $stmt = getDb()->prepare(
            'SELECT applicant_name, slug FROM admissions WHERE slug = ? AND active = 1 AND is_verified = 1 LIMIT 1'
        );
        $stmt->execute([$slug]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    // Full row version of findBySlug, used by QR/self-service attendance
    // scanning where the caller needs id + applicant_name, not just the
    // display-only pair findBySlug returns.
    public static function findVerifiedBySlug(string $slug): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE slug = ? AND active = 1 AND is_verified = 1 LIMIT 1');
        $stmt->execute([$slug]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    // Full row, active=1 only — used by the public attendance-auth flow,
    // which must look up a not-yet-verified admission too (findVerifiedBySlug
    // requires is_verified=1, which is wrong before OTP verification happens).
    public static function findActiveBySlug(string $slug): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE slug = ? AND active = 1 LIMIT 1');
        $stmt->execute([$slug]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    // Unscoped by admin_id on purpose — the attendance-auth flow is public
    // (no admin session), so it can only ever identify a row by its slug.
    public static function updateBySlug(string $slug, array $fields): void
    {
        $set = [];
        $values = [];
        foreach (self::$columns as $col) {
            if (array_key_exists($col, $fields)) {
                $set[] = "$col = ?";
                $values[] = $fields[$col];
            }
        }
        if (empty($set)) {
            return;
        }
        $values[] = $slug;
        $sql = 'UPDATE admissions SET ' . implode(', ', $set) . ' WHERE slug = ?';
        $stmt = getDb()->prepare($sql);
        $stmt->execute($values);
    }

    // No admin_id scoping — comn_enrol_no is treated as a unique student
    // identifier across every Student App integration, same as the Node app.
    public static function findByEnrolNo(string $enrolNo): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE comn_enrol_no = ? AND active = 1 LIMIT 1');
        $stmt->execute([$enrolNo]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    // No admin_id scoping — mirrors Node's Admission.findByPk(id) used by
    // markAttendance, which trusts the id alone (called from an
    // already-admin-authed route, but the lookup itself isn't tenant-scoped
    // in the original code either).
    public static function findByIdAny(int $id): ?array
    {
        $stmt = getDb()->prepare('SELECT * FROM admissions WHERE id = ? LIMIT 1');
        $stmt->execute([$id]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public static function create(array $data): array
    {
        if (empty($data['slug'])) {
            $data['slug'] = bin2hex(random_bytes(12));
        }

        $cols = [];
        $placeholders = [];
        $values = [];
        foreach (self::$columns as $col) {
            if (array_key_exists($col, $data)) {
                $cols[] = $col;
                $placeholders[] = '?';
                $values[] = $data[$col];
            }
        }

        $sql = 'INSERT INTO admissions (' . implode(', ', $cols) . ') VALUES (' . implode(', ', $placeholders) . ')';
        $stmt = getDb()->prepare($sql);
        $stmt->execute($values);
        $id = (int) getDb()->lastInsertId();

        return self::findById($id, $data['admin_id']);
    }

    public static function update(int $id, string $adminId, array $fields): void
    {
        $set = [];
        $values = [];
        foreach (self::$columns as $col) {
            if (array_key_exists($col, $fields)) {
                $set[] = "$col = ?";
                $values[] = $fields[$col];
            }
        }
        if (empty($set)) {
            return;
        }
        $values[] = $id;
        $values[] = $adminId;
        $sql = 'UPDATE admissions SET ' . implode(', ', $set) . ' WHERE id = ? AND admin_id = ?';
        $stmt = getDb()->prepare($sql);
        $stmt->execute($values);
    }
}
