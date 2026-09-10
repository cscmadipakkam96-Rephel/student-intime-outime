const { caFetch } = require('../config/courseAdmissionClient');

async function getBatches(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const { statusCode, data } = await caFetch(`/batches?comn_enrol_no=${encodeURIComponent(comn_enrol_no)}`);
    res.status(statusCode).json(data);
  } catch (err) {
    console.error('Get batches error:', err);
    res.status(502).json({ success: false, error: 'Could not reach Course Admission service' });
  }
}

// Enriches each attendance row with hasLeaveRequest — whether it already has
// a non-rejected leave letter submitted for that exact batch + date — so the
// app knows whether to show "Submit Leave Letter" without an extra round
// trip. A rejected request doesn't count, matching the backend's own rule
// that a rejected request doesn't block resubmission.
async function getAttendance(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const qs = `comn_enrol_no=${encodeURIComponent(comn_enrol_no)}`;

    const [attendanceResult, leaveRequestsResult] = await Promise.all([
      caFetch(`/attendance?${qs}`),
      caFetch(`/leave-requests?${qs}`),
    ]);

    if (!attendanceResult.data.success) {
      return res.status(attendanceResult.statusCode).json(attendanceResult.data);
    }

    const leaveRequestKeys = new Set();
    if (leaveRequestsResult.data.success) {
      for (const lr of leaveRequestsResult.data.data) {
        if (lr.status !== 'rejected') {
          leaveRequestKeys.add(`${lr.batch_name}|${lr.session_date}`);
        }
      }
    }

    const enriched = attendanceResult.data.data.map((row) => ({
      ...row,
      hasLeaveRequest: leaveRequestKeys.has(`${row.batch_name}|${row.date}`),
    }));

    res.status(200).json({ success: true, data: enriched });
  } catch (err) {
    console.error('Get attendance error:', err);
    res.status(502).json({ success: false, error: 'Could not reach Course Admission service' });
  }
}

async function submitLeaveRequest(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const { batch_id, session_date, description, leave_type } = req.body;

    if (!batch_id || !session_date || !description || !leave_type) {
      return res.status(400).json({ success: false, error: 'batch_id, session_date, description and leave_type are required' });
    }

    // comn_enrol_no always comes from the authenticated session, never from
    // the request body — the app can't spoof another student's identity.
    const { statusCode, data } = await caFetch('/leave-requests', {
      method: 'POST',
      body: JSON.stringify({ comn_enrol_no, batch_id, session_date, description, leave_type }),
    });
    res.status(statusCode).json(data);
  } catch (err) {
    console.error('Submit leave request error:', err);
    res.status(502).json({ success: false, error: 'Could not reach Course Admission service' });
  }
}

async function getLeaveRequests(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const { statusCode, data } = await caFetch(`/leave-requests?comn_enrol_no=${encodeURIComponent(comn_enrol_no)}`);
    res.status(statusCode).json(data);
  } catch (err) {
    console.error('Get leave requests error:', err);
    res.status(502).json({ success: false, error: 'Could not reach Course Admission service' });
  }
}

module.exports = { getBatches, getAttendance, submitLeaveRequest, getLeaveRequests };
