
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

            // Lưu thông tin cũ trước khi cập nhật
            const oldValues = {
                title: task.title,
                description: task.description || '',
                startDate: task.startDate,
                dueDate: task.dueDate,
                priority: task.priority
            };

            // Kiểm tra và cập nhật tên công việc
            if (title !== undefined) {
                if (typeof title !== 'string' || !title.trim()) {
                    return res.status(400).json({
                        message: 'Tên công việc không được để trống!'
                    });
                }

                task.title = title.trim();
            }

            // Cập nhật mô tả
            if (description !== undefined) {
                task.description = description;
            }

            // Cập nhật ngày bắt đầu
            if (startDate !== undefined) {
                task.startDate = startDate || null;
            }

            // Cập nhật hạn hoàn thành
            if (dueDate !== undefined) {
                task.dueDate = dueDate || null;
            }

            // Kiểm tra và cập nhật độ ưu tiên
            if (priority !== undefined) {
                if (!['low', 'medium', 'high'].includes(priority)) {
                    return res.status(400).json({
                        message: 'Mức độ ưu tiên không hợp lệ!'
                    });
                }

                task.priority = priority;
            }

            // Cập nhật trạng thái
            // Không gửi email trạng thái ở D3 để tránh trùng D4
            if (status !== undefined) {
                if (!['todo', 'in_progress', 'completed'].includes(status)) {
                    return res.status(400).json({
                        message: 'Trạng thái công việc không hợp lệ!'
                    });
                }

                task.status = status;
            }

            // Hàm chuyển ngày thành chuỗi để so sánh
            const dateKey = (value) => {
                if (!value) return '';

                const date = new Date(value);

                if (Number.isNaN(date.getTime())) {
                    return String(value);
                }

                return date.toISOString();
            };

            // Hàm hiển thị ngày theo định dạng Việt Nam
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

            // Danh sách những thông tin thực sự thay đổi
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

            // So sánh tên công việc
            addChange(
                'Tên công việc',
                oldValues.title,
                task.title
            );

            // So sánh mô tả
            addChange(
                'Mô tả',
                oldValues.description,
                task.description || ''
            );

            // So sánh ngày bắt đầu
            if (
                dateKey(oldValues.startDate) !==
                dateKey(task.startDate)
            ) {
                changes.push({
                    label: 'Ngày bắt đầu',
                    oldValue: formatDate(oldValues.startDate),
                    newValue: formatDate(task.startDate)
                });
            }

            // So sánh hạn hoàn thành
            if (
                dateKey(oldValues.dueDate) !==
                dateKey(task.dueDate)
            ) {
                changes.push({
                    label: 'Hạn hoàn thành',
                    oldValue: formatDate(oldValues.dueDate),
                    newValue: formatDate(task.dueDate)
                });
            }

            // So sánh độ ưu tiên
            if (oldValues.priority !== task.priority) {
                changes.push({
                    label: 'Độ ưu tiên',
                    oldValue: priorityLabels[oldValues.priority] || oldValues.priority,
                    newValue: priorityLabels[task.priority] || task.priority
                });
            }

            // Lưu thay đổi vào MongoDB trước
            await task.save();

            const emailSummary = {
                total: 0,
                success: [],
                failed: []
            };

            // Chỉ gửi email khi có thông tin quan trọng thực sự thay đổi
            if (changes.length > 0) {
                // Lấy danh sách người được chia sẻ công việc
                const shares = await TaskShare.find({
                    taskId: id
                }).select('userId');

                // Gom ID người tạo, người được giao và người được chia sẻ
                const recipientIds = new Set();

                const creatorId = getObjectId(task.createdBy);

                if (creatorId) {
                    recipientIds.add(creatorId);
                }

                for (const assignee of task.assigneeIds || []) {
                    const assigneeId = getObjectId(assignee);

                    if (assigneeId) {
                        recipientIds.add(assigneeId);
                    }
                }

                for (const share of shares) {
                    const sharedUserId = getObjectId(share.userId);

                    if (sharedUserId) {
                        recipientIds.add(sharedUserId);
                    }
                }

                // Không gửi email cho chính người đang chỉnh sửa
                recipientIds.delete(req.user._id.toString());

                const recipients = await User.find({
                    _id: { $in: [...recipientIds] }
                }).select('fullName email');

                const updater = await User.findById(req.user._id)
                    .select('fullName email');

                emailSummary.total = recipients.length;

                // Gửi email cho từng người liên quan
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

            // Lấy thông tin đầy đủ để trả về giao diện
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
                emailSummary
            });

        } catch (error) {
            console.error('Lỗi cập nhật công việc:', error);

            return res.status(500).json({
                message: 'Không thể cập nhật công việc!',
                error: error.message
            });
        }
    };
