
import 'package:flutter/material.dart';

import 'task_detail_screen.dart';
import 'add_task_screen.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();

  List<dynamic> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // Tải danh sách công việc
  Future<void> loadTasks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _taskService.getTasks();

      if (!mounted) return;

      setState(() {
        tasks = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Mở màn hình thêm công việc
  Future<void> openAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );

    if (mounted) {
      await loadTasks();
    }
  }

  // Chuyển trạng thái sang tiếng Việt
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

  // Chuyển mức độ ưu tiên sang tiếng Việt
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

  // Mở chi tiết và cập nhật danh sách sau khi sửa hoặc xóa
  Future<void> openTaskDetail(
      Map<String, dynamic> task,
      ) async {
    final id = task['_id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID công việc!'),
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );

    if (result != null && mounted) {
      await loadTasks();

      if (!mounted) return;

      if (result['deleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa công việc thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danh sách công việc đã được cập nhật!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),

      // Nút thêm công việc
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddTask,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 45,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadTasks,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      )
          : tasks.isEmpty
          ? const Center(
        child: Text('Chưa có công việc nào'),
      )
          : RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task =
            Map<String, dynamic>.from(tasks[index]);

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(
                    Icons.assignment,
                    color: Colors.deepPurple,
                  ),
                ),
                title: Text(
                  task['title']?.toString() ??
                      'Không có tiêu đề',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      task['description']?.toString() ??
                          'Không có mô tả',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Trạng thái: ${statusText(task['status']?.toString())}',
                    ),
                    Text(
                      'Ưu tiên: ${priorityText(task['priority']?.toString())}',
                    ),
                    if (task['dueDate'] != null)
                      Text(
                        'Hạn hoàn thành: ${task['dueDate'].toString().substring(0, 10)}',
                      ),
                    const SizedBox(height: 5),
                    const Text(
                      'Nhấn để xem, chỉnh sửa hoặc xóa',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.deepPurple,
                ),
                onTap: () => openTaskDetail(task),
              ),
            );
          },
        ),
      ),
    );
  }
}
