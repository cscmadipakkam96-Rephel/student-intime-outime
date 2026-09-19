<?php
// Included at the top of every api/**/*.php entry point. Mirrors the global
// middleware Node's index.js applies once for the whole app (CORS, cookies,
// JSON body) — Core PHP has no single entry point wired to every route the
// way Express does, so each script pulls this in individually instead.

require_once __DIR__ . '/env.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/migrate.php';
require_once __DIR__ . '/../utils/jwt.php';
require_once __DIR__ . '/../utils/response.php';

// Closest thing to Sequelize's sync({alter:true}) without an ORM — runs
// any not-yet-applied server/sql/*.sql file so tables never need manual
// pasting. Cheap once everything's applied (one SELECT against
// _migrations). The `course_admission` database itself still has to exist
// first — PDO can't create the database it's connecting to.
ensureSchema();

// No cron-job access on this host (FTP + phpMyAdmin only) — piggybacks the
// schedule-reminder check onto ordinary app traffic instead of a real
// cron. See server/utils/scheduleReminderRunner.php for the tradeoffs.
require_once __DIR__ . '/../utils/scheduleReminderRunner.php';
maybeRunScheduleReminderCheck();

$allowedOrigins = array_filter(array_map('trim', explode(',', env('ALLOWED_ORIGINS', ''))));
$origin = $_SERVER['HTTP_ORIGIN'] ?? null;

if ($origin === null || in_array($origin, $allowedOrigins, true)) {
    if ($origin !== null) {
        header("Access-Control-Allow-Origin: $origin");
    }
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, x-api-key');
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
