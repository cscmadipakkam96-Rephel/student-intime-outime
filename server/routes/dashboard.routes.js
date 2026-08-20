const express = require('express');
const cors = require('cors');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.get('/', verifyToken, (req, res) => {
  res.status(200).json({ success: true, message: 'Welcome to the dashboard', user: req.user });
});

module.exports = router;
