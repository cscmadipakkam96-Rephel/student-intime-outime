<?php
require_once __DIR__ . '/../../config/bootstrap.php';
require_once __DIR__ . '/../../middleware/studentAppAuth.php';
require_once __DIR__ . '/../../controllers/recordingController.php';

$studentEnrolNo = requireStudentAppAuth();
if ($studentEnrolNo !== null) {
    $_GET['comn_enrol_no'] = $studentEnrolNo;
}
getRecordingsForApp();
