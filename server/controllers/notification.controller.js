const prisma = require('../config/prisma');

// Called on every app open/login — overwrites whatever token was stored
// before, so only the most recently active device receives reminders.
async function registerToken(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, error: 'token is required' });
    }

    await prisma.register.update({
      where: { comn_enrol_no },
      data: { fcmToken: token },
    });

    res.status(200).json({ success: true });
  } catch (err) {
    console.error('Register FCM token error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = { registerToken };
