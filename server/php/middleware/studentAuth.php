<?php
require_once __DIR__ . '/../utils/jwt.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../models/Admission.php';

// A third trust domain alongside admin/teacher — the Flutter Student App's
// own session. The Flutter client has no browser-style cookie jar: it
// manually reads Set-Cookie on login, stores just the "token=..." value,
// and re-attaches it as a plain Cookie header on every later request. So
// the cookie name here MUST be exactly "token" (not "student_token") to
// match what the app already parses — this is a hard constraint from the
// existing app, not a naming choice.
//
// Single-active-device enforcement: every login overwrites
// admissions.current_session_id and embeds that same value in the JWT
// (see studentAuthController.php::studentLogin). A token whose embedded
// sessionId no longer matches the row's current value means a newer login
// happened elsewhere since this token was issued — reject it with a
// distinct code so the app can show "logged in on another device" rather
// than a generic "please log in".
function requireStudentAuth(): array
{
    $token = $_COOKIE['token'] ?? null;
    $payload = verifyJwt($token);

    if (!$payload || empty($payload['admissionId']) || ($payload['role'] ?? null) !== 'student') {
        jsonError('Not authenticated. Please log in.', 401);
    }

    $admission = Admission::findByIdAny((int) $payload['admissionId']);
    if (!$admission || !$admission['active']) {
        jsonError('Not authenticated. Please log in.', 401);
    }

    $currentSessionId = $admission['current_session_id'] ?? null;
    $tokenSessionId = $payload['sessionId'] ?? null;
    if ($currentSessionId !== null && $tokenSessionId !== $currentSessionId) {
        jsonError('Your account was logged in on another device.', 401, ['code' => 'SESSION_INVALIDATED']);
    }

    return $payload;
}
