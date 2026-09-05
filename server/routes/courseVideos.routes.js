const express = require('express');
const cors = require('cors');
const {
  listCourseVideos,
  createOrder,
  verifyPayment,
  getCourseVideoPlayUrl,
} = require('../controllers/courseVideos.controller');
const verifyToken = require('../middleware/auth.middleware');

const router = express.Router();

const authCors = cors({ origin: true, credentials: true });

router.use(authCors);
router.use(verifyToken);

router.get('/', listCourseVideos);
router.post('/:id/create-order', createOrder);
router.post('/:id/verify-payment', verifyPayment);
router.get('/:id/play', getCourseVideoPlayUrl);

module.exports = router;
