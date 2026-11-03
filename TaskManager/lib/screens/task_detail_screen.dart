
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  String statusText(String? status) {
    switch (status) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return 'Chưa xác định';
    }
  }

  String priorityText(String? priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return 'Chưa xác định';
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return 'Chưa thiết lập';

    final value = date.toString();
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  Widget detailItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getUserName(dynamic user) {
    if (user == null) return 'Chưa xác định';

    if (user is Map) {
      return user['fullName']?.toString() ?? 'Chưa xác định';
    }

    return user.toString();
  }

  // Chỉnh sửa công việc
  Future<void> editTask(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: task),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.pop(context, result);
    }
  }

  // Xóa công việc
  Future<void> deleteTask(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa công việc '
                '"${task['title'] ?? ''}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    final taskId = task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã công việc!'),
        ),
      );
      return;
    }

    try {
      await TaskService().deleteTask(taskId);

      if (!context.mounted) return;

      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa công việc',
            icon: const Icon(Icons.edit),
            onPressed: () => editTask(context),
          ),
          IconButton(
            tooltip: 'Xóa công việc',
            icon: const Icon(Icons.delete),
            onPressed: () => deleteTask(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THÔNG TIN CÔNG VIỆC',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      task['title']?.toString() ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task['description']?.toString() ?? 'Không có mô tả',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    detailItem(
                      'Trạng thái',
                      statusText(task['status']?.toString()),
                      Icons.flag_outlined,
                    ),
                    const Divider(),
                    detailItem(
                      'Mức độ ưu tiên',
                      priorityText(task['priority']?.toString()),
                      Icons.priority_high,
                    ),
                    const Divider(),
                    detailItem(
                      'Ngày bắt đầu',
                      formatDate(task['startDate']),
                      Icons.calendar_today,
                    ),
                    const Divider(),
                    detailItem(
                      'Hạn hoàn thành',
                      formatDate(task['dueDate']),
                      Icons.event,
                    ),
                    const Divider(),
                    detailItem(
                      'Người tạo',
                      getUserName(task['createdBy']),
                      Icons.person,
                    ),
                    const Divider(),
                    detailItem(
                      'Người phụ trách chính',
                      getUserName(task['primaryAssigneeId']),
                      Icons.assignment_ind,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nút chỉnh sửa
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => editTask(context),
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nút xóa
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => deleteTask(context),
                icon: const Icon(Icons.delete),
                label: const Text('Xóa công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
