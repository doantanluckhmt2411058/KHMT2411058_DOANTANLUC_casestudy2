
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');

const {
    sendAssignmentEmail,
    sendShareInvitationEmail,
    sendTaskUpdateEmail,
    sendTaskCompletedEmail
} = require('../services/emailService');

// ============================
// KIỂM TRA QUYỀN
// ============================

const getObjectId = (value) => {
    if (!value) return null;
    return (value._id || value).toString();
};

const canViewTask = async (task, userId) => {
    const id = userId.toString();

    if (getObjectId(task.createdBy) === id) return true;

    const isAssignee = task.assigneeIds.some(
        user => getObjectId(user) === id
    );

    if (isAssignee) return true;

    const share = await TaskShare.findOne({
        taskId: task._id,
        userId: id
    });

    return !!share;
};

const canEditTask = async (task, userId) => {
    const id = userId.toString();

    if (getObjectId(task.createdBy) === id) return true;

    const isAssignee = task.assigneeIds.some(
        user => getObjectId(user) === id
    );

    if (isAssignee) return true;

    const share = await TaskShare.findOne({
        taskId: task._id,
        userId: id,
        permission: 'editor'
    });

    return !!share;
};

const isTaskOwner = (task, userId) => {
    return getObjectId(task.createdBy) === userId.toString();
};

// ============================
// E4: GHI LỊCH SỬ HOẠT ĐỘNG
// ============================

const logTaskActivity = async ({
    taskId,
    userId,
    action,
    description,
    details = {}
}) => {
    try {
        await TaskActivity.create({
            taskId,
            userId,
            action,
            description,
            details
        });
    } catch (error) {
        console.error('E4: Lỗi ghi lịch sử hoạt động:', error.message);
    }
};

// ============================
// D4: GỬI EMAIL KHI CÔNG VIỆC HOÀN THÀNH
// ============================

const notifyTaskCompleted = async (task, completerId) => {
    const emailSummary = {
        total: 0,
        success: [],
        failed: []
    };

    try {
        const shares = await TaskShare.find({
            taskId: task._id
        }).select('userId');

        const recipientIds = new Set();

        const creatorId = getObjectId(task.createdBy);

        if (creatorId) recipientIds.add(creatorId);

        for (const assignee of task.assigneeIds || []) {
            const assigneeId = getObjectId(assignee);
            if (assigneeId) recipientIds.add(assigneeId);
        }

        for (const share of shares) {
            const sharedUserId = getObjectId(share.userId);
            if (sharedUserId) recipientIds.add(sharedUserId);
        }

        recipientIds.delete(completerId.toString());

        const recipients = await User.find({
            _id: { $in: [...recipientIds] }
        }).select('fullName email');

        const completer = await User.findById(completerId)
            .select('fullName email');

        emailSummary.total = recipients.length;

        for (const recipient of recipients) {
            try {
                const result = await sendTaskCompletedEmail({
                    recipient,
                    task,
                    completer
                });

                emailSummary.success.push(result);
            } catch (emailError) {
                console.error(
                    `D4: Lỗi gửi email đến ${recipient.email}:`,
                    emailError.message
                );

                emailSummary.failed.push({
                    email: recipient.email,
                    error: emailError.message
                });
            }
        }
    } catch (error) {
        console.error('D4: Lỗi xử lý gửi email:', error.message);
    }

    return emailSummary;
};

// ============================
// B: TẠO CÔNG VIỆC
// ============================

const createTask = async (req, res) => {
    try {
        const {
            title,
            description,
            startDate,
            dueDate,
            priority,
            status
        } = req.body;

        if (!title || !title.trim()) {
            return res.status(400).json({
                message: 'Vui lòng nhập tên công việc!'
            });
        }

        const allowedPriorities = ['low', 'medium', 'high'];
        const allowedStatuses = ['todo', 'in_progress', 'completed'];

        if (priority && !allowedPriorities.includes(priority)) {
            return res.status(400).json({
                message: 'Mức độ ưu tiên không hợp lệ!'
            });
        }

        if (status && !allowedStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Trạng thái công việc không hợp lệ!'
            });
        }

        const task = await Task.create({
            title: title.trim(),
            description: description || '',
            createdBy: req.user._id,
            assigneeIds: [],
            primaryAssigneeId: null,
            startDate: startDate || null,
            dueDate: dueDate || null,
            priority: priority || 'medium',
            status: status || 'todo'
        });

        // E4: Ghi lịch sử tạo công việc
        await logTaskActivity({
            taskId: task._id,
            userId: req.user._id,
            action: 'created',
            description: `Đã tạo công việc "${task.title}"`,
            details: {
                title: task.title
            }
        });

        await task.populate(
            'createdBy',
            'fullName email avatarUrl'
        );

        return res.status(201).json({
            message: 'Tạo công việc thành công!',
            task
        });
    } catch (error) {
        console.error('Lỗi tạo công việc:', error);

        return res.status(500).json({
            message: 'Không thể tạo công việc!',
            error: error.message
        });
    }
};

// ============================
// B1: LẤY DANH SÁCH CÔNG VIỆC
// ============================

const getTasks = async (req, res) => {
    try {
        const userId = req.user._id;
        const userIdString = userId.toString();

        const sharedRecords = await TaskShare.find({
            userId
        }).select('taskId permission');

        const sharedTaskIds = sharedRecords.map(
            share => share.taskId
        );

        const tasks = await Task.find({
            $or: [
                { createdBy: userId },
                { assigneeIds: userId },
                { _id: { $in: sharedTaskIds } }
            ]
        })
            .populate('createdBy', 'fullName email avatarUrl')
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl')
            .sort({ createdAt: -1 });

        const shareMap = new Map();

        for (const share of sharedRecords) {
            shareMap.set(
                share.taskId.toString(),
                share.permission
            );
        }

        const result = tasks.map(task => {
            const taskData = task.toObject();
            const roles = [];

            if (getObjectId(task.createdBy) === userIdString) {
                roles.push('creator');
            }

            const isAssignee = task.assigneeIds.some(
                user => getObjectId(user) === userIdString
            );

            if (isAssignee) roles.push('assignee');

            const sharePermission = shareMap.get(
                task._id.toString()
            );

            if (sharePermission) roles.push('shared');

            let progress = 0;

            if (task.status === 'in_progress') {
                progress = 50;
            } else if (task.status === 'completed') {
                progress = 100;
            }

            return {
                ...taskData,
                myRoles: roles,
                mySharePermission: sharePermission || null,
                progress
            };
        });

        return res.status(200).json({
            message: 'Lấy danh sách công việc thành công!',
            currentUserId: userIdString,
            tasks: result
        });
    } catch (error) {
        console.error('Lỗi lấy danh sách công việc:', error);

        return res.status(500).json({
            message: 'Không thể lấy danh sách công việc!',
            error: error.message
        });
    }
};

// ============================
// B2: LẤY CHI TIẾT CÔNG VIỆC
// ============================

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

        if (!await canViewTask(task, req.user._id)) {
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

// ============================
// B4: CHỈNH SỬA CÔNG VIỆC
// ============================

const updateTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        const oldStatus = task.status;

        if (!await canEditTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Bạn không có quyền chỉnh sửa công việc này!'
            });
        }

        const {
            title,
            description,
            startDate,
            dueDate,
            priority,
            status
        } = req.body;

        const oldValues = {
            title: task.title,
            description: task.description || '',
            startDate: task.startDate,
            dueDate: task.dueDate,
            priority: task.priority
        };

        if (title !== undefined) {
            if (typeof title !== 'string' || !title.trim()) {
                return res.status(400).json({
                    message: 'Tên công việc không được để trống!'
                });
            }

            task.title = title.trim();
        }

        if (description !== undefined) {
            task.description = description;
        }

        if (startDate !== undefined) {
            task.startDate = startDate || null;
        }

        if (dueDate !== undefined) {
            task.dueDate = dueDate || null;
        }

        if (priority !== undefined) {
            if (!['low', 'medium', 'high'].includes(priority)) {
                return res.status(400).json({
                    message: 'Mức độ ưu tiên không hợp lệ!'
                });
            }

            task.priority = priority;
        }

        if (status !== undefined) {
            if (!['todo', 'in_progress', 'completed'].includes(status)) {
                return res.status(400).json({
                    message: 'Trạng thái công việc không hợp lệ!'
                });
            }

            task.status = status;
        }

        const dateKey = (value) => {
            if (!value) return '';

            const date = new Date(value);

            if (Number.isNaN(date.getTime())) {
                return String(value);
            }

            return date.toISOString();
        };

        const formatDate = (value) => {
            if (!value) return 'Chưa thiết lập';

            const date = new Date(value);

            if (Number.isNaN(date.getTime())) {
                return String(value);
            }

            return date.toLocaleDateString('vi-VN');
        };

        const priorityLabels = {
            low: 'Thấp',
            medium: 'Trung bình',
            high: 'Cao'
        };

        const changes = [];

        const addChange = (label, oldValue, newValue) => {
            if (String(oldValue ?? '') !== String(newValue ?? '')) {
                changes.push({
                    label,
                    oldValue: oldValue || 'Không có',
                    newValue: newValue || 'Không có'
                });
            }
        };

        addChange('Tên công việc', oldValues.title, task.title);
        addChange(
            'Mô tả',
            oldValues.description,
            task.description || ''
        );

        if (dateKey(oldValues.startDate) !== dateKey(task.startDate)) {
            changes.push({
                label: 'Ngày bắt đầu',
                oldValue: formatDate(oldValues.startDate),
                newValue: formatDate(task.startDate)
            });
        }

        if (dateKey(oldValues.dueDate) !== dateKey(task.dueDate)) {
            changes.push({
                label: 'Hạn hoàn thành',
                oldValue: formatDate(oldValues.dueDate),
                newValue: formatDate(task.dueDate)
            });
        }

        if (oldValues.priority !== task.priority) {
            changes.push({
                label: 'Độ ưu tiên',
                oldValue: priorityLabels[oldValues.priority] || oldValues.priority,
                newValue: priorityLabels[task.priority] || task.priority
            });
        }

        await task.save();

        // E4: Ghi lịch sử chỉnh sửa thông tin
        if (changes.length > 0) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.user._id,
                action: 'updated',
                description: `Đã cập nhật công việc "${task.title}"`,
                details: { changes }
            });
        }

        // E4: Ghi lịch sử thay đổi trạng thái
        if (oldStatus !== task.status) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.user._id,
                action: 'status_changed',
                description: `Đã thay đổi trạng thái từ "${oldStatus}" sang "${task.status}"`,
                details: {
                    oldStatus,
                    newStatus: task.status
                }
            });
        }

        // D4: Gửi email khi chuyển sang hoàn thành
        let completedEmailSummary = null;

        if (oldStatus !== 'completed' && task.status === 'completed') {
            completedEmailSummary = await notifyTaskCompleted(
                task,
                req.user._id
            );
        }

        // Khởi tạo kết quả email
        const emailSummary = {
            total: 0,
            success: [],
            failed: []
        };

        if (changes.length > 0) {
            const shares = await TaskShare.find({
                taskId: id
            }).select('userId');

            const recipientIds = new Set();

            const creatorId = getObjectId(task.createdBy);

            if (creatorId) recipientIds.add(creatorId);

            for (const assignee of task.assigneeIds || []) {
                const assigneeId = getObjectId(assignee);
                if (assigneeId) recipientIds.add(assigneeId);
            }

            for (const share of shares) {
                const sharedUserId = getObjectId(share.userId);
                if (sharedUserId) recipientIds.add(sharedUserId);
            }

            recipientIds.delete(req.user._id.toString());

            const recipients = await User.find({
                _id: { $in: [...recipientIds] }
            }).select('fullName email');

            const updater = await User.findById(req.user._id)
                .select('fullName email');

            emailSummary.total = recipients.length;

            for (const recipient of recipients) {
                try {
                    const result = await sendTaskUpdateEmail({
                        recipient,
                        task,
                        updater,
                        changes
                    });

                    emailSummary.success.push(result || {
                        email: recipient.email
                    });
                } catch (emailError) {
                    console.error(
                        `Lỗi gửi email cập nhật đến ${recipient.email}:`,
                        emailError.message
                    );

                    emailSummary.failed.push({
                        email: recipient.email,
                        error: emailError.message
                    });
                }
            }
        }

        await task.populate(
            'createdBy',
            'fullName email avatarUrl'
        );

        await task.populate(
            'assigneeIds',
            'fullName email avatarUrl'
        );

        await task.populate(
            'primaryAssigneeId',
            'fullName email avatarUrl'
        );

        return res.status(200).json({
            message: 'Cập nhật công việc thành công!',
            task,
            emailSummary,
            completedEmailSummary
        });
    } catch (error) {
        console.error('Lỗi cập nhật công việc:', error);

        return res.status(500).json({
            message: 'Không thể cập nhật công việc!',
            error: error.message
        });
    }
};

// ============================
// B5: XÓA CÔNG VIỆC
// ============================

const deleteTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo công việc mới được xóa!'
            });
        }

        await Task.findByIdAndDelete(id);
        await TaskShare.deleteMany({ taskId: id });

        // Xóa lịch sử liên quan khi xóa công việc
        await TaskActivity.deleteMany({ taskId: id });

        return res.status(200).json({
            message: 'Xóa công việc thành công!'
        });
    } catch (error) {
        console.error('Lỗi xóa công việc:', error);

        return res.status(500).json({
            message: 'Không thể xóa công việc!',
            error: error.message
        });
    }
};

// ============================
// B6 + D4: CẬP NHẬT TRẠNG THÁI
// ============================

const updateTaskStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const allowedStatuses = [
            'todo',
            'in_progress',
            'completed'
        ];

        if (!allowedStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Trạng thái công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!await canEditTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Bạn không có quyền cập nhật công việc này!'
            });
        }

        const oldStatus = task.status;

        task.status = status;
        await task.save();

        // E4: Chỉ ghi lịch sử khi trạng thái thực sự thay đổi
        if (oldStatus !== status) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.user._id,
                action: 'status_changed',
                description: `Đã thay đổi trạng thái từ "${oldStatus}" sang "${status}"`,
                details: {
                    oldStatus,
                    newStatus: status
                }
            });
        }

        let completedEmailSummary = null;

        if (oldStatus !== 'completed' && status === 'completed') {
            completedEmailSummary = await notifyTaskCompleted(
                task,
                req.user._id
            );
        }

        await task.populate(
            'createdBy',
            'fullName email avatarUrl'
        );

        await task.populate(
            'assigneeIds',
            'fullName email avatarUrl'
        );

        await task.populate(
            'primaryAssigneeId',
            'fullName email avatarUrl'
        );

        return res.status(200).json({
            message: 'Cập nhật trạng thái thành công!',
            task,
            completedEmailSummary
        });
    } catch (error) {
        console.error('Lỗi cập nhật trạng thái:', error);

        return res.status(500).json({
            message: 'Không thể cập nhật trạng thái!',
            error: error.message
        });
    }
};

// ============================
// C1: XEM NGƯỜI ĐƯỢC GIAO
// ============================

const getTaskAssignees = async (req, res) => {
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

        if (!await canViewTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Bạn không có quyền xem công việc này!'
            });
        }

        return res.status(200).json({
            message: 'Lấy danh sách người được giao thành công!',
            createdBy: task.createdBy,
            primaryAssignee: task.primaryAssigneeId,
            assignees: task.assigneeIds
        });
    } catch (error) {
        console.error('Lỗi lấy danh sách người được giao:', error);

        return res.status(500).json({
            message: 'Không thể lấy danh sách người được giao!',
            error: error.message
        });
    }
};

// ============================
// C1: GIAO CÔNG VIỆC
// ============================

const assignTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { userIds, primaryAssigneeId } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        if (!Array.isArray(userIds) || userIds.length === 0) {
            return res.status(400).json({
                message: 'Vui lòng chọn ít nhất một người!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo công việc mới được giao việc!'
            });
        }

        const uniqueIds = [...new Set(userIds.map(String))];

        if (uniqueIds.some(userId =>
            !mongoose.Types.ObjectId.isValid(userId)
        )) {
            return res.status(400).json({
                message: 'Có ID người dùng không hợp lệ!'
            });
        }

        if (
            !primaryAssigneeId ||
            !mongoose.Types.ObjectId.isValid(primaryAssigneeId)
        ) {
            return res.status(400).json({
                message: 'Vui lòng chọn người phụ trách chính hợp lệ!'
            });
        }

        if (!uniqueIds.includes(primaryAssigneeId.toString())) {
            return res.status(400).json({
                message: 'Người phụ trách chính phải nằm trong danh sách được giao!'
            });
        }

        const users = await User.find({
            _id: { $in: uniqueIds }
        });

        if (users.length !== uniqueIds.length) {
            return res.status(404).json({
                message: 'Không tìm thấy một hoặc nhiều người dùng!'
            });
        }

        const oldAssigneeIds = (task.assigneeIds || []).map(
            user => getObjectId(user)
        );

        const oldPrimaryAssigneeId = getObjectId(
            task.primaryAssigneeId
        );

        task.assigneeIds = uniqueIds;
        task.primaryAssigneeId = primaryAssigneeId;

        await task.save();

        // E4: Ghi lịch sử giao việc khi có thay đổi
        const assignmentChanged =
            JSON.stringify([...oldAssigneeIds].sort()) !==
                JSON.stringify([...uniqueIds].sort()) ||
            oldPrimaryAssigneeId !== primaryAssigneeId.toString();

        if (assignmentChanged) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.user._id,
                action: 'assigned',
                description: 'Đã cập nhật danh sách người được giao công việc',
                details: {
                    oldAssigneeIds,
                    newAssigneeIds: uniqueIds,
                    oldPrimaryAssigneeId,
                    newPrimaryAssigneeId: primaryAssigneeId
                }
            });
        }

        await task.populate(
            'assigneeIds',
            'fullName email avatarUrl'
        );

        await task.populate(
            'primaryAssigneeId',
            'fullName email avatarUrl'
        );

        return res.status(200).json({
            message: 'Giao công việc thành công!',
            assignees: task.assigneeIds,
            primaryAssignee: task.primaryAssigneeId
        });
    } catch (error) {
        console.error('Lỗi giao công việc:', error);

        return res.status(500).json({
            message: 'Không thể giao công việc!',
            error: error.message
        });
    }
};

// ============================
// C2.1: LẤY DANH SÁCH NGƯỜI ĐƯỢC CHIA SẺ
// ============================

const getTaskShares = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!await canViewTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Bạn không có quyền xem công việc này!'
            });
        }

        const shares = await TaskShare.find({ taskId: id })
            .populate('userId', 'fullName email avatarUrl')
            .populate('sharedBy', 'fullName email avatarUrl')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Lấy danh sách chia sẻ thành công!',
            shares
        });
    } catch (error) {
        console.error('Lỗi lấy danh sách chia sẻ:', error);

        return res.status(500).json({
            message: 'Không thể lấy danh sách chia sẻ!',
            error: error.message
        });
    }
};

// ============================
// C2.2: CHIA SẺ CÔNG VIỆC
// ============================

const shareTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { userIds, permission } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        if (!Array.isArray(userIds) || userIds.length === 0) {
            return res.status(400).json({
                message: 'Vui lòng chọn ít nhất một người!'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyền chia sẻ không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo công việc mới được chia sẻ!'
            });
        }

        const uniqueIds = [...new Set(userIds.map(String))];

        if (uniqueIds.some(userId =>
            !mongoose.Types.ObjectId.isValid(userId)
        )) {
            return res.status(400).json({
                message: 'Có ID người dùng không hợp lệ!'
            });
        }

        if (uniqueIds.includes(req.user._id.toString())) {
            return res.status(400).json({
                message: 'Bạn không thể chia sẻ công việc cho chính mình!'
            });
        }

        const users = await User.find({
            _id: { $in: uniqueIds }
        });

        if (users.length !== uniqueIds.length) {
            return res.status(404).json({
                message: 'Không tìm thấy một hoặc nhiều người dùng!'
            });
        }

        for (const userId of uniqueIds) {
            const existingShare = await TaskShare.findOne({
                taskId: id,
                userId
            });

            await TaskShare.findOneAndUpdate(
                {
                    taskId: id,
                    userId
                },
                {
                    $set: {
                        permission,
                        sharedBy: req.user._id
                    },
                    $setOnInsert: {
                        taskId: id,
                        userId
                    }
                },
                {
                    upsert: true,
                    new: true,
                    runValidators: true
                }
            );

            // E4: Ghi lịch sử chia sẻ hoặc thay đổi quyền
            if (!existingShare) {
                await logTaskActivity({
                    taskId: task._id,
                    userId: req.user._id,
                    action: 'shared',
                    description: `Đã chia sẻ công việc cho người dùng ${userId} với quyền ${permission}`,
                    details: {
                        sharedUserId: userId,
                        permission
                    }
                });
            } else if (existingShare.permission !== permission) {
                await logTaskActivity({
                    taskId: task._id,
                    userId: req.user._id,
                    action: 'permission_updated',
                    description: `Đã thay đổi quyền chia sẻ của người dùng ${userId} thành ${permission}`,
                    details: {
                        sharedUserId: userId,
                        oldPermission: existingShare.permission,
                        newPermission: permission
                    }
                });
            }
        }

        const shares = await TaskShare.find({ taskId: id })
            .populate('userId', 'fullName email avatarUrl')
            .populate('sharedBy', 'fullName email avatarUrl')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Chia sẻ công việc thành công!',
            shares
        });
    } catch (error) {
        console.error('Lỗi chia sẻ công việc:', error);

        return res.status(500).json({
            message: 'Không thể chia sẻ công việc!',
            error: error.message
        });
    }
};

// ============================
// C2.3: THAY ĐỔI QUYỀN CHIA SẺ
// ============================

const updateTaskShare = async (req, res) => {
    try {
        const { id, shareId } = req.params;
        const { permission } = req.body;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(shareId)
        ) {
            return res.status(400).json({
                message: 'ID không hợp lệ!'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyền chia sẻ không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo công việc mới được đổi quyền!'
            });
        }

        const oldShare = await TaskShare.findOne({
            _id: shareId,
            taskId: id
        });

        if (!oldShare) {
            return res.status(404).json({
                message: 'Không tìm thấy thông tin chia sẻ!'
            });
        }

        const oldPermission = oldShare.permission;
        const sharedUserId = getObjectId(oldShare.userId);

        const share = await TaskShare.findOneAndUpdate(
            {
                _id: shareId,
                taskId: id
            },
            {
                permission
            },
            {
                new: true,
                runValidators: true
            }
        )
            .populate('userId', 'fullName email avatarUrl')
            .populate('sharedBy', 'fullName email avatarUrl');

        // E4: Ghi lịch sử khi quyền thực sự thay đổi
        if (oldPermission !== permission) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.user._id,
                action: 'permission_updated',
                description: `Đã thay đổi quyền chia sẻ từ ${oldPermission} thành ${permission}`,
                details: {
                    sharedUserId,
                    oldPermission,
                    newPermission: permission
                }
            });
        }

        return res.status(200).json({
            message: 'Cập nhật quyền chia sẻ thành công!',
            share
        });
    } catch (error) {
        console.error('Lỗi cập nhật quyền chia sẻ:', error);

        return res.status(500).json({
            message: 'Không thể cập nhật quyền chia sẻ!',
            error: error.message
        });
    }
};

// ============================
// C2.4: THU HỒI QUYỀN CHIA SẺ
// ============================

const removeTaskShare = async (req, res) => {
    try {
        const { id, shareId } = req.params;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(shareId)
        ) {
            return res.status(400).json({
                message: 'ID không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo công việc mới được thu hồi chia sẻ!'
            });
        }

        const share = await TaskShare.findOneAndDelete({
            _id: shareId,
            taskId: id
        });

        if (!share) {
            return res.status(404).json({
                message: 'Không tìm thấy thông tin chia sẻ!'
            });
        }

        // E4: Ghi lịch sử thu hồi quyền
        await logTaskActivity({
            taskId: task._id,
            userId: req.user._id,
            action: 'share_removed',
            description: `Đã thu hồi quyền chia sẻ của người dùng ${getObjectId(share.userId)}`,
            details: {
                sharedUserId: getObjectId(share.userId),
                oldPermission: share.permission
            }
        });

        return res.status(200).json({
            message: 'Thu hồi quyền chia sẻ thành công!'
        });
    } catch (error) {
        console.error('Lỗi thu hồi chia sẻ:', error);

        return res.status(500).json({
            message: 'Không thể thu hồi quyền chia sẻ!',
            error: error.message
        });
    }
};

// ============================
// E4: LẤY LỊCH SỬ HOẠT ĐỘNG
// ============================

const getTaskActivities = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID công việc không hợp lệ!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc!'
            });
        }

        if (!await canViewTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Bạn không có quyền xem lịch sử công việc này!'
            });
        }

        const activities = await TaskActivity.find({
            taskId: id
        })
            .populate('userId', 'fullName email avatarUrl')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Lấy lịch sử hoạt động thành công!',
            activities
        });
    } catch (error) {
        console.error('E4: Lỗi lấy lịch sử hoạt động:', error);

        return res.status(500).json({
            message: 'Không thể lấy lịch sử hoạt động!',
            error: error.message
        });
    }
};

// ============================
// EXPORT
// ============================

module.exports = {
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
    removeTaskShare,

    // E4
    getTaskActivities
};
