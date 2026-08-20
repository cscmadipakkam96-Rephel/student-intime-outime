const prisma = require('../config/prisma');

function startOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function endOfToday() {
  const d = new Date();
  d.setHours(23, 59, 59, 999);
  return d;
}

async function markInTime(req, res) {
  try {
    const { comn_enrol_no } = req.user;

    const existing = await prisma.attendance.findFirst({
      where: { comn_enrol_no, date: { gte: startOfToday(), lte: endOfToday() } },
    });

    if (existing) {
      return res.status(400).json({ success: false, error: 'Already checked in today' });
    }

    const record = await prisma.attendance.create({
      data: { comn_enrol_no, inTime: new Date() },
    });

    res.status(200).json({ success: true, record });
  } catch (err) {
    console.error('Mark in-time error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function markOutTime(req, res) {
  try {
    const { comn_enrol_no } = req.user;

    const existing = await prisma.attendance.findFirst({
      where: { comn_enrol_no, date: { gte: startOfToday(), lte: endOfToday() } },
    });

    if (!existing) {
      return res.status(400).json({ success: false, error: 'You have not checked in today' });
    }

    if (existing.outTime) {
      return res.status(400).json({ success: false, error: 'Already checked out today' });
    }

    const record = await prisma.attendance.update({
      where: { id: existing.id },
      data: { outTime: new Date() },
    });

    res.status(200).json({ success: true, record });
  } catch (err) {
    console.error('Mark out-time error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function getHistory(req, res) {
  try {
    const { comn_enrol_no } = req.user;

    const records = await prisma.attendance.findMany({
      where: { comn_enrol_no },
      orderBy: { date: 'desc' },
    });

    res.status(200).json({ success: true, records });
  } catch (err) {
    console.error('Get history error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = { markInTime, markOutTime, getHistory };
