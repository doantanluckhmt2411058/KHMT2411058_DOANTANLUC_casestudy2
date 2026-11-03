import 'package:flutter/material.dart';

import 'task_detail_screen.dart';

class TaskDetailTestScreen extends StatelessWidget {
  const TaskDetailTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleTask = {
      '_id': 'test001',
      'title': 'Hoàn thành Case Study 2',
      'description': 'Xây dựng chức năng quản lý và giao công việc nhóm.',
      'status': 'in_progress',
      'priority': 'high',
      'startDate': '2026-11-01',
      'dueDate': '2026-11-10',
      'createdBy': {'fullName': 'Đoàn Tấn Lực'},
      'primaryAssigneeId': {'fullName': 'Đoàn Tấn Lực'},
    };

    return TaskDetailScreen(task: sampleTask);
  }
}
