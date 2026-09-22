-- Enforces single-active-device login for the Flutter Student App: each
-- login overwrites this value and embeds it in the issued JWT — an older
-- token's embedded session id won't match anymore, so it's rejected the
-- next time that device tries to use it.
ALTER TABLE admissions ADD COLUMN current_session_id VARCHAR(64) NULL;
