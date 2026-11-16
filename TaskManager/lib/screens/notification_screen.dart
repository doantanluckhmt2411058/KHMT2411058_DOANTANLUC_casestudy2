import 'package:flutter/material.dart';

import 'task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final List<dynamic> tasks;

  const NotificationScreen({super.key, required this.tasks});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<Map<String, dynamic>> notifications;

  @override
  void initState() {
    super.initState();
    notifications = _createNotifications();
  }

  // Tạo thông báo mẫu từ danh sách công việc hiện có
  List<Map<String, dynamic>> _createNotifications() {
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < widget.tasks.length; i++) {
      final task = Map<String, dynamic>.from(widget.tasks[i]);
      final title = task['title']?.toString() ?? 'Công việc';

      result.add({
        'id': 'notification_$i',
        'taskId': task['_id']?.toString() ?? '',
        'title': 'Thông báo công việc',
        'message': 'Công việc "$title" đang được theo dõi.',
        'type': 'task',
        'isRead': i > 0,
        'createdAt': DateTime.now().subtract(Duration(hours: i)).toString(),
      });
    }

    // Nếu chưa có công việc, vẫn hiển thị thông báo mẫu
    if (result.isEmpty) {
      result.add({
        'id': 'notification_demo',
        'taskId': '',
        'title': 'Chào mừng bạn!',
        'message': 'Thông báo trong ứng dụng sẽ hiển thị tại đây.',
        'type': 'info',
        'isRead': false,
        'createdAt': DateTime.now().toString(),
      });
    }

    return result;
  }

  // Số thông báo chưa đọc
  int get unreadCount {
    return notifications.where((item) => item['isRead'] == false).length;
  }

  // Đánh dấu một thông báo đã đọc
  void markAsRead(int index) {
    setState(() {
      notifications[index]['isRead'] = true;
    });
  }

  // Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    setState(() {
      for (final item in notifications) {
        item['isRead'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Mở công việc liên quan
  void openRelatedTask(Map<String, dynamic> notification) {
    final taskId = notification['taskId']?.toString() ?? '';

    final task = widget.tasks.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['_id']?.toString() == taskId,
      orElse: () => null,
    );

    if (task == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy công việc liên quan')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  // Icon theo loại thông báo
  IconData getNotificationIcon(String? type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_ind;
      case 'share':
        return Icons.people;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  // Màu thông báo
  Color getNotificationColor(String? type) {
    switch (type) {
      case 'assignment':
        return Colors.blue;
      case 'share':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }

  // Hiển thị thời gian
  String formatTime(String? value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value);
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // Card thông báo
  Widget notificationCard(int index) {
    final item = notifications[index];
    final isRead = item['isRead'] == true;
    final color = getNotificationColor(item['type']?.toString());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.white : Colors.deepPurple.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            getNotificationIcon(item['type']?.toString()),
            color: color,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['title']?.toString() ?? 'Thông báo',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(item['message']?.toString() ?? ''),
            const SizedBox(height: 8),
            Text(
              formatTime(item['createdAt']?.toString()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!isRead)
                  TextButton.icon(
                    onPressed: () => markAsRead(index),
                    icon: const Icon(Icons.done, size: 16),
                    label: const Text('Đánh dấu đã đọc'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    markAsRead(index);
                    openRelatedTask(item);
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Mở công việc'),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          markAsRead(index);
          openRelatedTask(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 10),
                Text(
                  '$unreadCount thông báo chưa đọc',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('Không có thông báo'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return notificationCard(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
