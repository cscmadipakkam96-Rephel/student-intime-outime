const express = require('express');
const cors = require('cors');
const { handleIncoming } = require('../controllers/notificationWebhook.controller');
const verifyApiKey = require('../middleware/apiKey.middleware');

const router = express.Router();

// Server-to-server call from the Course Admission backend, not a browser —
// same trust boundary as attendanceSummary.routes.js, same API key.
const adminAppCors = cors({ origin: 'https://16-192-84-160.sslip.io' });

router.use(adminAppCors);
router.use(verifyApiKey);

router.post('/', handleIncoming);

module.exports = router;
