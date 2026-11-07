
const User = require('../models/User');

// C1: Tìm người dùng theo tên hoặc email
const searchUsers = async (req, res) => {
    try {
        const q = (req.query.q || '').trim();

        if (!q) {
            return res.status(200).json({
                message: 'Vui lòng nhập tên hoặc email cần tìm!',
                users: []
            });
        }

        const users = await User.find({
            $or: [
                { fullName: { $regex: q, $options: 'i' } },
                { email: { $regex: q, $options: 'i' } }
            ],
            _id: { $ne: req.user._id }
        })
            .select('fullName email avatarUrl')
            .limit(20);

        return res.status(200).json({
            message: 'Tìm người dùng thành công!',
            users
        });
    } catch (error) {
        console.error('Lỗi tìm người dùng:', error);
        return res.status(500).json({
            message: 'Không thể tìm người dùng!',
            error: error.message
        });
    }
};

module.exports = { searchUsers };
