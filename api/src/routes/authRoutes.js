
const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// API đăng ký
router.post('/register', authController.register);

// API đăng nhập
router.post('/login', authController.login);

// API xem thông tin cá nhân
router.get('/me', authMiddleware, authController.getMe);
// API cập nhật thông tin cá nhân
router.put('/me', authMiddleware, authController.updateMe);
// API đổi mật khẩu
router.put('/change-password', authMiddleware, authController.changePassword);
module.exports = router;
