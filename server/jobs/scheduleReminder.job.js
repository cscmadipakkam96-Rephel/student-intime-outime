const cron = require('node-cron');
const { checkAndSendScheduleReminders } = require('../services/scheduleReminder.service');

// Every 2 minutes, in Asia/Kolkata — matches the polling cadence Course
// Admission expects for the "5 minutes after class time" reminder window.
function startScheduleReminderJob() {
  cron.schedule(
    '*/2 * * * *',
    async () => {
      try {
        const result = await checkAndSendScheduleReminders();
        if (result.sent > 0) {
          console.log('Schedule reminders sent:', result);
        }
      } catch (err) {
        console.error('Schedule reminder job failed:', err);
      }
    },
    { timezone: 'Asia/Kolkata' },
  );
}

module.exports = { startScheduleReminderJob };
