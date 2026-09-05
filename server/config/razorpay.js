const Razorpay = require('razorpay');

// Swapping from test to live is a pure env-var change (RAZORPAY_KEY_ID /
// RAZORPAY_KEY_SECRET) — nothing here or in any controller needs to change.
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

module.exports = razorpay;
