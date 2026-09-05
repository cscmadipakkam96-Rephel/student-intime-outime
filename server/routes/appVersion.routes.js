const express = require('express');
const cors = require('cors');

const router = express.Router();

// No auth — this must be reachable before a student has ever logged in
// (checked on every app launch, before the session check).
router.use(cors());

router.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    minVersion: process.env.MIN_APP_VERSION || '0.0.0',
  });
});

module.exports = router;
