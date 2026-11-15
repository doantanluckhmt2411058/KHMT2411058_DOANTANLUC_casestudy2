
const EmailLog = require('../models/EmailLog');

const getEmailLogs = async (req, res) => {
    try {
        const logs = await EmailLog.find({
            triggeredBy: req.user._id
        })
            .sort({ sentAt: -1 })
            .limit(100);

        return res.status(200).json({
            message: 'Lấy lịch sử email thành công!',
            total: logs.length,
            logs
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Không thể lấy lịch sử email!',
            error: error.message
        });
    }
};

module.exports = { getEmailLogs };
