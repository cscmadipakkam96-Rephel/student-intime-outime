<?php
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/jwt.php';

// Class recordings — files live under uploads/recordings/<comn_enrol_no>/,
// uploaded manually (no in-app upload flow, same as the old Node/S3 setup
// this replaces). Never served directly (uploads/.htaccess denies the
// whole uploads/ tree) — playback goes through recordings-stream.php's own
// short-lived signed-token gate, mirroring course-videos/stream.php.
define('RECORDINGS_STORAGE_ROOT', __DIR__ . '/../uploads/recordings');

function getRecordingsForApp(): void
{
    $enrolNo = $_GET['comn_enrol_no'] ?? '';
    if (!$enrolNo) {
        jsonError('comn_enrol_no is required.', 400);
    }

    $safeEnrolNo = preg_replace('/[^a-zA-Z0-9_-]/', '', $enrolNo);
    $dir = RECORDINGS_STORAGE_ROOT . '/' . $safeEnrolNo;

    $recordings = [];
    if (is_dir($dir)) {
        foreach (scandir($dir) as $filename) {
            if ($filename === '.' || $filename === '..') {
                continue;
            }
            $path = "$dir/$filename";
            if (!is_file($path)) {
                continue;
            }

            $token = signJwt(
                ['comn_enrol_no' => $safeEnrolNo, 'filename' => $filename, 'purpose' => 'recording-stream'],
                600
            );
            $recordings[] = [
                'filename' => $filename,
                'lastModified' => date('c', filemtime($path)),
                'size' => filesize($path),
                'url' => recordingStreamBaseUrl() . '/recordings-stream.php?token=' . urlencode($token),
            ];
        }
    }

    usort($recordings, fn($a, $b) => strtotime($b['lastModified']) <=> strtotime($a['lastModified']));
    jsonSuccess($recordings);
}

function recordingStreamBaseUrl(): string
{
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $dir = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
    return "$scheme://$host$dir";
}

// $filename comes from a token we signed ourselves, but basename() still
// guards against path traversal defensively.
function streamRecordingFile(string $enrolNo, string $filename): void
{
    $safeEnrolNo = preg_replace('/[^a-zA-Z0-9_-]/', '', $enrolNo);
    $safeFilename = basename($filename);
    $path = RECORDINGS_STORAGE_ROOT . "/$safeEnrolNo/$safeFilename";

    if (!is_file($path)) {
        http_response_code(404);
        exit;
    }

    $size = filesize($path);
    $start = 0;
    $end = $size - 1;

    $range = $_SERVER['HTTP_RANGE'] ?? null;
    if ($range && preg_match('/bytes=(\d*)-(\d*)/', $range, $m)) {
        if ($m[1] !== '') {
            $start = (int) $m[1];
        }
        if ($m[2] !== '') {
            $end = (int) $m[2];
        }
        $end = min($end, $size - 1);
        http_response_code(206);
        header("Content-Range: bytes $start-$end/$size");
    }

    header('Accept-Ranges: bytes');
    header('Content-Type: video/mp4');
    header('Content-Length: ' . ($end - $start + 1));

    $fh = fopen($path, 'rb');
    fseek($fh, $start);
    $bufferSize = 1024 * 1024; // 1MB chunks, so a large recording never loads fully into memory
    $remaining = $end - $start + 1;
    while ($remaining > 0 && !feof($fh)) {
        $chunkSize = min($bufferSize, $remaining);
        echo fread($fh, $chunkSize);
        flush();
        $remaining -= $chunkSize;
    }
    fclose($fh);
    exit;
}
