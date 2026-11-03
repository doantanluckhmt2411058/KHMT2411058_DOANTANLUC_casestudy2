import 'package:flutter/material.dart';

import 'task_detail_screen.dart';
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

  // Mở giao diện chi tiết công việc B2
  Future<void> openTaskDetail(Map<String, dynamic> task) async {
    final id = task['_id']?.toString();

    debugPrint('========== MỞ CHI TIẾT ==========');
    debugPrint('TASK ID: $id');
    debugPrint('TASK DATA: $task');

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID công việc!')),
      );
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return TaskDetailScreen(task: task);
          },
        ),
      );
    } catch (e) {
      debugPrint('LỖI ĐIỀU HƯỚNG: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi mở chi tiết: $e')));
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
          IconButton(onPressed: loadTasks, icon: const Icon(Icons.refresh)),
        ],
      ),

      // Nút kiểm tra mở chi tiết
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: isLoading || tasks.isEmpty
            ? null
            : () {
                final task = Map<String, dynamic>.from(tasks.first);
                openTaskDetail(task);
              },
        icon: const Icon(Icons.open_in_new),
        label: const Text('Thử mở chi tiết'),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
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
          ? const Center(child: Text('Chưa có công việc nào'))
          : RefreshIndicator(
              onRefresh: loadTasks,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = Map<String, dynamic>.from(tasks[index]);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        openTaskDetail(task);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFEDE7F6),
                              child: Icon(
                                Icons.assignment,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title']?.toString() ??
                                        'Không có tiêu đề',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    task['description']?.toString() ??
                                        'Không có mô tả',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Trạng thái: ${statusText(task['status']?.toString())}',
                                  ),
                                  Text(
                                    'Ưu tiên: ${priorityText(task['priority']?.toString())}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (task['dueDate'] != null)
                                    Text(
                                      'Hạn hoàn thành: ${task['dueDate'].toString().length >= 10 ? task['dueDate'].toString().substring(0, 10) : task['dueDate']}',
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
