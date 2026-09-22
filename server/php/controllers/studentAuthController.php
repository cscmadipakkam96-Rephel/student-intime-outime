<?php
require_once __DIR__ . '/../models/Admission.php';
require_once __DIR__ . '/../utils/jwt.php';
require_once __DIR__ . '/../utils/response.php';

// Mirrors the Flutter Student App's existing Node backend (auth.controller.js)
// exactly — same login contract, same cookie name/shape — so the Flutter
// client's own session-handling code (which manually parses Set-Cookie and
// re-sends a plain Cookie header, no browser cookie jar) keeps working
// unmodified once pointed at this backend.

const STUDENT_COOKIE_MAX_AGE = 30 * 24 * 60 * 60; // 30 days, matches the app's existing session length

function formatDDMMYYYY(?string $dateOfBirth): ?string
{
    if (!$dateOfBirth) {
        return null;
    }
    $ts = strtotime($dateOfBirth);
    if ($ts === false) {
        return null;
    }
    return date('dmY', $ts);
}

function setStudentAuthCookie(string $token): void
{
    $isProd = env('APP_ENV') === 'production';
    setcookie('token', $token, [
        'expires' => time() + STUDENT_COOKIE_MAX_AGE,
        'path' => '/',
        'httponly' => true,
        'secure' => $isProd,
        'samesite' => 'Lax',
    ]);
}

function clearStudentAuthCookie(): void
{
    $isProd = env('APP_ENV') === 'production';
    setcookie('token', '', [
        'expires' => time() - 3600,
        'path' => '/',
        'httponly' => true,
        'secure' => $isProd,
        'samesite' => 'Lax',
    ]);
}

function studentLogin(): void
{
    $body = getJsonBody();
    $comnEnrolNo = trim($body['comn_enrol_no'] ?? '');
    $password = trim($body['password'] ?? '');

    if (!$comnEnrolNo || !$password) {
        jsonError('Enrollment number and password are required.', 400);
    }

    $admission = Admission::findByEnrolNo($comnEnrolNo);
    if (!$admission) {
        jsonError('Invalid enrollment number or password.', 401);
    }

    $expectedPassword = formatDDMMYYYY($admission['date_of_birth']);
    if (!$expectedPassword || $password !== $expectedPassword) {
        jsonError('Invalid enrollment number or password.', 401);
    }

    // Single-active-device login: this new session id overwrites whatever
    // was stored from a previous login (any device), and gets embedded in
    // the JWT issued below. Any older token — still sitting in another
    // device's cookie storage — carries the *previous* session id, so the
    // auth middleware will reject it as soon as this new one takes over.
    $sessionId = bin2hex(random_bytes(24));
    Admission::update((int) $admission['id'], $admission['admin_id'], ['current_session_id' => $sessionId]);

    $token = signJwt([
        'admissionId' => (int) $admission['id'],
        'comn_enrol_no' => $admission['comn_enrol_no'],
        'admin_id' => $admission['admin_id'],
        'role' => 'student',
        'sessionId' => $sessionId,
    ], STUDENT_COOKIE_MAX_AGE);
    setStudentAuthCookie($token);

    // NOT the usual {success, data} shape — the Flutter client's existing
    // parsing code expects `user` at the top level, exactly matching its
    // current Node backend's response.
    jsonResponse(200, [
        'success' => true,
        'user' => [
            'comn_enrol_no' => $admission['comn_enrol_no'],
            'name' => $admission['applicant_name'],
        ],
    ]);
}

function getStudentMe(array $authPayload): void
{
    $admission = Admission::findByIdAny((int) $authPayload['admissionId']);
    if (!$admission || !$admission['active']) {
        jsonError('Student not found.', 404);
    }

    jsonResponse(200, [
        'success' => true,
        'user' => [
            'comn_enrol_no' => $admission['comn_enrol_no'],
            'name' => $admission['applicant_name'],
        ],
    ]);
}

function studentLogout(): void
{
    clearStudentAuthCookie();
    jsonSuccess([], 'Logged out successfully');
}
