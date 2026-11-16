import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final List<dynamic> tasks;

  const StatisticsScreen({super.key, required this.tasks});

  int countByStatus(String status) {
    return tasks.where((task) {
      if (task is! Map) return false;
      return task['status']?.toString() == status;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final todo = countByStatus('todo');
    final inProgress = countByStatus('in_progress');
    final completed = countByStatus('completed');
    final total = tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan công việc',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 45,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Text(
                      'Tổng số công việc',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Số lượng theo trạng thái',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildStatusCard(
              title: 'Chưa thực hiện',
              count: todo,
              total: total,
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
            _buildStatusCard(
              title: 'Đang thực hiện',
              count: inProgress,
              total: total,
              color: Colors.blue,
              icon: Icons.autorenew,
            ),
            _buildStatusCard(
              title: 'Đã hoàn thành',
              count: completed,
              total: total,
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final percent = total == 0 ? 0.0 : count / total;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
