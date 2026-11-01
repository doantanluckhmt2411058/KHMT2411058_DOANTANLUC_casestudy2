
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService taskService = TaskService();

  List<dynamic> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await taskService.getTasks();

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
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Chưa thực hiện';
    }
  }

  String priorityText(String? priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'low':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  Color priorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Danh sách công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 150),
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Center(child: Text(errorMessage!)),
          Center(
            child: TextButton(
              onPressed: loadTasks,
              child: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (tasks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 150),
          Icon(Icons.task_alt, size: 70, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Chưa có công việc nào',
              style: TextStyle(fontSize: 17, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        final priority = task['priority']?.toString();
        final status = task['status']?.toString();
        final dueDate = task['dueDate']?.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEDE7F6),
              child: Icon(
                Icons.assignment,
                color: Colors.deepPurple,
              ),
            ),
            title: Text(
              task['title'] ?? 'Không có tiêu đề',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['description'] ?? 'Không có mô tả'),
                  const SizedBox(height: 8),
                  Text('Trạng thái: ${statusText(status)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Ưu tiên: ${priorityText(priority)}',
                    style: TextStyle(
                      color: priorityColor(priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hạn hoàn thành: ${dueDate == null ? 'Chưa đặt' : dueDate.substring(0, 10)}',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
