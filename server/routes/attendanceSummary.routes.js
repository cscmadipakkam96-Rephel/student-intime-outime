const express = require('express');
const cors = require('cors');
const { getAttendanceSummary } = require('../controllers/attendanceSummary.controller');
const verifyApiKey = require('../middleware/apiKey.middleware');

const router = express.Router();

// Server-to-server call from the Course Admission backend, not a browser —
// CORS is defense-in-depth here, the real gate is the API key.
const adminAppCors = cors({ origin: 'https://16-192-84-160.sslip.io' });

router.use(adminAppCors);
router.use(verifyApiKey);

router.get('/', getAttendanceSummary);

module.exports = router;
