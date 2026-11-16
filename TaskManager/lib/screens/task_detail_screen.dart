import 'package:flutter/material.dart';

import '../services/task_service.dart';
import 'edit_task_screen.dart';
import 'share_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String currentStatus;
  String? selectedStatus;

  bool isUpdating = false;
  bool isLoadingMembers = true;

  Map<String, dynamic> members = {
    'createdBy': null,
    'primaryAssignee': null,
    'assignees': [],
    'shares': [],
  };

  @override
  void initState() {
    super.initState();

    currentStatus = widget.task['status']?.toString() ?? 'todo';
    selectedStatus = currentStatus;

    loadMembers();
  }

  // C5: Tải danh sách thành viên công việc
  Future<void> loadMembers() async {
    final taskId = widget.task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoadingMembers = false;
        });
      }
      return;
    }

    try {
      final result = await TaskService().getTaskMembers(taskId);

      if (!mounted) return;

      setState(() {
        members = result;
        isLoadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingMembers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách thành viên: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // E4: Mở màn hình lịch sử hoạt động
  Future<void> openTaskActivities() async {
    final taskId = widget.task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã công việc!')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskActivityScreen(
          taskId: taskId,
          taskTitle: widget.task['title']?.toString() ?? 'Công việc',
        ),
      ),
    );
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

  String getUserName(dynamic user) {
    if (user == null) return 'Chưa xác định';

    if (user is Map) {
      return user['fullName']?.toString() ?? 'Chưa xác định';
    }

    return user.toString();
  }

  String getUserEmail(dynamic user) {
    if (user is Map) {
      return user['email']?.toString() ?? '';
    }

    return '';
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
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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

  // C5: Hiển thị thông tin một thành viên
  Widget memberTile({
    required dynamic user,
    required IconData icon,
    String? subtitle,
    Color color = Colors.deepPurple,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(25),
        child: Icon(icon, color: color),
      ),
      title: Text(
        getUserName(user),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
    );
  }

  // C5: Hiển thị danh sách người được giao
  Widget assigneeSection() {
    final assignees = members['assignees'] as List? ?? [];
    final primaryAssignee = members['primaryAssignee'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_ind, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(
                  'NGƯỜI ĐƯỢC GIAO',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Người phụ trách chính',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            if (primaryAssignee != null)
              memberTile(
                user: primaryAssignee,
                icon: Icons.star,
                color: Colors.orange,
                subtitle: getUserEmail(primaryAssignee),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Chưa có người phụ trách chính'),
              ),
            const Divider(),
            const Text(
              'Danh sách người được giao',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            if (assignees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Chưa có người được giao'),
              )
            else
              ...assignees.map((user) {
                return memberTile(
                  user: user,
                  icon: Icons.person_outline,
                  subtitle: getUserEmail(user),
                );
              }),
          ],
        ),
      ),
    );
  }

  // C5: Hiển thị danh sách người được chia sẻ
  Widget shareSection() {
    final shares = members['shares'] as List? ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_alt_outlined, color: Colors.teal),
                SizedBox(width: 10),
                Text(
                  'NGƯỜI ĐƯỢC CHIA SẺ',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shares.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Chưa chia sẻ công việc với ai'),
              )
            else
              ...shares.map((share) {
                final user = share is Map ? share['userId'] : null;

                final permission = share is Map
                    ? share['permission']?.toString() ?? 'viewer'
                    : 'viewer';

                final permissionText = permission == 'editor'
                    ? 'Editor - Được xem và chỉnh sửa'
                    : 'Viewer - Chỉ được xem';

                return memberTile(
                  user: user,
                  icon: permission == 'editor' ? Icons.edit : Icons.visibility,
                  color: permission == 'editor' ? Colors.blue : Colors.teal,
                  subtitle: '${getUserEmail(user)}\n$permissionText',
                );
              }),
          ],
        ),
      ),
    );
  }

  // B6: Cập nhật trạng thái công việc
  Future<void> updateStatus() async {
    if (selectedStatus == null || selectedStatus == currentStatus) {
      return;
    }

    final taskId = widget.task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã công việc!')),
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
        currentStatus = updatedTask['status']?.toString() ?? selectedStatus!;
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
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('Không tìm thấy mã công việc!')),
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
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // C3: Mở màn hình chia sẻ công việc
  Future<void> openShareTask() async {
    final taskId = widget.task['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã công việc!')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShareTaskScreen(taskId: taskId)),
    );

    if (mounted) {
      setState(() {
        isLoadingMembers = true;
      });

      await loadMembers();
    }
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
                Icon(Icons.flag_outlined, color: Colors.deepPurple),
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
                DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
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
                onPressed: isUpdating || selectedStatus == currentStatus
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
                label: Text(isUpdating ? 'Đang cập nhật...' : 'Lưu trạng thái'),
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
            // Thông tin công việc
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
                      widget.task['title']?.toString() ?? 'Không có tiêu đề',
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

            const SizedBox(height: 12),

            // E4: Lịch sử hoạt động
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: openTaskActivities,
                icon: const Icon(Icons.history),
                label: const Text('Lịch sử hoạt động'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thông tin chi tiết
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
                      priorityText(widget.task['priority']?.toString()),
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
                      getUserName(
                        members['createdBy'] ?? widget.task['createdBy'],
                      ),
                      Icons.person,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (isLoadingMembers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              assigneeSection(),
              const SizedBox(height: 12),
              shareSection(),
            ],

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

// ======================================================
// E4: MÀN HÌNH LỊCH SỬ HOẠT ĐỘNG CÔNG VIỆC
// ======================================================

class TaskActivityScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskActivityScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> activities = [];

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await TaskService().getTaskActivities(widget.taskId);

      if (!mounted) return;

      setState(() {
        activities = result;
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

  String userName(dynamic user) {
    if (user is Map) {
      return user['fullName']?.toString() ?? 'Người dùng';
    }

    return 'Người dùng';
  }

  String formatActivityDate(dynamic value) {
    if (value == null) return 'Không rõ thời gian';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final localDate = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)} '
        '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year}';
  }

  IconData activityIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle;
      case 'updated':
        return Icons.edit;
      case 'status_changed':
        return Icons.flag;
      case 'assigned':
        return Icons.assignment_ind;
      case 'shared':
        return Icons.share;
      case 'permission_updated':
        return Icons.security;
      case 'share_removed':
        return Icons.person_remove;
      default:
        return Icons.history;
    }
  }

  Color activityColor(String action) {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'status_changed':
        return Colors.orange;
      case 'assigned':
        return Colors.deepPurple;
      case 'shared':
        return Colors.teal;
      case 'permission_updated':
        return Colors.indigo;
      case 'share_removed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget activityTile(dynamic item, int index) {
    final activity = item is Map
        ? Map<String, dynamic>.from(item)
        : <String, dynamic>{};

    final action = activity['action']?.toString() ?? '';
    final description =
        activity['description']?.toString() ?? 'Có hoạt động mới';

    final user = activity['userId'];

    final createdAt = activity['createdAt'];

    final color = activityColor(action);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: color.withAlpha(25),
                child: Icon(activityIcon(action), color: color, size: 20),
              ),
              if (index != activities.length - 1)
                Container(width: 2, height: 65, color: Colors.grey.shade300),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        userName(user),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      formatActivityDate(createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: loadActivities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: Colors.deepPurple.withAlpha(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÔNG VIỆC',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.taskTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${activities.length} hoạt động được ghi nhận',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(child: _buildActivityBody()),
        ],
      ),
    );
  }

  Widget _buildActivityBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 45),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải lịch sử hoạt động',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadActivities,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadActivities,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.history, size: 65, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Chưa có lịch sử hoạt động',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return activityTile(activities[index], index);
        },
      ),
    );
  }
}
