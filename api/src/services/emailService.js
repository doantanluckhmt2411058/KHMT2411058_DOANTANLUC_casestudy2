
const nodemailer = require('nodemailer');

// Tạo kết nối SMTP
const createTransporter = () => {
    const required = [
        'SMTP_HOST',
        'SMTP_PORT',
        'SMTP_USER',
        'SMTP_PASS'
    ];

    const missing = required.filter(key => !process.env[key]);

    if (missing.length > 0) {
        throw new Error(
            `Thiếu cấu hình email trong file .env: ${missing.join(', ')}`
        );
    }

    return nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT),
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
};

// Tránh lỗi khi tên hoặc nội dung có ký tự HTML
const escapeHtml = (value = '') =>
    String(value).replace(/[&<>"']/g, char => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    })[char]);

// D1: Gửi email khi giao công việc mới
const sendAssignmentEmail = async ({
    recipient,
    task,
    assigner,
    isPrimary
}) => {
    if (!recipient || !recipient.email) {
        throw new Error('Người nhận không có địa chỉ email!');
    }

    const transporter = createTransporter();

    const taskTitle = escapeHtml(task.title || 'Công việc mới');
    const assignerName = escapeHtml(assigner?.fullName || 'Người dùng');
    const description = escapeHtml(task.description || 'Không có mô tả');

    const dueDate = task.dueDate
        ? new Date(task.dueDate).toLocaleDateString('vi-VN')
        : 'Chưa thiết lập';

    const subject = `Bạn được giao công việc: ${task.title}`;

    const html = `
        <div style="font-family: Arial, sans-serif; line-height: 1.6;">
            <h2>Bạn có công việc mới!</h2>
            <p>Xin chào <strong>${escapeHtml(recipient.fullName || '')}</strong>,</p>
            <p>Bạn vừa được <strong>${assignerName}</strong> giao một công việc mới.</p>
            <h3>${taskTitle}</h3>
            <p><strong>Mô tả:</strong> ${description}</p>
            <p><strong>Hạn hoàn thành:</strong> ${dueDate}</p>
            <p><strong>Vai trò:</strong>
                ${isPrimary ? 'Người phụ trách chính' : 'Người được giao'}
            </p>
            <p>Vui lòng đăng nhập ứng dụng Task Manager để xem chi tiết.</p>
            <hr />
            <p style="color: #777;">
                Đây là email tự động từ ứng dụng quản lý công việc nhóm.
            </p>
        </div>
    `;

    const info = await transporter.sendMail({
        from: process.env.SMTP_FROM || process.env.SMTP_USER,
        to: recipient.email,
        subject,
        html
    });

    return {
        email: recipient.email,
        messageId: info.messageId
    };
};

// D2: Gửi email khi được mời xem hoặc tham gia công việc
const sendShareInvitationEmail = async ({
    recipient,
    task,
    inviter,
    permission
}) => {
    if (!recipient || !recipient.email) {
        throw new Error('Người nhận không có địa chỉ email!');
    }

    const transporter = createTransporter();

    const taskTitle = escapeHtml(task.title || 'Công việc');
    const inviterName = escapeHtml(inviter?.fullName || 'Người dùng');
    const description = escapeHtml(task.description || 'Không có mô tả');

    const roleText = permission === 'editor'
        ? 'Được phép xem và chỉnh sửa công việc'
        : 'Chỉ được phép xem công việc';

    const dueDate = task.dueDate
        ? new Date(task.dueDate).toLocaleDateString('vi-VN')
        : 'Chưa thiết lập';

    const subject = `Bạn được mời tham gia công việc: ${task.title}`;

    const html = `
        <div style="font-family: Arial, sans-serif; line-height: 1.6;">
            <h2>Bạn nhận được lời mời tham gia công việc!</h2>

            <p>
                Xin chào
                <strong>${escapeHtml(recipient.fullName || '')}</strong>,
            </p>

            <p>
                <strong>${inviterName}</strong>
                đã chia sẻ một công việc với bạn trên Task Manager.
            </p>

            <h3>${taskTitle}</h3>

            <p><strong>Mô tả:</strong> ${description}</p>
            <p><strong>Hạn hoàn thành:</strong> ${dueDate}</p>
            <p><strong>Quyền được cấp:</strong> ${roleText}</p>

            <p>
                Vui lòng đăng nhập ứng dụng Task Manager
                để xem công việc được chia sẻ.
            </p>

            <hr />

            <p style="color: #777;">
                Đây là email tự động từ ứng dụng quản lý công việc nhóm.
            </p>
        </div>
    `;

    const info = await transporter.sendMail({
        from: process.env.SMTP_FROM || process.env.SMTP_USER,
        to: recipient.email,
        subject,
        html
    });

    return {
        email: recipient.email,
        messageId: info.messageId
    };
};

module.exports = {
    sendAssignmentEmail,
    sendShareInvitationEmail
};
