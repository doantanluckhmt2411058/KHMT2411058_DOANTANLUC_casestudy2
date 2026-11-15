
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { getEmailLogs } = require('../controllers/emailLogController');

router.get('/', authMiddleware, getEmailLogs);

module.exports = router;
