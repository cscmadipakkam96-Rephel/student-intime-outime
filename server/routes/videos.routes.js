const express = require('express');
const cors = require('cors');
const { getMyRecordings } = require('../controllers/videos.controller');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.use(verifyToken);

router.get('/recordings', getMyRecordings);

module.exports = router;
