<?php
require_once __DIR__ . '/../../config/bootstrap.php';
require_once __DIR__ . '/../../controllers/recordingController.php';

// Public (no session check) — the short-lived signed token in the query
// string is the auth, generated only after getRecordingsForApp() already
// scoped the listing to the right student. Mirrors course-videos/stream.php.
$token = $_GET['token'] ?? '';
$payload = verifyJwt($token);

if (!$payload || ($payload['purpose'] ?? null) !== 'recording-stream') {
    http_response_code(403);
    exit;
}

streamRecordingFile($payload['comn_enrol_no'] ?? '', $payload['filename'] ?? '');
