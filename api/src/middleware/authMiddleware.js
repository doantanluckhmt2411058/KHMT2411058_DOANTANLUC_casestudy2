
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                message: 'Bạn chưa đăng nhập!'
            });
        }

        const token = authHeader.split(' ')[1];

        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        const user = await User.findById(decoded.userId)
            .select('fullName email avatarUrl createdAt updatedAt passwordHash');

        if (!user) {
            return res.status(401).json({
                message: 'Tài khoản không tồn tại!'
            });
        }

        req.user = user;
        next();

    } catch (error) {
        return res.status(401).json({
            message: 'Token không hợp lệ hoặc đã hết hạn!'
        });
    }
};

module.exports = authMiddleware;
