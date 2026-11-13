
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

      final List<dynamic> loadedAssignees =
      List<dynamic>.from(result['assignees'] ?? []);

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

  // Giao công việc và nhận kết quả gửi email
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
      final result = await service.assignTask(
        widget.taskId,
        selectedIds.toList(),
        primaryId!,
      );

      await loadInitialData();

      if (!mounted) return;

      final emailSummary = result['emailSummary'];

      if (emailSummary is Map) {
        showEmailSummaryDialog(
          Map<String, dynamic>.from(emailSummary),
        );
      } else {
        showMessage('Giao công việc thành công!');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  // Hiển thị kết quả gửi email
  void showEmailSummaryDialog(Map<String, dynamic> summary) {
    final int total = summary['total'] is num
        ? (summary['total'] as num).toInt()
        : 0;

    final int success = summary['success'] is num
        ? (summary['success'] as num).toInt()
        : 0;

    final int failed = summary['failed'] is num
        ? (summary['failed'] as num).toInt()
        : 0;

    final List<dynamic> results =
    summary['results'] is List ? summary['results'] : [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.mark_email_read,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kết quả giao công việc',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giao công việc đã hoàn tất.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildEmailStat(
                        'Tổng email',
                        total,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildEmailStat(
                        'Thành công',
                        success,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildEmailStat(
                        'Thất bại',
                        failed,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                if (results.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Chi tiết gửi email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...results.map((item) {
                    final Map<String, dynamic> emailResult =
                    Map<String, dynamic>.from(item);

                    final String email =
                        emailResult['email']?.toString() ?? 'Không rõ email';

                    final String status =
                        emailResult['status']?.toString() ?? 'unknown';

                    final String message =
                        emailResult['message']?.toString() ?? '';

                    final bool isSent = status == 'sent' ||
                        status == 'success';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSent
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSent
                                ? Icons.check_circle
                                : Icons.error,
                            color: isSent
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isSent
                                      ? 'Gửi thành công'
                                      : 'Gửi thất bại',
                                  style: TextStyle(
                                    color: isSent
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                                if (message.isNotEmpty)
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                if (total == 0) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Không có email mới cần gửi. Có thể các thành viên đã được giao từ trước.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // Thẻ thống kê email
  Widget _buildEmailStat(
      String label,
      int value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
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
