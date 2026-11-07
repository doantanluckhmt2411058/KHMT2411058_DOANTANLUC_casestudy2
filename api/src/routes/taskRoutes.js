
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const {
    createTask,
    getTasks,
    getTaskById,
    updateTask,
    deleteTask,
    updateTaskStatus,
    getTaskAssignees,
    assignTask,
    getTaskShares,
    shareTask,
    updateTaskShare,
    removeTaskShare
} = require('../controllers/taskController');

// B: Tạo công việc
router.post('/', authMiddleware, createTask);

// B1: Danh sách công việc
router.get('/', authMiddleware, getTasks);

// B2: Chi tiết công việc
router.get('/:id', authMiddleware, getTaskById);

// B3: Cập nhật công việc
router.put('/:id', authMiddleware, updateTask);

// B4: Xóa công việc
router.delete('/:id', authMiddleware, deleteTask);

// B6: Cập nhật trạng thái
router.patch('/:id/status', authMiddleware, updateTaskStatus);

// C1: Giao việc
router.get('/:id/assignees', authMiddleware, getTaskAssignees);
router.post('/:id/assignees', authMiddleware, assignTask);

// C2: Chia sẻ công việc
router.get('/:id/shares', authMiddleware, getTaskShares);
router.post('/:id/shares', authMiddleware, shareTask);
router.patch('/:id/shares/:shareId', authMiddleware, updateTaskShare);
router.delete('/:id/shares/:shareId', authMiddleware, removeTaskShare);

module.exports = router;
