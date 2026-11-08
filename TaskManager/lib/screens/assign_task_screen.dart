
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
  bool loadingAssignees = true;

  String query = '';

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Lấy ID dù dữ liệu đã populate hay chưa
  String? getUserId(dynamic user) {
    if (user == null) return null;

    if (user is Map) {
      return user['_id']?.toString();
    }

    return user.toString();
  }

  // Tải danh sách người được giao và người phụ trách chính
  Future<void> loadInitialData() async {
    try {
      final result = await service.getTaskAssignees(widget.taskId);

      if (!mounted) return;

      // API trả về Map chứa danh sách assignees
      final List<dynamic> loadedAssignees =
      List<dynamic>.from(result['assignees'] ?? []);

      // Lấy người phụ trách chính từ API
      final primary = getUserId(result['primaryAssignee']);

      setState(() {
        assignees = loadedAssignees;

        selectedIds.clear();

        for (final user in loadedAssignees) {
          final id = getUserId(user);

          if (id != null) {
            selectedIds.add(id);
          }
        }

        primaryId = primary;
      });
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => loadingAssignees = false);
      }
    }
  }

  // Tìm kiếm người dùng
  Future<void> searchUsers(String value) async {
    setState(() {
      query = value.trim();
    });

    if (query.isEmpty) {
      setState(() {
        users = [];
        loading = false;
      });
      return;
    }

    setState(() => loading = true);

    try {
      final result = await service.searchUsers(query);

      if (!mounted) return;

      setState(() {
        users = result;
      });
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // Danh sách thành viên đã chọn
  List<dynamic> get selectedUsers {
    final Map<String, dynamic> mergedUsers = {};

    for (final user in assignees) {
      final id = getUserId(user);

      if (id != null) {
        mergedUsers[id] = user;
      }
    }

    for (final user in users) {
      final id = getUserId(user);

      if (id != null) {
        mergedUsers[id] = user;
      }
    }

    return mergedUsers.values
        .where((user) => selectedIds.contains(getUserId(user)))
        .toList();
  }

  // Giao công việc
  Future<void> submitAssignment() async {
    if (selectedIds.isEmpty) {
      showMessage('Vui lòng chọn ít nhất một thành viên!');
      return;
    }

    if (primaryId == null || !selectedIds.contains(primaryId)) {
      showMessage('Vui lòng chọn người phụ trách chính!');
      return;
    }

    setState(() => saving = true);

    try {
      await service.assignTask(
        widget.taskId,
        selectedIds.toList(),
        primaryId!,
      );

      await loadInitialData();

      if (!mounted) return;

      showMessage('Giao công việc thành công!');
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  // Hiển thị thông báo
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Giao công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: loadingAssignees
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tìm kiếm thành viên
          const Text(
            'Tìm kiếm thành viên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
            const Center(
              child: CircularProgressIndicator(),
            ),

          if (!loading && query.isNotEmpty && users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Không tìm thấy thành viên.'),
            ),

          // Kết quả tìm kiếm
          ...users.map((user) {
            final id = getUserId(user);

            if (id == null) {
              return const SizedBox.shrink();
            }

            final isSelected = selectedIds.contains(id);

            return Card(
              color: Colors.white,
              child: CheckboxListTile(
                value: isSelected,
                onChanged: saving
                    ? null
                    : (value) {
                  setState(() {
                    if (value == true) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);

                      if (primaryId == id) {
                        primaryId = null;
                      }
                    }
                  });
                },
                secondary: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  user['fullName'] ?? 'Chưa có tên',
                ),
                subtitle: Text(
                  user['email'] ?? '',
                ),
                activeColor: Colors.deepPurple,
              ),
            );
          }),

          const SizedBox(height: 24),

          // Người phụ trách chính
          const Text(
            'Người phụ trách chính',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: selected.any(
                  (user) => getUserId(user) == primaryId,
            )
                ? primaryId
                : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Chọn người phụ trách chính',
              prefixIcon: const Icon(
                Icons.star,
                color: Colors.orange,
              ),
            ),
            items: selected.map<DropdownMenuItem<String>>((user) {
              final id = getUserId(user)!;

              return DropdownMenuItem<String>(
                value: id,
                child: Text(
                  user['fullName'] ?? 'Chưa có tên',
                ),
              );
            }).toList(),
            onChanged: saving || selected.isEmpty
                ? null
                : (value) {
              setState(() {
                primaryId = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // Nút xác nhận
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: saving ? null : submitAssignment,
              icon: const Icon(Icons.assignment_turned_in),
              label: Text(
                saving
                    ? 'Đang giao việc...'
                    : 'Xác nhận giao việc',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Danh sách thành viên đã giao
          const Text(
            'Thành viên đã được giao',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (assignees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Chưa có thành viên nào được giao.',
              ),
            ),

          ...assignees.map((user) {
            final id = getUserId(user);
            final isPrimary = id != null && id == primaryId;

            return Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPrimary
                      ? Colors.orange.shade100
                      : Colors.deepPurple.shade100,
                  child: Icon(
                    isPrimary ? Icons.star : Icons.person,
                    color: isPrimary
                        ? Colors.orange
                        : Colors.deepPurple,
                  ),
                ),
                title: Text(
                  user['fullName'] ?? 'Chưa có tên',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user['email'] ?? '',
                ),
                trailing: isPrimary
                    ? const Chip(
                  label: Text(
                    'Phụ trách chính',
                    style: TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Color(0xFFFFE0B2),
                )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
