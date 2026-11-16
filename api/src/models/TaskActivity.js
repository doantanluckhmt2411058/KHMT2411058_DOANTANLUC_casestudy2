
const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema({
    taskId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Task',
        required: true,
        index: true
    },

    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },

    action: {
        type: String,
        required: true,
        enum: [
            'created',
            'updated',
            'status_changed',
            'assigned',
            'shared',
            'permission_updated',
            'share_removed'
        ]
    },

    description: {
        type: String,
        required: true,
        trim: true
    },

    details: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    }
}, {
    timestamps: true,
    collection: 'taskactivities'
});

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
