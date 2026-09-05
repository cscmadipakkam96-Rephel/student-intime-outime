const prisma = require('../config/prisma');

// Mirrors DashboardPage.totalDays in the Flutter app (client/lib/pages/dashboard_page.dart) —
// a fixed target, not a per-student or per-program value tracked anywhere in
// the database. Update both places together if this ever changes.
const TOTAL_DAY_COUNT = 15;

function toIstDate(date) {
  // en-CA formats as YYYY-MM-DD
  return date.toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
}

function toIstTime(date) {
  return date.toLocaleTimeString('en-GB', {
    timeZone: 'Asia/Kolkata',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
}

async function getAttendanceSummary(req, res) {
  try {
    const [students, attendanceRows] = await Promise.all([
      prisma.register.findMany({ select: { comn_enrol_no: true } }),
      prisma.attendance.findMany({
        select: { comn_enrol_no: true, date: true, inTime: true, outTime: true },
        orderBy: { date: 'asc' },
      }),
    ]);

    const attendanceByStudent = new Map();
    for (const row of attendanceRows) {
      const list = attendanceByStudent.get(row.comn_enrol_no) || [];
      list.push(row);
      attendanceByStudent.set(row.comn_enrol_no, list);
    }

    const data = students.map((student) => {
      const rows = attendanceByStudent.get(student.comn_enrol_no) || [];

      const attendance_days = rows.map((row) => {
        const counted = Boolean(row.inTime && row.outTime);
        return {
          date: toIstDate(row.date),
          in_time: row.inTime ? toIstTime(row.inTime) : null,
          out_time: row.outTime ? toIstTime(row.outTime) : null,
          counted,
        };
      });

      const completed_day_count = attendance_days.filter((d) => d.counted).length;

      return {
        comn_enrol_no: student.comn_enrol_no,
        total_day_count: TOTAL_DAY_COUNT,
        completed_day_count,
        attendance_days,
      };
    });

    res.status(200).json({ data });
  } catch (err) {
    console.error('Get attendance summary error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = { getAttendanceSummary };
