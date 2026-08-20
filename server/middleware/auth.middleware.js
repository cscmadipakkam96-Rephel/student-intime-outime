const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
  const token = req.cookies?.token;

  if (!token) {
    return res.status(401).json({ success: false, error: 'Not authenticated' });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (err) {
    return res.status(401).json({ success: false, error: 'Invalid or expired token' });
  }
}

module.exports = verifyToken;
