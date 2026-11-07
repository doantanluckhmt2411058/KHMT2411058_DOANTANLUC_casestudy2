
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;

  const AssignTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final TaskService service = TaskService();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> assignees = [];
  final Set<String> selectedIds = {};
  String? primaryId;

  bool loading = false;
  bool saving = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    loadAssignees();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchUsers(String value) async {
    setState(() {
      query = value;
      loading = true;
    });

    try {
      final result = await service.searchUsers(value);
      if (!mounted) return;
      setState(() => users = result);
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadAssignees() async {
    try {
      final result = await service.getTaskAssignees(widget.taskId);
      if (!mounted) return;
      setState(() => assignees = result);
    } catch (e) {
      showMessage(e.toString());
    }
  }

  Future<void> submitAssignment() async {
    if (selectedIds.isEmpty) {
      showMessage('Vui lòng chọn ít nhất một thành viên!');
      return;
    }

    setState(() => saving = true);

    try {
      await service.assignTask(
        widget.taskId,
        selectedIds.toList(),
      );

      await loadAssignees();

      if (!mounted) return;
      setState(() {
        selectedIds.clear();
        primaryId = null;
      });

      showMessage('Giao công việc thành công!');
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Giao công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tìm kiếm thành viên',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: searchController,
            onChanged: searchUsers,
            decoration: InputDecoration(
              hintText: 'Nhập tên hoặc email...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (loading)
            const Center(child: CircularProgressIndicator()),

          if (!loading && query.isNotEmpty && users.isEmpty)
            const Text('Không tìm thấy thành viên.'),

          ...users.map((user) {
            final id = user['_id'].toString();
            final selected = selectedIds.contains(id);

            return Card(
              child: CheckboxListTile(
                value: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);
                      if (primaryId == id) primaryId = null;
                    }
                  });
                },
                secondary: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(user['fullName'] ?? ''),
                subtitle: Text(user['email'] ?? ''),
              ),
            );
          }),

          const SizedBox(height: 20),

          const Text(
            'Người phụ trách chính',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: primaryId,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              hintText: 'Chọn người phụ trách chính',
            ),
            items: users
                .where((user) => selectedIds.contains(user['_id'].toString()))
                .map<DropdownMenuItem<String>>((user) {
              return DropdownMenuItem<String>(
                value: user['_id'].toString(),
                child: Text(user['fullName'] ?? ''),
              );
            }).toList(),
            onChanged: (value) => setState(() => primaryId = value),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: saving ? null : submitAssignment,
              icon: const Icon(Icons.assignment_turned_in),
              label: Text(saving ? 'Đang giao việc...' : 'Xác nhận giao việc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Thành viên đã được giao',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          ...assignees.map((user) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(user['fullName'] ?? ''),
              subtitle: Text(user['email'] ?? ''),
            ),
          )),

          if (assignees.isEmpty)
            const Text('Chưa có thành viên nào được giao.'),
        ],
      ),
    );
  }
}
