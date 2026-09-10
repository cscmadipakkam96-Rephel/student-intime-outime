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

// Enriches the raw attendance rows with two things the upstream API doesn't
// provide directly, so the app never has to do this correlation itself:
// - batch_id (attendance only gives batch_name, but submitting a leave
//   request needs the id) — resolved via a name lookup against /batches.
//   Best-effort: if two batches share a name this could resolve to the
//   wrong one, but that's a data issue on the upstream side, not ours.
// - hasLeaveRequest (whether an Absent row already has a leave letter
//   submitted for that exact batch + date) — resolved against /leave-requests
//   so the app knows whether to show "Submit Leave Letter".
async function getAttendance(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const qs = `comn_enrol_no=${encodeURIComponent(comn_enrol_no)}`;

    const [attendanceResult, batchesResult, leaveRequestsResult] = await Promise.all([
      caFetch(`/attendance?${qs}`),
      caFetch(`/batches?${qs}`),
      caFetch(`/leave-requests?${qs}`),
    ]);

    if (!attendanceResult.data.success) {
      return res.status(attendanceResult.statusCode).json(attendanceResult.data);
    }

    const batchNameToId = new Map();
    if (batchesResult.data.success) {
      for (const batch of batchesResult.data.data) {
        if (!batchNameToId.has(batch.batch_name)) {
          batchNameToId.set(batch.batch_name, batch.batch_id);
        }
      }
    }

    const leaveRequestKeys = new Set();
    if (leaveRequestsResult.data.success) {
      for (const lr of leaveRequestsResult.data.data) {
        leaveRequestKeys.add(`${lr.batch_name}|${lr.session_date}`);
      }
    }

    const enriched = attendanceResult.data.data.map((row) => ({
      ...row,
      batch_id: batchNameToId.get(row.batch_name) ?? null,
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
