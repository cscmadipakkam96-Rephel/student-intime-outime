const prisma = require('../config/prisma');

async function registerStudent(req, res) {
  try {
    const { comn_enrol_no, name, date_of_birth } = req.body;

    if (!comn_enrol_no || !name || !date_of_birth) {
      return res.status(400).json({
        success: false,
        error: 'comn_enrol_no, name, and date_of_birth are all required',
      });
    }

    const dob = new Date(date_of_birth);
    if (isNaN(dob.getTime())) {
      return res.status(400).json({
        success: false,
        error: 'date_of_birth must be a valid date (YYYY-MM-DD)',
      });
    }

    await prisma.register.upsert({
      where: { comn_enrol_no },
      update: { name, date_of_birth: dob },
      create: { comn_enrol_no, name, date_of_birth: dob },
    });

    res.status(200).json({ success: true });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function deleteRegister(req, res) {
  try {
    const { comn_enrol_no } = req.params;

    const existing = await prisma.register.findUnique({ where: { comn_enrol_no } });

    if (!existing) {
      return res.status(404).json({ success: false, error: 'Not found' });
    }

    await prisma.register.delete({ where: { comn_enrol_no } });

    res.status(200).json({ success: true });
  } catch (err) {
    console.error('Delete register error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function checkRegistered(req, res) {
  try {
    const { comn_enrol_no } = req.params;

    const existing = await prisma.register.findUnique({ where: { comn_enrol_no } });

    res.status(200).json({ success: true, exists: !!existing });
  } catch (err) {
    console.error('Check register error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = { registerStudent, deleteRegister, checkRegistered };
