
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// CHỨC NĂNG ĐĂNG KÝ
exports.register = async (req, res) => {
    try {
        const { fullName, email, password } = req.body;

        if (!fullName || !email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ thông tin!'
            });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailRegex.test(email)) {
            return res.status(400).json({
                message: 'Email không hợp lệ!'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                message: 'Mật khẩu phải có ít nhất 6 ký tự!'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(409).json({
                message: 'Email đã được đăng ký!'
            });
        }

        const passwordHash = await bcrypt.hash(password, 12);

        const newUser = new User({
            fullName: fullName.trim(),
            email: normalizedEmail,
            passwordHash
        });

        await newUser.save();

        return res.status(201).json({
            message: 'Đăng ký tài khoản thành công!',
            user: {
                id: newUser._id,
                fullName: newUser.fullName,
                email: newUser.email
            }
        });

    } catch (error) {
        console.error('Lỗi đăng ký:', error);
        return res.status(500).json({
            message: 'Lỗi máy chủ khi đăng ký tài khoản!'
        });
    }
};

// CHỨC NĂNG ĐĂNG NHẬP
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                message: 'Vui lòng nhập email và mật khẩu!'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(401).json({
                message: 'Email hoặc mật khẩu không chính xác!'
            });
        }

        const isMatch = await bcrypt.compare(
            password,
            user.passwordHash
        );

        if (!isMatch) {
            return res.status(401).json({
                message: 'Email hoặc mật khẩu không chính xác!'
            });
        }

        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        return res.status(200).json({
            message: 'Đăng nhập thành công!',
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email,
                avatarUrl: user.avatarUrl
            }
        });

    } catch (error) {
        console.error('Lỗi đăng nhập:', error);
        return res.status(500).json({
            message: 'Lỗi máy chủ khi đăng nhập!'
        });
    }
};

// CHỨC NĂNG XEM THÔNG TIN CÁ NHÂN
exports.getMe = async (req, res) => {
    try {
        return res.status(200).json({
            message: 'Lấy thông tin cá nhân thành công!',
            user: {
                id: req.user._id,
                fullName: req.user.fullName,
                email: req.user.email,
                avatarUrl: req.user.avatarUrl,
                createdAt: req.user.createdAt
            }
        });

    } catch (error) {
        console.error('Lỗi lấy thông tin cá nhân:', error);

        return res.status(500).json({
            message: 'Lỗi máy chủ!'
        });
    }
};
// CHỨC NĂNG CẬP NHẬT THÔNG TIN CÁ NHÂN
exports.updateMe = async (req, res) => {
    try {
        const { fullName, avatarUrl } = req.body;

        if (!fullName || !fullName.trim()) {
            return res.status(400).json({
                message: 'Họ tên không được để trống!'
            });
        }

        req.user.fullName = fullName.trim();

        if (avatarUrl !== undefined) {
            req.user.avatarUrl = avatarUrl;
        }

        await req.user.save();

        return res.status(200).json({
            message: 'Cập nhật thông tin cá nhân thành công!',
            user: {
                id: req.user._id,
                fullName: req.user.fullName,
                email: req.user.email,
                avatarUrl: req.user.avatarUrl
            }
        });

    } catch (error) {
        console.error('Lỗi cập nhật thông tin:', error);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi cập nhật thông tin!'
        });
    }
};
// CHỨC NĂNG ĐỔI MẬT KHẨU
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                message: 'Vui lòng nhập đầy đủ mật khẩu!'
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                message: 'Mật khẩu mới phải có ít nhất 6 ký tự!'
            });
        }

        const isMatch = await bcrypt.compare(
            currentPassword,
            req.user.passwordHash
        );

        if (!isMatch) {
            return res.status(400).json({
                message: 'Mật khẩu hiện tại không chính xác!'
            });
        }

        req.user.passwordHash = await bcrypt.hash(newPassword, 12);

        await req.user.save();

        return res.status(200).json({
            message: 'Đổi mật khẩu thành công!'
        });

    } catch (error) {
        console.error('Lỗi đổi mật khẩu:', error);

        return res.status(500).json({
            message: 'Lỗi máy chủ khi đổi mật khẩu!'
        });
    }
};