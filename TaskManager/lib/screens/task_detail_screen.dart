
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import 'edit_task_screen.dart';
import 'share_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String currentStatus;
  String? selectedStatus;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.task['status']?.toString() ?? 'todo';
    selectedStatus = currentStatus;
  }

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

  // B6: Cập nhật trạng thái công việc
  Future<void> updateStatus() async {
    if (selectedStatus == null || selectedStatus == currentStatus) {
      return;
    }

    final taskId = widget.task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã công việc!'),
        ),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final updatedTask = await TaskService().updateTaskStatus(
        taskId,
        selectedStatus!,
      );

      if (!mounted) return;

      setState(() {
        currentStatus =
            updatedTask['status']?.toString() ?? selectedStatus!;
        selectedStatus = currentStatus;
        widget.task['status'] = currentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trạng thái thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  // Chỉnh sửa công việc
  Future<void> editTask() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: widget.task),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  // Xóa công việc
  Future<void> deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa công việc '
                '"${widget.task['title'] ?? ''}" không?',
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

    if (confirm != true || !mounted) return;

    final taskId = widget.task['_id']?.toString();

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

      if (!mounted) return;

      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // C3: Mở màn hình chia sẻ công việc
  Future<void> openShareTask() async {
    final taskId = widget.task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã công việc!'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareTaskScreen(
          taskId: taskId,
        ),
      ),
    );
  }

  // Giao diện chọn trạng thái
  Widget statusSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: Colors.deepPurple,
                ),
                SizedBox(width: 10),
                Text(
                  'CẬP NHẬT TRẠNG THÁI',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Chọn trạng thái',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'todo',
                  child: Text('Chưa thực hiện'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('Đang thực hiện'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Đã hoàn thành'),
                ),
              ],
              onChanged: isUpdating
                  ? null
                  : (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isUpdating ||
                    selectedStatus == currentStatus
                    ? null
                    : updateStatus,
                icon: isUpdating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  isUpdating ? 'Đang cập nhật...' : 'Lưu trạng thái',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            onPressed: editTask,
          ),
          IconButton(
            tooltip: 'Xóa công việc',
            icon: const Icon(Icons.delete),
            onPressed: deleteTask,
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
                      widget.task['title']?.toString() ??
                          'Không có tiêu đề',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.task['description']?.toString() ??
                          'Không có mô tả',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // B6: Chọn và lưu trạng thái
            statusSection(),

            const SizedBox(height: 16),

            // C3: Chia sẻ công việc
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: openShareTask,
                icon: const Icon(Icons.share),
                label: const Text('Chia sẻ công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
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
                      'Trạng thái hiện tại',
                      statusText(currentStatus),
                      Icons.flag_outlined,
                    ),
                    const Divider(),
                    detailItem(
                      'Mức độ ưu tiên',
                      priorityText(
                        widget.task['priority']?.toString(),
                      ),
                      Icons.priority_high,
                    ),
                    const Divider(),
                    detailItem(
                      'Ngày bắt đầu',
                      formatDate(widget.task['startDate']),
                      Icons.calendar_today,
                    ),
                    const Divider(),
                    detailItem(
                      'Hạn hoàn thành',
                      formatDate(widget.task['dueDate']),
                      Icons.event,
                    ),
                    const Divider(),
                    detailItem(
                      'Người tạo',
                      getUserName(widget.task['createdBy']),
                      Icons.person,
                    ),
                    const Divider(),
                    detailItem(
                      'Người phụ trách chính',
                      getUserName(widget.task['primaryAssigneeId']),
                      Icons.assignment_ind,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: editTask,
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: deleteTask,
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
