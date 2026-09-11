const prisma = require('../config/prisma');
const { messaging } = require('../config/firebaseAdmin');
const { caFetch } = require('../config/courseAdmissionClient');

function nowIstParts() {
  const now = new Date();
  return {
    // en-CA gives YYYY-MM-DD directly — used as the ReminderLog dedup key.
    dateStr: now.toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' }),
    timeStr: now.toLocaleTimeString('en-GB', {
      timeZone: 'Asia/Kolkata',
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
    }),
    dayName: now.toLocaleDateString('en-US', { timeZone: 'Asia/Kolkata', weekday: 'long' }),
  };
}

function hhmmToMinutes(hhmm) {
  if (!hhmm) return null;
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}

// Local server-time day boundaries, used to scope "today"'s Attendance rows.
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

// Records that a reminder was sent, atomically guarding against the poll
// cycle firing the same one twice — the unique(comn_enrol_no, date, type)
// constraint makes a duplicate insert fail, which we treat as "already sent".
async function claimReminderSlot(comn_enrol_no, date, type) {
  try {
    await prisma.reminderLog.create({ data: { comn_enrol_no, date, type } });
    return true;
  } catch (err) {
    if (err.code === 'P2002') return false;
    throw err;
  }
}

function messageFor(student, type) {
  if (student.source === 'schedule') {
    return { title: student.notification_title, body: student.notification_description };
  }
  return type === 'in'
    ? { title: 'Time to check in', body: 'CSC IT Education: It\'s time to check in for your class. Please open the app and check in.' }
    : { title: 'Time to check out', body: 'CSC IT Education: It\'s time to check out. Please open the app and check out.' };
}

async function sendReminder(comn_enrol_no, token, title, body) {
  try {
    await messaging.send({ token, data: { title, body }, android: { priority: 'high' } });
    return true;
  } catch (err) {
    if (
      err.code === 'messaging/registration-token-not-registered'
      || err.code === 'messaging/invalid-registration-token'
    ) {
      await prisma.register.update({ where: { comn_enrol_no }, data: { fcmToken: null } });
    }
    console.error(`Schedule reminder send failed for ${comn_enrol_no}:`, err.message);
    return false;
  }
}

// Runs every 1-2 minutes. For each student whose class meets today, fires a
// "check in"/"check out" nudge 5 minutes after their resolved class time if
// they haven't marked attendance yet — at most once per student per type per
// day, tracked via ReminderLog.
async function checkAndSendScheduleReminders() {
  const { dateStr, timeStr, dayName } = nowIstParts();
  const nowMinutes = hhmmToMinutes(timeStr);

  const { data: scheduleData } = await caFetch('/schedule');
  if (!scheduleData.success) return { checked: 0, sent: 0 };

  const dueToday = scheduleData.data.filter((s) => s.class_days?.includes(dayName));
  if (dueToday.length === 0) return { checked: 0, sent: 0 };

  const enrolNos = dueToday.map((s) => s.comn_enrol_no);
  const [registers, todaysAttendance] = await Promise.all([
    prisma.register.findMany({
      where: { comn_enrol_no: { in: enrolNos } },
      select: { comn_enrol_no: true, fcmToken: true },
    }),
    prisma.attendance.findMany({
      where: { comn_enrol_no: { in: enrolNos }, date: { gte: startOfToday(), lte: endOfToday() } },
    }),
  ]);

  const tokenByStudent = new Map(registers.filter((r) => r.fcmToken).map((r) => [r.comn_enrol_no, r.fcmToken]));
  const attendanceByStudent = new Map(todaysAttendance.map((r) => [r.comn_enrol_no, r]));

  let sent = 0;

  for (const student of dueToday) {
    const token = tokenByStudent.get(student.comn_enrol_no);
    if (!token) continue;

    const record = attendanceByStudent.get(student.comn_enrol_no);

    const checks = [
      { type: 'in', targetMinutes: hhmmToMinutes(student.effective_in_time), alreadyDone: !!record?.inTime },
      { type: 'out', targetMinutes: hhmmToMinutes(student.effective_out_time), alreadyDone: !!record?.outTime },
    ];

    for (const { type, targetMinutes, alreadyDone } of checks) {
      if (targetMinutes === null || alreadyDone) continue;
      if (nowMinutes < targetMinutes + 5) continue;

      const claimed = await claimReminderSlot(student.comn_enrol_no, dateStr, type);
      if (!claimed) continue;

      const { title, body } = messageFor(student, type);
      if (!title || !body) continue;

      if (await sendReminder(student.comn_enrol_no, token, title, body)) sent++;
    }
  }

  return { checked: dueToday.length, sent };
}

module.exports = { checkAndSendScheduleReminders };
