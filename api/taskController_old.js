
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const TaskShare = require('../models/TaskShare');

// ============================
// HĂ€M KIá»‚M TRA QUYá»€N
// ============================

// Láº¥y ID dĂ¹ dá»¯ liá»‡u Ä‘Ă£ populate hay chÆ°a
const getObjectId = (value) => {
    if (!value) return null;
    return (value._id || value).toString();
};

// Kiá»ƒm tra quyá»n xem cĂ´ng viá»‡c
const canViewTask = async (task, userId) => {
    const id = userId.toString();

    // NgÆ°á»i táº¡o
    if (getObjectId(task.createdBy) === id) {
        return true;
    }

    // NgÆ°á»i Ä‘Æ°á»£c giao
    const isAssignee = task.assigneeIds.some(
        user => getObjectId(user) === id
    );

    if (isAssignee) return true;

    // NgÆ°á»i Ä‘Æ°á»£c chia sáº»
    const share = await TaskShare.findOne({
        taskId: task._id,
        userId: id
    });

    return !!share;
};

// Kiá»ƒm tra quyá»n chá»‰nh sá»­a cĂ´ng viá»‡c
const canEditTask = async (task, userId) => {
    const id = userId.toString();

    // NgÆ°á»i táº¡o
    if (getObjectId(task.createdBy) === id) {
        return true;
    }

    // NgÆ°á»i Ä‘Æ°á»£c giao
    const isAssignee = task.assigneeIds.some(
        user => getObjectId(user) === id
    );

    if (isAssignee) return true;

    // NgÆ°á»i Ä‘Æ°á»£c chia sáº» vá»›i quyá»n Editor
    const share = await TaskShare.findOne({
        taskId: task._id,
        userId: id,
        permission: 'editor'
    });

    return !!share;
};

// Kiá»ƒm tra ngÆ°á»i táº¡o cĂ´ng viá»‡c
const isTaskOwner = (task, userId) => {
    return getObjectId(task.createdBy) === userId.toString();
};

// ============================
// B: Táº O CĂ”NG VIá»†C
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
                message: 'Vui lĂ²ng nháº­p tĂªn cĂ´ng viá»‡c!'
            });
        }

        const allowedPriorities = ['low', 'medium', 'high'];
        const allowedStatuses = ['todo', 'in_progress', 'completed'];

        if (priority && !allowedPriorities.includes(priority)) {
            return res.status(400).json({
                message: 'Má»©c Ä‘á»™ Æ°u tiĂªn khĂ´ng há»£p lá»‡!'
            });
        }

        if (status && !allowedStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Tráº¡ng thĂ¡i cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
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
            message: 'Táº¡o cĂ´ng viá»‡c thĂ nh cĂ´ng!',
            task
        });

    } catch (error) {
        console.error('Lá»—i táº¡o cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ táº¡o cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};

// ============================
// B1: Láº¤Y DANH SĂCH CĂ”NG VIá»†C
// ============================


const getTasks = async (req, res) => {
    try {
        const userId = req.user._id;
        const userIdString = userId.toString();

        // Láº¥y danh sĂ¡ch cĂ´ng viá»‡c Ä‘Æ°á»£c chia sáº» cho ngÆ°á»i dĂ¹ng
        const sharedRecords = await TaskShare.find({
            userId: userId
        }).select('taskId permission');

        const sharedTaskIds = sharedRecords.map(
            share => share.taskId
        );

        // Láº¥y cĂ´ng viá»‡c do ngÆ°á»i dĂ¹ng táº¡o, Ä‘Æ°á»£c giao hoáº·c Ä‘Æ°á»£c chia sáº»
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

        // LÆ°u quyá»n chia sáº» Ä‘á»ƒ tra cá»©u nhanh
        const shareMap = new Map();

        for (const share of sharedRecords) {
            shareMap.set(
                share.taskId.toString(),
                share.permission
            );
        }

        // Bá»• sung vai trĂ² vĂ  tiáº¿n Ä‘á»™ cho tá»«ng cĂ´ng viá»‡c
        const result = tasks.map(task => {
            const taskData = task.toObject();
            const roles = [];

            // Kiá»ƒm tra ngÆ°á»i táº¡o
            if (getObjectId(task.createdBy) === userIdString) {
                roles.push('creator');
            }

            // Kiá»ƒm tra ngÆ°á»i Ä‘Æ°á»£c giao
            const isAssignee = task.assigneeIds.some(
                user => getObjectId(user) === userIdString
            );

            if (isAssignee) {
                roles.push('assignee');
            }

            // Kiá»ƒm tra ngÆ°á»i Ä‘Æ°á»£c chia sáº»
            const sharePermission = shareMap.get(
                task._id.toString()
            );

            if (sharePermission) {
                roles.push('shared');
            }

            // TĂ­nh tiáº¿n Ä‘á»™ dá»±a trĂªn tráº¡ng thĂ¡i
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
            message: 'Láº¥y danh sĂ¡ch cĂ´ng viá»‡c thĂ nh cĂ´ng!',
            currentUserId: userIdString,
            tasks: result
        });

    } catch (error) {
        console.error('Lá»—i láº¥y danh sĂ¡ch cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ láº¥y danh sĂ¡ch cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};


// ============================
// B2: Láº¤Y CHI TIáº¾T CĂ”NG VIá»†C
// ============================

const getTaskById = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id)
            .populate('createdBy', 'fullName email avatarUrl')
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl');

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!await canViewTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Báº¡n khĂ´ng cĂ³ quyá»n xem cĂ´ng viá»‡c nĂ y!'
            });
        }

        return res.status(200).json({
            message: 'Láº¥y chi tiáº¿t cĂ´ng viá»‡c thĂ nh cĂ´ng!',
            task
        });

    } catch (error) {
        console.error('Lá»—i láº¥y chi tiáº¿t cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ láº¥y chi tiáº¿t cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};

// ============================
// B4: CHá»ˆNH Sá»¬A CĂ”NG VIá»†C
// ============================

const updateTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!await canEditTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Báº¡n khĂ´ng cĂ³ quyá»n chá»‰nh sá»­a cĂ´ng viá»‡c nĂ y!'
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
                    message: 'TĂªn cĂ´ng viá»‡c khĂ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng!'
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
                    message: 'Má»©c Ä‘á»™ Æ°u tiĂªn khĂ´ng há»£p lá»‡!'
                });
            }
            task.priority = priority;
        }

        if (status !== undefined) {
            if (!['todo', 'in_progress', 'completed'].includes(status)) {
                return res.status(400).json({
                    message: 'Tráº¡ng thĂ¡i cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
                });
            }
            task.status = status;
        }

        await task.save();

        await task.populate('createdBy', 'fullName email avatarUrl');
        await task.populate('assigneeIds', 'fullName email avatarUrl');
        await task.populate('primaryAssigneeId', 'fullName email avatarUrl');

        return res.status(200).json({
            message: 'Cáº­p nháº­t cĂ´ng viá»‡c thĂ nh cĂ´ng!',
            task
        });

    } catch (error) {
        console.error('Lá»—i cáº­p nháº­t cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ cáº­p nháº­t cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};

// ============================
// B5: XĂ“A CĂ”NG VIá»†C
// ============================

const deleteTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        // Chá»‰ ngÆ°á»i táº¡o má»›i Ä‘Æ°á»£c xĂ³a
        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chá»‰ ngÆ°á»i táº¡o cĂ´ng viá»‡c má»›i Ä‘Æ°á»£c xĂ³a!'
            });
        }

        await Task.findByIdAndDelete(id);

        // XĂ³a luĂ´n dá»¯ liá»‡u chia sáº» liĂªn quan
        await TaskShare.deleteMany({ taskId: id });

        return res.status(200).json({
            message: 'XĂ³a cĂ´ng viá»‡c thĂ nh cĂ´ng!'
        });

    } catch (error) {
        console.error('Lá»—i xĂ³a cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ xĂ³a cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};

// ============================
// B6: Cáº¬P NHáº¬T TRáº NG THĂI
// ============================

const updateTaskStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        const allowedStatuses = [
            'todo',
            'in_progress',
            'completed'
        ];

        if (!allowedStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Tráº¡ng thĂ¡i cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        // Pháº£i tĂ¬m task trÆ°á»›c khi kiá»ƒm tra quyá»n
        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!await canEditTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Báº¡n khĂ´ng cĂ³ quyá»n cáº­p nháº­t cĂ´ng viá»‡c nĂ y!'
            });
        }

        task.status = status;
        await task.save();

        return res.status(200).json({
            message: 'Cáº­p nháº­t tráº¡ng thĂ¡i thĂ nh cĂ´ng!',
            task
        });

    } catch (error) {
        console.error('Lá»—i cáº­p nháº­t tráº¡ng thĂ¡i:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ cáº­p nháº­t tráº¡ng thĂ¡i!',
            error: error.message
        });
    }
};

// ============================
// C1: XEM NGÆ¯á»œI ÄÆ¯á»¢C GIAO
// ============================


const getTaskAssignees = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id)
            .populate('createdBy', 'fullName email avatarUrl')
            .populate('assigneeIds', 'fullName email avatarUrl')
            .populate('primaryAssigneeId', 'fullName email avatarUrl');

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!await canViewTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Báº¡n khĂ´ng cĂ³ quyá»n xem cĂ´ng viá»‡c nĂ y!'
            });
        }

        return res.status(200).json({
            message: 'Láº¥y danh sĂ¡ch ngÆ°á»i Ä‘Æ°á»£c giao thĂ nh cĂ´ng!',
            createdBy: task.createdBy,
            primaryAssignee: task.primaryAssigneeId,
            assignees: task.assigneeIds
        });

    } catch (error) {
        console.error('Lá»—i láº¥y danh sĂ¡ch ngÆ°á»i Ä‘Æ°á»£c giao:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ láº¥y danh sĂ¡ch ngÆ°á»i Ä‘Æ°á»£c giao!',
            error: error.message
        });
    }
};


// ============================
// C1: GIAO CĂ”NG VIá»†C
// ============================


const assignTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { userIds, primaryAssigneeId } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        if (!Array.isArray(userIds) || userIds.length === 0) {
            return res.status(400).json({
                message: 'Vui lĂ²ng chá»n Ă­t nháº¥t má»™t ngÆ°á»i!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chá»‰ ngÆ°á»i táº¡o cĂ´ng viá»‡c má»›i Ä‘Æ°á»£c giao viá»‡c!'
            });
        }

        const uniqueIds = [...new Set(userIds.map(String))];

        if (uniqueIds.some(userId =>
            !mongoose.Types.ObjectId.isValid(userId)
        )) {
            return res.status(400).json({
                message: 'CĂ³ ID ngÆ°á»i dĂ¹ng khĂ´ng há»£p lá»‡!'
            });
        }

        if (
            !primaryAssigneeId ||
            !mongoose.Types.ObjectId.isValid(primaryAssigneeId)
        ) {
            return res.status(400).json({
                message: 'Vui lĂ²ng chá»n ngÆ°á»i phá»¥ trĂ¡ch chĂ­nh há»£p lá»‡!'
            });
        }

        if (!uniqueIds.includes(primaryAssigneeId.toString())) {
            return res.status(400).json({
                message: 'NgÆ°á»i phá»¥ trĂ¡ch chĂ­nh pháº£i náº±m trong danh sĂ¡ch Ä‘Æ°á»£c giao!'
            });
        }

        const users = await User.find({
            _id: { $in: uniqueIds }
        });

        if (users.length !== uniqueIds.length) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y má»™t hoáº·c nhiá»u ngÆ°á»i dĂ¹ng!'
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
            message: 'Giao cĂ´ng viá»‡c thĂ nh cĂ´ng!',
            assignees: task.assigneeIds,
            primaryAssignee: task.primaryAssigneeId
        });

    } catch (error) {
        console.error('Lá»—i giao cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ giao cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};


// ============================
// C2: CHIA Sáºº CĂ”NG VIá»†C
// ============================

// C2.1: Láº¥y danh sĂ¡ch ngÆ°á»i Ä‘Æ°á»£c chia sáº»
const getTaskShares = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!await canViewTask(task, req.user._id)) {
            return res.status(403).json({
                message: 'Báº¡n khĂ´ng cĂ³ quyá»n xem cĂ´ng viá»‡c nĂ y!'
            });
        }

        const shares = await TaskShare.find({ taskId: id })
            .populate('userId', 'fullName email avatarUrl')
            .populate('sharedBy', 'fullName email avatarUrl')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Láº¥y danh sĂ¡ch chia sáº» thĂ nh cĂ´ng!',
            shares
        });

    } catch (error) {
        console.error('Lá»—i láº¥y danh sĂ¡ch chia sáº»:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ láº¥y danh sĂ¡ch chia sáº»!',
            error: error.message
        });
    }
};

// C2.2: Chia sáº» cĂ´ng viá»‡c cho má»™t hoáº·c nhiá»u ngÆ°á»i
const shareTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { userIds, permission } = req.body;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cĂ´ng viá»‡c khĂ´ng há»£p lá»‡!'
            });
        }

        if (!Array.isArray(userIds) || userIds.length === 0) {
            return res.status(400).json({
                message: 'Vui lĂ²ng chá»n Ă­t nháº¥t má»™t ngÆ°á»i!'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyá»n chia sáº» khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chá»‰ ngÆ°á»i táº¡o cĂ´ng viá»‡c má»›i Ä‘Æ°á»£c chia sáº»!'
            });
        }

        const uniqueIds = [...new Set(userIds.map(String))];

        if (uniqueIds.some(userId =>
            !mongoose.Types.ObjectId.isValid(userId)
        )) {
            return res.status(400).json({
                message: 'CĂ³ ID ngÆ°á»i dĂ¹ng khĂ´ng há»£p lá»‡!'
            });
        }

        if (uniqueIds.includes(req.user._id.toString())) {
            return res.status(400).json({
                message: 'Báº¡n khĂ´ng thá»ƒ chia sáº» cĂ´ng viá»‡c cho chĂ­nh mĂ¬nh!'
            });
        }

        const users = await User.find({
            _id: { $in: uniqueIds }
        });

        if (users.length !== uniqueIds.length) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y má»™t hoáº·c nhiá»u ngÆ°á»i dĂ¹ng!'
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
            message: 'Chia sáº» cĂ´ng viá»‡c thĂ nh cĂ´ng!',
            shares
        });

    } catch (error) {
        console.error('Lá»—i chia sáº» cĂ´ng viá»‡c:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ chia sáº» cĂ´ng viá»‡c!',
            error: error.message
        });
    }
};

// C2.3: Thay Ä‘á»•i quyá»n chia sáº»
const updateTaskShare = async (req, res) => {
    try {
        const { id, shareId } = req.params;
        const { permission } = req.body;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(shareId)
        ) {
            return res.status(400).json({
                message: 'ID khĂ´ng há»£p lá»‡!'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyá»n chia sáº» khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chá»‰ ngÆ°á»i táº¡o cĂ´ng viá»‡c má»›i Ä‘Æ°á»£c Ä‘á»•i quyá»n!'
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
                message: 'KhĂ´ng tĂ¬m tháº¥y thĂ´ng tin chia sáº»!'
            });
        }

        return res.status(200).json({
            message: 'Cáº­p nháº­t quyá»n chia sáº» thĂ nh cĂ´ng!',
            share
        });

    } catch (error) {
        console.error('Lá»—i cáº­p nháº­t quyá»n chia sáº»:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ cáº­p nháº­t quyá»n chia sáº»!',
            error: error.message
        });
    }
};

// C2.4: Thu há»“i quyá»n chia sáº»
const removeTaskShare = async (req, res) => {
    try {
        const { id, shareId } = req.params;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(shareId)
        ) {
            return res.status(400).json({
                message: 'ID khĂ´ng há»£p lá»‡!'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y cĂ´ng viá»‡c!'
            });
        }

        if (!isTaskOwner(task, req.user._id)) {
            return res.status(403).json({
                message: 'Chá»‰ ngÆ°á»i táº¡o cĂ´ng viá»‡c má»›i Ä‘Æ°á»£c thu há»“i chia sáº»!'
            });
        }

        const share = await TaskShare.findOneAndDelete({
            _id: shareId,
            taskId: id
        });

        if (!share) {
            return res.status(404).json({
                message: 'KhĂ´ng tĂ¬m tháº¥y thĂ´ng tin chia sáº»!'
            });
        }

        return res.status(200).json({
            message: 'Thu há»“i quyá»n chia sáº» thĂ nh cĂ´ng!'
        });

    } catch (error) {
        console.error('Lá»—i thu há»“i chia sáº»:', error);

        return res.status(500).json({
            message: 'KhĂ´ng thá»ƒ thu há»“i quyá»n chia sáº»!',
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
