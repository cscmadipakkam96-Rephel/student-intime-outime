// Shared-secret auth for server-to-server calls (e.g. the Course Admission
// backend) — distinct from the student-facing JWT cookie auth, since these
// callers have no student session of their own.
function verifyApiKey(req, res, next) {
  const key = req.headers['x-api-key'];

  if (!key || key !== process.env.COURSE_ADMISSION_API_KEY) {
    return res.status(401).json({ success: false, error: 'Invalid or missing API key' });
  }

  next();
}

module.exports = verifyApiKey;
