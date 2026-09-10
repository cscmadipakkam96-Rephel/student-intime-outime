// Thin client for the Course Admission "student-app" API (batches,
// attendance, leave requests) — this key is distinct from
// COURSE_ADMISSION_API_KEY, which authenticates the *reverse* direction
// (Course Admission calling into us for attendance summaries). Never expose
// this key to the Flutter app; only this server calls out with it.
const BASE_URL = process.env.COURSE_ADMISSION_STUDENT_APP_BASE_URL;
const API_KEY = process.env.COURSE_ADMISSION_STUDENT_APP_API_KEY;

async function caFetch(path, options = {}) {
  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'x-api-key': API_KEY,
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
  });
  const data = await response.json().catch(() => ({}));
  return { statusCode: response.status, data };
}

module.exports = { caFetch };
