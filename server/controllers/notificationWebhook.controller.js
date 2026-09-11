const prisma = require('../config/prisma');
const { messaging } = require('../config/firebaseAdmin');

// Called by Course Admission the moment an admin clicks "Send Now" — this is
// a synchronous webhook, not a queue: the response IS the delivery
// confirmation, so we only return delivered:true once messaging.send() has
// actually succeeded, never just "we received your request".
async function handleIncoming(req, res) {
  try {
    const { comn_enrol_no, title, description, notification_id } = req.body;

    if (!comn_enrol_no || !title || !description) {
      return res.status(400).json({ success: false, error: 'comn_enrol_no, title and description are required' });
    }

    const student = await prisma.register.findUnique({ where: { comn_enrol_no } });
    if (!student || !student.fcmToken) {
      return res.status(200).json({ success: false, delivered: false, reason: 'no_token', notification_id: notification_id ?? null });
    }

    try {
      await messaging.send({
        token: student.fcmToken,
        data: { title, body: description },
        android: { priority: 'high' },
      });
      return res.status(200).json({ success: true, delivered: true, notification_id: notification_id ?? null });
    } catch (err) {
      if (
        err.code === 'messaging/registration-token-not-registered'
        || err.code === 'messaging/invalid-registration-token'
      ) {
        await prisma.register.update({ where: { comn_enrol_no }, data: { fcmToken: null } });
      }
      console.error(`FCM send failed for ${comn_enrol_no}:`, err.message);
      return res.status(200).json({ success: false, delivered: false, reason: 'fcm_send_failed', notification_id: notification_id ?? null });
    }
  } catch (err) {
    console.error('Incoming notification webhook error:', err);
    res.status(500).json({ success: false, delivered: false, reason: 'internal_error' });
  }
}

module.exports = { handleIncoming };
