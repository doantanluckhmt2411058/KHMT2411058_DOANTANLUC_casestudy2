
const mongoose = require('mongoose');
const Task = require('../models/Task');

// Kiểm tra quyền xem công việc
const hasTaskPermission = (task, userId) => {
    const id = userId.toString();

    const isCreator =
        task.createdBy &&
        task.createdBy._id.toString() === id;

    const isAssignee = task.assigneeIds.some(
        user => user._id.toString() === id
    );

    return isCreator || isAssignee;
};

// B1: Lấy danh sách công việc
const getTasks = async (req, res) => {
    try {
        const userId = req.user._id;

        const tasks = await Task.find({
            $or: [
                { createdBy: userId },
                { assigneeIds: userId }
            ]
        })
            .populate('createdBy', 'fullName email avatarUrl')
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Lấy danh sách công việc thành công!',
            tasks
        });

    } catch (error) {
        console.error('Lỗi lấy danh sách công việc:', error);

        return res.status(500).json({
            message: 'Không thể lấy danh sách công việc!',
            error: error.message
        });
    }
};

// B2: Lấy chi tiết một công việc
const getTaskById = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id)
            .populate('createdBy', 'fullName email avatarUrl')
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl');

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!hasTaskPermission(task, req.user._id)) {
            return res.status(403).json({
                message: 'Bạn không có quyền xem công việc này!'
            });
        }

        return res.status(200).json({
            message: 'Lấy chi tiết công việc thành công!',
            task
        });

    } catch (error) {
        console.error('Lỗi lấy chi tiết công việc:', error);

        return res.status(500).json({
            message: 'Không thể lấy chi tiết công việc!',
            error: error.message
        });
    }
};

module.exports = {
    getTasks,
    getTaskById
};
