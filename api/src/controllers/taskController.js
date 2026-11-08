
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const TaskShare = require('../models/TaskShare');

// ============================
// HÀM KIỂM TRA QUYỀN
// ============================

// Lấy ID dù dữ liệu đã populate hay chưa
const getObjectId = (value) => {
    if (!value) return null;
    return (value._id || value).toString();
};

// Kiểm tra quyền xem công việc
const canViewTask = async (task, userId) => {
    const id = userId.toString();

    // Người tạo
    if (getObjectId(task.createdBy) === id) {
        return true;
    }

    // Người được giao
    const isAssignee = task.assigneeIds.some(
        user => getObjectId(user) === id
    );

    if (isAssignee) return true;

    // Người được chia sẻ
    const share = await TaskShare.findOne({
        taskId: task._id,
        userId: id
    });

    return !!share;
};

// Kiểm tra quyền chỉnh sửa công việc
const canEditTask = async (task, userId) => {
    const id = userId.toString();

    // Người tạo
    if (getObjectId(task.createdBy) === id) {
        return true;
    }

    // Người được giao
    const isAssignee = task.assigneeIds.some(
        user => getObjectId(user) === id
    );

    if (isAssignee) return true;

    // Người được chia sẻ với quyền Editor
    const share = await TaskShare.findOne({
        taskId: task._id,
        userId: id,
        permission: 'editor'
    });

    return !!share;
};

// Kiểm tra người tạo công việc
const isTaskOwner = (task, userId) => {
    return getObjectId(task.createdBy) === userId.toString();
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

        // Lấy danh sách công việc được chia sẻ cho người dùng
        const sharedRecords = await TaskShare.find({
            userId: userId
        }).select('taskId permission');

        const sharedTaskIds = sharedRecords.map(
            share => share.taskId
        );

        // Lấy công việc do người dùng tạo, được giao hoặc được chia sẻ
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

        // Lưu quyền chia sẻ để tra cứu nhanh
        const shareMap = new Map();

        for (const share of sharedRecords) {
            shareMap.set(
                share.taskId.toString(),
                share.permission
            );
        }

        // Bổ sung vai trò và tiến độ cho từng công việc
        const result = tasks.map(task => {
            const taskData = task.toObject();
            const roles = [];

            // Kiểm tra người tạo
            if (getObjectId(task.createdBy) === userIdString) {
                roles.push('creator');
            }

            // Kiểm tra người được giao
            const isAssignee = task.assigneeIds.some(
                user => getObjectId(user) === userIdString
            );

            if (isAssignee) {
                roles.push('assignee');
            }

            // Kiểm tra người được chia sẻ
            const sharePermission = shareMap.get(
                task._id.toString()
            );

            if (sharePermission) {
                roles.push('shared');
            }

            // Tính tiến độ dựa trên trạng thái
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
                progress: progress
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

        if (title !== undefined) {
            if (!title.trim()) {
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

        await task.save();

        await task.populate('createdBy', 'fullName email avatarUrl');
        await task.populate('assigneeIds', 'fullName email avatarUrl');
        await task.populate('primaryAssigneeId', 'fullName email avatarUrl');

        return res.status(200).json({
            message: 'Cập nhật công việc thành công!',
            task
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

        // Chỉ người tạo mới được xóa
        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chỉ người tạo công việc mới được xóa!'
            });
        }

        await Task.findByIdAndDelete(id);

        // Xóa luôn dữ liệu chia sẻ liên quan
        await TaskShare.deleteMany({ taskId: id });

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
// B6: CẬP NHẬT TRẠNG THÁI
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

        // Phải tìm task trước khi kiểm tra quyền
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

        task.status = status;
        await task.save();

        return res.status(200).json({
            message: 'Cập nhật trạng thái thành công!',
            task
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

        task.assigneeIds = uniqueIds;
        task.primaryAssigneeId = primaryAssigneeId;

        await task.save();

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
// C2: CHIA SẺ CÔNG VIỆC
// ============================

// C2.1: Lấy danh sách người được chia sẻ
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

// C2.2: Chia sẻ công việc cho một hoặc nhiều người
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

// C2.3: Thay đổi quyền chia sẻ
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

        if (!share) {
            return res.status(404).json({
                message: 'Không tìm thấy thông tin chia sẻ!'
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

// C2.4: Thu hồi quyền chia sẻ
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

    // C2
    getTaskShares,
    shareTask,
    updateTaskShare,
    removeTaskShare
};
