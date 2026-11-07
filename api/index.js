
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const connectDatabase = require('./src/config/database');

const app = express();

app.use(cors());
app.use(express.json());

// Kết nối MongoDB
connectDatabase();

// API đăng ký, đăng nhập
const authRoutes = require('./src/routes/authRoutes');
app.use('/api/auth', authRoutes);
const userRoutes = require('./src/routes/userRoutes');
app.use('/api/users', userRoutes);
// API quản lý công việc B1-B7
const taskRoutes = require('./src/routes/taskRoutes');
app.use('/api/tasks', taskRoutes);

// C1: API giao công việc
const assignmentRoutes = require('./src/routes/assignmentRoutes');
app.use('/api/tasks', assignmentRoutes);

// Kiểm tra server
app.get('/', (req, res) => {
    res.send('Task Manager API đang hoạt động!');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server đang chạy tại http://localhost:${PORT}`);
});
