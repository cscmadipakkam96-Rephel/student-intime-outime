const express = require('express');
const cors = require('cors');
const { registerToken } = require('../controllers/notification.controller');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.use(verifyToken);

router.post('/register-token', registerToken);

module.exports = router;
