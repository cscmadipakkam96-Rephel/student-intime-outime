const express = require('express');
const cors = require('cors');
const { markInTime, markOutTime, getHistory } = require('../controllers/attendance.controller');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.use(verifyToken);

router.post('/in', markInTime);
router.post('/out', markOutTime);
router.get('/history', getHistory);

module.exports = router;
