
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class EmailHistoryScreen extends StatefulWidget {
  const EmailHistoryScreen({super.key});

  @override
  State<EmailHistoryScreen> createState() => _EmailHistoryScreenState();
}

class _EmailHistoryScreenState extends State<EmailHistoryScreen> {
  final TaskService _taskService = TaskService();

  List<dynamic> logs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _taskService.getEmailLogs();

      if (!mounted) return;

      setState(() {
        logs = result;
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

  String typeText(dynamic type) {
    switch (type?.toString()) {
      case 'assignment':
        return 'Giao công việc';
      case 'share':
        return 'Chia sẻ công việc';
      case 'update':
        return 'Cập nhật công việc';
      case 'completed':
        return 'Hoàn thành công việc';
      default:
        return 'Email khác';
    }
  }

  IconData typeIcon(dynamic type) {
    switch (type?.toString()) {
      case 'assignment':
        return Icons.assignment_ind;
      case 'share':
        return Icons.share;
      case 'update':
        return Icons.edit_note;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.email;
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return 'Không xác định';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return 'Không xác định';

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  Widget emailCard(Map<String, dynamic> log) {
    final success = log['status'] == 'success';

    final recipientName =
        log['recipientName']?.toString() ?? '';

    final recipientEmail =
        log['recipientEmail']?.toString() ?? 'Không rõ';

    final taskTitle =
        log['taskTitle']?.toString() ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Icon(
                    typeIcon(log['type']),
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    typeText(log['type']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    success ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: success ? Colors.green : Colors.red,
                  ),
                  label: Text(
                    success ? 'Thành công' : 'Thất bại',
                    style: TextStyle(
                      color: success ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor:
                  success ? Colors.green.shade50 : Colors.red.shade50,
                  side: BorderSide.none,
                ),
              ],
            ),
            const Divider(height: 22),
            Text(
              'Người nhận: ${recipientName.isEmpty ? recipientEmail : recipientName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text('Email: $recipientEmail'),
            if (taskTitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Công việc: $taskTitle'),
            ],
            if ((log['subject'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Tiêu đề: ${log['subject']}'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  formatDate(log['sentAt']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            if (!success && log['error'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lỗi: ${log['error']}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử gửi email'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadLogs,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      )
          : logs.isEmpty
          ? RefreshIndicator(
        onRefresh: loadLogs,
        child: ListView(
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.email_outlined,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Chưa có lịch sử gửi email'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadLogs,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Tổng số email: ${logs.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...logs.map((item) {
              return emailCard(
                Map<String, dynamic>.from(item),
              );
            }),
          ],
        ),
      ),
    );
  }
}
