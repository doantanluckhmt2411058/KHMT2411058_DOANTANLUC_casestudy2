
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const {
    getAssignees,
    assignTask
} = require('../controllers/assignmentController');

// GET /api/tasks/:id/assignees
router.get('/:id/assignees', authMiddleware, getAssignees);

// POST /api/tasks/:id/assignees
router.post('/:id/assignees', authMiddleware, assignTask);

module.exports = router;
