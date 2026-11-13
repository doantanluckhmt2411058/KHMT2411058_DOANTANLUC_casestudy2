
require('dotenv').config();
const nodemailer = require('nodemailer');

async function testEmail() {
  try {
    console.log('========== KIỂM TRA SMTP ==========');

    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS?.replace(/\s/g, ''),
      },
    });

    console.log('Đang kiểm tra kết nối Gmail...');

    await transporter.verify();

    console.log('THÀNH CÔNG: Đã kết nối và xác thực SMTP!');

    // Thay bằng email của bạn hoặc email nhận thử
    const recipient = 'EMAIL_NHAN_THU@gmail.com';

    console.log('Đang gửi email thử...');

    const info = await transporter.sendMail({
      from: process.env.SMTP_FROM,
      to: recipient,
      subject: 'Kiểm tra chức năng gửi email - Task Manager',
      text: `
Xin chào!

Đây là email kiểm tra chức năng gửi Gmail
của ứng dụng Task Manager.

Nếu bạn nhận được email này,
chức năng SMTP đang hoạt động.

Trân trọng,
Task Manager
      `,
    });

    console.log('========== KẾT QUẢ ==========');
    console.log('GỬI EMAIL THÀNH CÔNG!');
    console.log('Message ID:', info.messageId);
    console.log('Người nhận:', recipient);
    console.log('Accepted:', info.accepted);
    console.log('Rejected:', info.rejected);

  } catch (error) {
    console.log('========== GỬI EMAIL THẤT BẠI ==========');
    console.error('Lỗi:', error.message);
  }
}

testEmail();
