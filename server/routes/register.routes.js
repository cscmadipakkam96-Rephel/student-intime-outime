const express = require('express');
const cors = require('cors');
const { registerStudent, deleteRegister, checkRegistered } = require('../controllers/register.controller');

const router = express.Router();

const adminAppCors = cors({ origin: 'https://16-192-84-160.sslip.io' });

router.use(adminAppCors);
router.post('/', registerStudent);
router.get('/:comn_enrol_no', checkRegistered);
router.delete('/:comn_enrol_no', deleteRegister);

module.exports = router;
