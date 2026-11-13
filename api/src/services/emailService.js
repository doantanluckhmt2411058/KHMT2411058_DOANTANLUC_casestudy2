
const nodemailer = require('nodemailer');

// ============================
// CẤU HÌNH GỬI EMAIL
// ============================

const createTransporter = () => {
    return nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT || 587),
        secure: String(process.env.SMTP_SECURE).toLowerCase() === 'true',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
};

// ============================
// HÀM CHỐNG HTML INJECTION
// ============================

const escapeHtml = (value) => {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
};

// ============================
// D1: EMAIL KHI ĐƯỢC GIAO CÔNG VIỆC
// ============================

const sendAssignmentEmail = async ({
    recipient,
    task,
    assigner
}) => {
    try {
        if (!recipient?.email) {
            throw new Error('Người nhận không có địa chỉ email!');
        }

        const transporter = createTransporter();

        const recipientName = escapeHtml(recipient.fullName || '');
        const assignerName = escapeHtml(assigner?.fullName || 'Người dùng');
        const taskTitle = escapeHtml(task?.title || 'Công việc');
        const description = escapeHtml(task?.description || 'Không có mô tả');

        const html = `
            <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                <h2>Thông báo giao công việc</h2>
                <p>Xin chào <strong>${recipientName}</strong>,</p>
                <p><strong>${assignerName}</strong> vừa giao cho bạn công việc:</p>
                <h3>${taskTitle}</h3>
                <p><strong>Mô tả:</strong> ${description}</p>
                <p><strong>Trạng thái:</strong> Chưa thực hiện</p>
                <p>Vui lòng đăng nhập Task Manager để xem chi tiết.</p>
                <hr />
                <p style="color: #777;">Email tự động từ ứng dụng quản lý công việc nhóm.</p>
            </div>
        `;

        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || process.env.SMTP_USER,
            to: recipient.email,
            subject: `Bạn được giao công việc: ${task?.title || 'Công việc'}`,
            html
        });

        console.log(`D1: Gửi email giao việc thành công đến ${recipient.email}`);

        return {
            email: recipient.email,
            messageId: info.messageId
        };
    } catch (error) {
        console.error(`D1: Gửi email thất bại đến ${recipient?.email || 'không xác định'}:`, error.message);
        throw error;
    }
};

// ============================
// D2: EMAIL KHI ĐƯỢC CHIA SẺ CÔNG VIỆC
// ============================

const sendShareInvitationEmail = async ({
    recipient,
    task,
    sender,
    permission
}) => {
    try {
        if (!recipient?.email) {
            throw new Error('Người nhận không có địa chỉ email!');
        }

        const transporter = createTransporter();

        const recipientName = escapeHtml(recipient.fullName || '');
        const senderName = escapeHtml(sender?.fullName || 'Người dùng');
        const taskTitle = escapeHtml(task?.title || 'Công việc');

        const permissionText = permission === 'editor'
            ? 'Chỉnh sửa công việc'
            : 'Chỉ xem công việc';

        const html = `
            <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                <h2>Thông báo chia sẻ công việc</h2>
                <p>Xin chào <strong>${recipientName}</strong>,</p>
                <p><strong>${senderName}</strong> vừa chia sẻ công việc với bạn:</p>
                <h3>${taskTitle}</h3>
                <p>
                    <strong>Quyền được cấp:</strong>
                    ${permissionText}
                </p>
                <p>Vui lòng đăng nhập Task Manager để xem công việc được chia sẻ.</p>
                <hr />
                <p style="color: #777;">Email tự động từ ứng dụng quản lý công việc nhóm.</p>
            </div>
        `;

        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || process.env.SMTP_USER,
            to: recipient.email,
            subject: `Bạn được chia sẻ công việc: ${task?.title || 'Công việc'}`,
            html
        });

        console.log(`D2: Gửi email chia sẻ thành công đến ${recipient.email}`);

        return {
            email: recipient.email,
            messageId: info.messageId
        };
    } catch (error) {
        console.error(`D2: Gửi email thất bại đến ${recipient?.email || 'không xác định'}:`, error.message);
        throw error;
    }
};

// ============================
// D3: EMAIL KHI CẬP NHẬT CÔNG VIỆC
// ============================

const sendTaskUpdateEmail = async ({
    recipient,
    task,
    updater,
    changes
}) => {
    try {
        if (!recipient?.email) {
            throw new Error('Người nhận không có địa chỉ email!');
        }

        if (!Array.isArray(changes) || changes.length === 0) {
            return null;
        }

        const transporter = createTransporter();

        const recipientName = escapeHtml(recipient.fullName || '');
        const updaterName = escapeHtml(updater?.fullName || 'Người dùng');
        const taskTitle = escapeHtml(task?.title || 'Công việc');

        const changesHtml = changes.map(change => `
            <li style="margin-bottom: 12px;">
                <strong>${escapeHtml(change.label || change.field || 'Thông tin')}:</strong>
                <br />
                <span style="color: #777;">
                    Trước: ${escapeHtml(change.oldValue ?? 'Không có')}
                </span>
                <br />
                <span style="color: #16803c;">
                    Sau: ${escapeHtml(change.newValue ?? 'Không có')}
                </span>
            </li>
        `).join('');

        const html = `
            <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                <h2>Thông báo cập nhật công việc</h2>
                <p>Xin chào <strong>${recipientName}</strong>,</p>
                <p><strong>${updaterName}</strong> vừa cập nhật công việc:</p>
                <h3>${taskTitle}</h3>
                <p><strong>Nội dung thay đổi:</strong></p>
                <ul>${changesHtml}</ul>
                <p>Vui lòng đăng nhập Task Manager để xem thông tin mới nhất.</p>
                <hr />
                <p style="color: #777;">Email tự động từ ứng dụng quản lý công việc nhóm.</p>
            </div>
        `;

        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || process.env.SMTP_USER,
            to: recipient.email,
            subject: `Công việc đã được cập nhật: ${task?.title || 'Công việc'}`,
            html
        });

        console.log(`D3: Gửi email cập nhật thành công đến ${recipient.email}`);

        return {
            email: recipient.email,
            messageId: info.messageId
        };
    } catch (error) {
        console.error(`D3: Gửi email cập nhật thất bại đến ${recipient?.email || 'không xác định'}:`, error.message);
        throw error;
    }
};

// ============================
// D4: EMAIL KHI CÔNG VIỆC HOÀN THÀNH
// ============================

const sendTaskCompletedEmail = async ({
    recipient,
    task,
    completer
}) => {
    try {
        if (!recipient?.email) {
            throw new Error('Người nhận không có địa chỉ email!');
        }

        const transporter = createTransporter();

        const recipientName = escapeHtml(recipient.fullName || '');
        const completerName = escapeHtml(completer?.fullName || 'Người dùng');
        const taskTitle = escapeHtml(task?.title || 'Công việc');

        const html = `
            <div style="font-family: Arial, sans-serif; line-height: 1.6;">
                <h2>Thông báo hoàn thành công việc</h2>
                <p>Xin chào <strong>${recipientName}</strong>,</p>
                <p><strong>${completerName}</strong> vừa hoàn thành công việc:</p>
                <h3>${taskTitle}</h3>
                <p>
                    Trạng thái công việc:
                    <strong style="color: #16803c;">Đã hoàn thành</strong>
                </p>
                <p>Vui lòng đăng nhập Task Manager để xem chi tiết.</p>
                <hr />
                <p style="color: #777;">Email tự động từ ứng dụng quản lý công việc nhóm.</p>
            </div>
        `;

        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || process.env.SMTP_USER,
            to: recipient.email,
            subject: `Công việc đã hoàn thành: ${task?.title || 'Công việc'}`,
            html
        });

        console.log(`D4: Gửi email hoàn thành thành công đến ${recipient.email}`);

        return {
            email: recipient.email,
            messageId: info.messageId
        };
    } catch (error) {
        console.error(`D4: Gửi email thất bại đến ${recipient?.email || 'không xác định'}:`, error.message);
        throw error;
    }
};

// ============================
// EXPORT
// ============================

module.exports = {
    sendAssignmentEmail,
    sendShareInvitationEmail,
    sendTaskUpdateEmail,
    sendTaskCompletedEmail
};
