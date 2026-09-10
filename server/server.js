require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const prisma = require('./config/prisma');
const registerRoutes = require('./routes/register.routes');
const authRoutes = require('./routes/auth.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const attendanceRoutes = require('./routes/attendance.routes');
const videosRoutes = require('./routes/videos.routes');
const attendanceSummaryRoutes = require('./routes/attendanceSummary.routes');
const courseVideosRoutes = require('./routes/courseVideos.routes');
const appVersionRoutes = require('./routes/appVersion.routes');
const notificationRoutes = require('./routes/notification.routes');
const studentAppRoutes = require('./routes/studentApp.routes');
const { startAttendanceReminderJob } = require('./jobs/attendanceReminder.job');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(cookieParser());

// Register endpoint has its own scoped CORS (admin app origin only) —
// mounted before the global open CORS below so that policy applies to it.
app.use('/api/register', registerRoutes);
app.use('/api/v1/attendance-summary', attendanceSummaryRoutes);
app.use('/api/app-version', appVersionRoutes);

// Auth/dashboard need credentialed CORS (cookies) — scoped per-route.
app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/videos', videosRoutes);
app.use('/api/course-videos', courseVideosRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/student-app', studentAppRoutes);

app.use(cors());

app.get('/', (req, res) => {
  res.send('Server running');
});

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  try {
    await prisma.$connect();
    console.log('Database connected successfully');
  } catch (err) {
    console.error('Database connection failed:', err);
  }
  startAttendanceReminderJob();
});
