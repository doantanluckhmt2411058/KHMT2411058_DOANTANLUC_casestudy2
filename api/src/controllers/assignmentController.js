
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const { sendAssignmentEmail } = require('../services/emailService');

// Hàm kiểm tra người tạo công việc
const isTaskCreator = (task, userId) =>
    task.createdBy.toString() === userId.toString();

// C1.1: Xem danh sách người được giao
const getAssignees = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id)
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl');

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskCreator(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo mới được quản lý giao việc!'
            });
        }

        return res.status(200).json({
            message: 'Lấy danh sách người được giao thành công!',
            assignees: task.assigneeIds,
            primaryAssignee: task.primaryAssigneeId
        });
    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: 'Không thể lấy danh sách người được giao!',
            error: error.message
        });
    }
};

// D1: Gửi email khi giao công việc mới
const assignTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { assigneeIds, primaryAssigneeId } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        if (!Array.isArray(assigneeIds) || assigneeIds.length === 0) {
            return res.status(400).json({
                message: 'Vui lòng chọn ít nhất một người được giao!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskCreator(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo mới được giao công việc!'
            });
        }

        // Kiểm tra ID người dùng
        const validIds = assigneeIds.every(
            userId => mongoose.Types.ObjectId.isValid(userId)
        );

        if (!validIds) {
            return res.status(400).json({
                message: 'ID người được giao không hợp lệ!'
            });
        }

        // Loại bỏ ID trùng
        const uniqueAssigneeIds = [
            ...new Set(assigneeIds.map(String))
        ];

        // Kiểm tra tài khoản có tồn tại
        const users = await User.find({
            _id: { $in: uniqueAssigneeIds }
        });

        if (users.length !== uniqueAssigneeIds.length) {
            return res.status(400).json({
                message: 'Có tài khoản người được giao không tồn tại!'
            });
        }

        // Kiểm tra người phụ trách chính
        if (
            primaryAssigneeId &&
            (
                !mongoose.Types.ObjectId.isValid(primaryAssigneeId) ||
                !uniqueAssigneeIds.includes(primaryAssigneeId.toString())
            )
        ) {
            return res.status(400).json({
                message: 'Người phụ trách chính phải nằm trong danh sách được giao!'
            });
        }

        // Lưu danh sách người đã được giao trước đó
        const oldAssigneeIds = new Set(
            task.assigneeIds.map(userId => userId.toString())
        );

        // Cập nhật người được giao
        task.assigneeIds = uniqueAssigneeIds;
        task.primaryAssigneeId = primaryAssigneeId || null;

        await task.save();

        // Lấy dữ liệu mới nhất
        const updatedTask = await Task.findById(task._id)
            .populate('createdBy', 'fullName email')
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl');

        // Chỉ gửi email cho những người mới được giao
        const newAssignees = updatedTask.assigneeIds.filter(
            user => !oldAssigneeIds.has(user._id.toString())
        );

        // Gửi email
        const emailResults = await Promise.allSettled(
            newAssignees.map(user =>
                sendAssignmentEmail({
                    recipient: user,
                    task: updatedTask,
                    assigner: updatedTask.createdBy,
                    isPrimary:
                        updatedTask.primaryAssigneeId?._id.toString() ===
                        user._id.toString()
                })
            )
        );

        const emailStatus = emailResults.map((result, index) => ({
            email: newAssignees[index].email,
            status: result.status === 'fulfilled' ? 'sent' : 'failed',
            message: result.status === 'fulfilled'
                ? 'Gửi email thành công!'
                : result.reason.message
        }));

        const successCount = emailStatus.filter(
            item => item.status === 'sent'
        ).length;

        const failedCount = emailStatus.filter(
            item => item.status === 'failed'
        ).length;

        return res.status(200).json({
            message: 'Giao công việc thành công!',
            task: updatedTask,
            emailSummary: {
                total: newAssignees.length,
                success: successCount,
                failed: failedCount,
                results: emailStatus
            }
        });

    } catch (error) {
        console.error('Lỗi giao công việc:', error);

        return res.status(500).json({
            message: 'Không thể giao công việc!',
            error: error.message
        });
    }
};

module.exports = {
    getAssignees,
    assignTask
};
