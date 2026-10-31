
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    fullName: {
        type: String,
        required: true,
        trim: true
    },

    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },

    passwordHash: {
        type: String,
        required: true
    },

    avatarUrl: {
        type: String,
        default: ''
    }

}, {
    timestamps: true,
    collection: 'users'
});

// Không trả mật khẩu đã mã hóa về client
userSchema.set('toJSON', {
    transform: (_doc, ret) => {
        delete ret.passwordHash;
        delete ret.__v;
        return ret;
    }
});

module.exports = mongoose.model('User', userSchema);
