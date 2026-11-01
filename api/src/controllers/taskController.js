
const Task = require('../models/Task');

// Lấy danh sách công việc của người dùng đang đăng nhập
const getTasks = async (req, res) => {
    try {
        const userId = req.user._id;

        const tasks = await Task.find({
            $or: [
                { createdBy: userId },
                { assigneeIds: userId },
                { primaryAssigneeId: userId }
            ]
        })
            .populate('createdBy', 'fullName email')
            .populate('assigneeIds', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Lấy danh sách công việc thành công!',
            total: tasks.length,
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

module.exports = {
    getTasks
};
