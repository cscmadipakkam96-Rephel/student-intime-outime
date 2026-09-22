<?php
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/jwt.php';
require_once __DIR__ . '/../models/Admission.php';

// Gate for the endpoints the separate Flutter Student App calls into this
// server. Originally x-api-key only (server-to-server, from the Flutter
// app's now-being-retired Node backend) — mirrors server/middleware/
// studentAppAuth.js. Now that the Flutter app talks to this PHP backend
// directly, these same endpoints also accept the student's own `token`
// cookie (see middleware/studentAuth.php) as a second way in, so the one
// x-api-key caller and the Flutter app can share one implementation.
//
// Returns the authenticated student's comn_enrol_no when auth came from the
// student cookie, or null when it came from x-api-key (that mode doesn't
// identify a specific student — the caller passes comn_enrol_no itself, as
// before).
function requireStudentAppAuth(): ?string
{
    $key = $_SERVER['HTTP_X_API_KEY'] ?? '';
    if ($key && $key === env('STUDENT_APP_INBOUND_API_KEY')) {
        return null;
    }

    $token = $_COOKIE['token'] ?? null;
    $payload = verifyJwt($token);
    if ($payload && ($payload['role'] ?? null) === 'student' && !empty($payload['comn_enrol_no'])) {
        // Single-active-device enforcement — same check as
        // middleware/studentAuth.php, see its comment for the full picture.
        $admission = Admission::findByIdAny((int) ($payload['admissionId'] ?? 0));
        $currentSessionId = $admission['current_session_id'] ?? null;
        $tokenSessionId = $payload['sessionId'] ?? null;
        if ($admission && $currentSessionId !== null && $tokenSessionId !== $currentSessionId) {
            jsonError('Your account was logged in on another device.', 401, ['code' => 'SESSION_INVALIDATED']);
        }
        return $payload['comn_enrol_no'];
    }

    jsonError('Invalid or missing API key.', 401);
}
