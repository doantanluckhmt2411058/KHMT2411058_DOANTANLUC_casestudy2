
const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema(
    {
        type: {
            type: String,
            enum: ['assignment', 'share', 'update', 'completed'],
            required: true
        },

        recipientEmail: {
            type: String,
            required: true,
            trim: true,
            lowercase: true
        },

        recipientName: {
            type: String,
            default: ''
        },

        taskId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Task',
            default: null
        },

        taskTitle: {
            type: String,
            default: ''
        },

        subject: {
            type: String,
            default: ''
        },

        status: {
            type: String,
            enum: ['success', 'failed'],
            required: true
        },

        messageId: {
            type: String,
            default: null
        },

        error: {
            type: String,
            default: null
        },

        sentAt: {
            type: Date,
            default: Date.now
        }
    },
    {
        timestamps: true,
        collection: 'emaillogs'
    }
);

emailLogSchema.index({ sentAt: -1 });
emailLogSchema.index({ recipientEmail: 1 });

module.exports = mongoose.model('EmailLog', emailLogSchema);
