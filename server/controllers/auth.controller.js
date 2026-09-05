const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');

const COOKIE_MAX_AGE = 30 * 24 * 60 * 60 * 1000;

function formatDDMMYYYY(date) {
  const day = String(date.getUTCDate()).padStart(2, '0');
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const year = date.getUTCFullYear();
  return `${day}${month}${year}`;
}

async function login(req, res) {
  try {
    const { comn_enrol_no, password } = req.body;

    if (!comn_enrol_no || !password) {
      return res.status(400).json({
        success: false,
        error: 'comn_enrol_no and password are required',
      });
    }

    const student = await prisma.register.findUnique({ where: { comn_enrol_no } });

    if (!student) {
      return res.status(404).json({
        success: false,
        error: 'You are not registered. Please contact admin to get registered.',
      });
    }

    if (!student.date_of_birth) {
      return res.status(401).json({
        success: false,
        error: 'Your account is missing a date of birth. Please contact admin to re-register.',
      });
    }

    const expectedPassword = formatDDMMYYYY(student.date_of_birth);

    if (password !== expectedPassword) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: student.id, comn_enrol_no: student.comn_enrol_no, name: student.name },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.cookie('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: COOKIE_MAX_AGE,
    });

    res.status(200).json({
      success: true,
      user: {
        comn_enrol_no: student.comn_enrol_no,
        name: student.name,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function logout(req, res) {
  res.clearCookie('token');
  res.status(200).json({ success: true });
}

async function me(req, res) {
  res.status(200).json({ success: true, user: req.user });
}

module.exports = { login, logout, me };
