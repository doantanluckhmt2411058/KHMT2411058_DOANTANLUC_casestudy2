
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { getTasks } = require('../controllers/taskController');

// GET /api/tasks
router.get('/', authMiddleware, getTasks);

module.exports = router;
