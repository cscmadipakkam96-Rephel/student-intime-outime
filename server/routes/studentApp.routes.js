const express = require('express');
const cors = require('cors');
const {
  getBatches,
  getAttendance,
  submitLeaveRequest,
  getLeaveRequests,
} = require('../controllers/studentApp.controller');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.use(verifyToken);

router.get('/batches', getBatches);
router.get('/attendance', getAttendance);
router.post('/leave-requests', submitLeaveRequest);
router.get('/leave-requests', getLeaveRequests);

module.exports = router;
