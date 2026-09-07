const cron = require('node-cron');
const { sendDailyAttendanceReminders } = require('../services/attendanceReminder.service');

// '30 20 * * *' = 8:30 PM, every day, in the Asia/Kolkata timezone —
// independent of whatever timezone the EC2 host itself is set to.
function startAttendanceReminderJob() {
  cron.schedule(
    '30 20 * * *',
    async () => {
      try {
        const result = await sendDailyAttendanceReminders();
        console.log('Daily attendance reminders sent:', result);
      } catch (err) {
        console.error('Attendance reminder job failed:', err);
      }
    },
    { timezone: 'Asia/Kolkata' },
  );
}

module.exports = { startAttendanceReminderJob };
