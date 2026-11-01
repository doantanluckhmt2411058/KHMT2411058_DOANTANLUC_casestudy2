
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Vui lòng nhập tên công việc'],
            trim: true
        },

        description: {
            type: String,
            default: '',
            trim: true
        },

        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },

        assigneeIds: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }],

        primaryAssigneeId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            default: null
        },

        startDate: {
            type: Date,
            default: null
        },

        dueDate: {
            type: Date,
            default: null
        },

        priority: {
            type: String,
            enum: ['low', 'medium', 'high'],
            default: 'medium'
        },

        status: {
            type: String,
            enum: ['todo', 'in_progress', 'completed'],
            default: 'todo'
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model('Task', taskSchema);
