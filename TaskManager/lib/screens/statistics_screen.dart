import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsScreen extends StatefulWidget {
  final List<dynamic> tasks;

  const StatisticsScreen({super.key, required this.tasks});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? currentUserId;
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  // Lấy ID người dùng từ JWT
  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          isLoadingUser = false;
        });
        return;
      }

      final parts = token.split('.');

      if (parts.length != 3) {
        setState(() {
          isLoadingUser = false;
        });
        return;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      setState(() {
        currentUserId = (payload['userId'] ?? payload['_id'] ?? payload['id'])
            ?.toString();

        isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  // Lấy ID dù dữ liệu đã populate hay chưa
  String? _getId(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? value['userId'])?.toString();
    }

    return value.toString();
  }

  // Đếm công việc theo trạng thái
  int countByStatus(String status) {
    return widget.tasks.where((task) {
      if (task is! Map) return false;
      return task['status']?.toString() == status;
    }).length;
  }

  // E2: Công việc do mình tạo và đã giao cho người khác
  int get assignedTaskCount {
    return widget.tasks.where((task) {
      if (task is! Map) return false;

      final roles = task['myRoles'];
      final assignees = task['assigneeIds'];

      final isCreator = roles is List && roles.contains('creator');

      final hasAssignees = assignees is List && assignees.isNotEmpty;

      return isCreator && hasAssignees;
    }).length;
  }

  // E2: Công việc mình đang là người phụ trách chính
  int get responsibleTaskCount {
    if (currentUserId == null) return 0;

    return widget.tasks.where((task) {
      if (task is! Map) return false;

      final primaryId = _getId(task['primaryAssigneeId']);

      return primaryId == currentUserId;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final todo = countByStatus('todo');
    final inProgress = countByStatus('in_progress');
    final completed = countByStatus('completed');
    final total = widget.tasks.length;

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

            // Tổng số công việc
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

            // E1
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

            const SizedBox(height: 24),

            // E2
            const Text(
              'Thống kê công việc được giao và phụ trách',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildStatusCard(
              title: 'Công việc được giao',
              count: assignedTaskCount,
              total: total,
              color: Colors.deepPurple,
              icon: Icons.assignment_outlined,
            ),

            if (isLoadingUser)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildStatusCard(
                title: 'Công việc đang phụ trách',
                count: responsibleTaskCount,
                total: total,
                color: Colors.teal,
                icon: Icons.person_pin_circle_outlined,
              ),

            if (!isLoadingUser && currentUserId == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Không lấy được thông tin tài khoản. '
                  'Vui lòng đăng nhập lại để xem thống kê công việc phụ trách.',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
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
              value: percent.clamp(0.0, 1.0),
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
