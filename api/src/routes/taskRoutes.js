
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const {
    getTasks,
    getTaskById
} = require('../controllers/taskController');

// B1: GET /api/tasks
router.get('/', authMiddleware, getTasks);

// B2: GET /api/tasks/:id
router.get('/:id', authMiddleware, getTaskById);

module.exports = router;
