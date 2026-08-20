const express = require('express');
const cors = require('cors');
const { login, logout, me } = require('../controllers/auth.controller');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.post('/login', login);
router.post('/logout', logout);
router.get('/me', verifyToken, me);

module.exports = router;
