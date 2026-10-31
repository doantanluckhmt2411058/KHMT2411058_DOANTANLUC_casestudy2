
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const connectDatabase = require('./src/config/database');

const app = express();

app.use(cors());
app.use(express.json());

// Kết nối MongoDB
connectDatabase();

// Kết nối API đăng ký
const authRoutes = require('./src/routes/authRoutes');
app.use('/api/auth', authRoutes);

// Kiểm tra server
app.get('/', (req, res) => {
    res.send('Task Manager API đang hoạt động!');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server đang chạy tại http://localhost:${PORT}`);
});
