const prisma = require('../config/prisma');
const { messaging } = require('../config/firebaseAdmin');

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

// Runs at 8:30 PM IST daily. Compares every student with a registered device
// against today's attendance row and reminds whoever hasn't completed both
// in-time and out-time yet — a different message depending on which one is
// missing, since "you forgot to check in" and "you forgot to check out" call
// for different action from the student.
async function sendDailyAttendanceReminders() {
  const students = await prisma.register.findMany({
    where: { fcmToken: { not: null } },
    select: { comn_enrol_no: true, name: true, fcmToken: true },
  });

  if (students.length === 0) return { sent: 0, skipped: 0, failed: 0 };

  const todaysAttendance = await prisma.attendance.findMany({
    where: { date: { gte: startOfToday(), lte: endOfToday() } },
  });
  const attendanceByStudent = new Map(todaysAttendance.map((r) => [r.comn_enrol_no, r]));

  let sent = 0;
  let skipped = 0;
  let failed = 0;
  const staleTokens = [];

  for (const student of students) {
    const record = attendanceByStudent.get(student.comn_enrol_no);

    let title;
    let body;
    if (!record || !record.inTime) {
      title = 'You haven’t checked in today';
      body = 'CSC IT Education: We noticed you haven’t marked your in-time yet today. Please open the app and check in.';
    } else if (!record.outTime) {
      title = 'You haven’t checked out today';
      body = 'CSC IT Education: You checked in today but haven’t marked your out-time yet. Please open the app and check out before the day ends.';
    } else {
      skipped++;
      continue;
    }

    try {
      await messaging.send({
        token: student.fcmToken,
        notification: { title, body },
        android: { priority: 'high', notification: { channelId: 'attendance_reminders' } },
      });
      sent++;
    } catch (err) {
      failed++;
      if (
        err.code === 'messaging/registration-token-not-registered'
        || err.code === 'messaging/invalid-registration-token'
      ) {
        staleTokens.push(student.comn_enrol_no);
      } else {
        console.error(`Failed to send reminder to ${student.comn_enrol_no}:`, err.message);
      }
    }
  }

  if (staleTokens.length > 0) {
    await prisma.register.updateMany({
      where: { comn_enrol_no: { in: staleTokens } },
      data: { fcmToken: null },
    });
  }

  return { sent, skipped, failed };
}

module.exports = { sendDailyAttendanceReminders };
