
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class ShareTaskScreen extends StatefulWidget {
  final String taskId;

  const ShareTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<ShareTaskScreen> createState() => _ShareTaskScreenState();
}

class _ShareTaskScreenState extends State<ShareTaskScreen> {
  final TaskService service = TaskService();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> shares = [];
  final Set<String> selectedIds = {};

  bool isSearching = false;
  bool isLoadingShares = true;
  bool isSharing = false;

  // Quyền mặc định khi chia sẻ
  String selectedPermission = 'viewer';

  String getUserId(dynamic user) {
    if (user is Map) {
      return (user['_id'] ?? user['id'] ?? '').toString();
    }
    return user?.toString() ?? '';
  }

  String getUserName(dynamic user) {
    if (user is Map) {
      return user['fullName']?.toString() ?? 'Người dùng';
    }
    return 'Người dùng';
  }

  String getUserEmail(dynamic user) {
    if (user is Map) {
      return user['email']?.toString() ?? '';
    }
    return '';
  }

  String permissionText(String permission) {
    return permission == 'editor' ? 'Chỉnh sửa' : 'Chỉ xem';
  }

  @override
  void initState() {
    super.initState();
    loadShares();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Tải danh sách người đã được chia sẻ
  Future<void> loadShares() async {
    try {
      final result = await service.getTaskShares(widget.taskId);

      if (!mounted) return;

      setState(() {
        shares = result;
        isLoadingShares = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingShares = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách chia sẻ: $e')),
      );
    }
  }

  // Tìm kiếm người dùng
  Future<void> searchUsers() async {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        users = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final result = await service.searchUsers(query);

      if (!mounted) return;

      setState(() {
        users = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm người dùng: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  // Chọn hoặc bỏ chọn người dùng
  void toggleUser(String userId) {
    setState(() {
      if (selectedIds.contains(userId)) {
        selectedIds.remove(userId);
      } else {
        selectedIds.add(userId);
      }
    });
  }

  // Chia sẻ công việc với quyền đã chọn
  Future<void> shareSelectedUsers() async {
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một người!'),
        ),
      );
      return;
    }

    setState(() {
      isSharing = true;
    });

    try {
      await service.shareTask(
        widget.taskId,
        selectedIds.toList(),
        selectedPermission,
      );

      if (!mounted) return;

      setState(() {
        selectedIds.clear();
        users = [];
        searchController.clear();
      });

      await loadShares();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chia sẻ thành công với quyền ${permissionText(selectedPermission)}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chia sẻ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSharing = false;
        });
      }
    }
  }

  // Kiểm tra người dùng đã được chia sẻ chưa
  bool isAlreadyShared(String userId) {
    return shares.any((share) {
      return getUserId(share['userId']) == userId;
    });
  }

  // Thay đổi quyền Viewer / Editor
  Future<void> changePermission(
      dynamic share,
      String newPermission,
      ) async {
    final shareId = share['_id']?.toString();

    if (shareId == null || shareId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã chia sẻ!'),
        ),
      );
      return;
    }

    final oldPermission =
        share['permission']?.toString() ?? 'viewer';

    if (oldPermission == newPermission) return;

    try {
      await service.updateSharePermission(
        widget.taskId,
        shareId,
        newPermission,
      );

      if (!mounted) return;

      await loadShares();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã đổi quyền thành ${permissionText(newPermission)}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thay đổi quyền: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Thu hồi quyền chia sẻ
  Future<void> removeShare(dynamic share) async {
    final user = share['userId'];
    final shareId = share['_id']?.toString();

    if (shareId == null || shareId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã chia sẻ!'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thu hồi quyền chia sẻ'),
          content: Text(
            'Bạn có chắc muốn thu hồi quyền của '
                '${getUserName(user)} không?',
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
              child: const Text('Thu hồi'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await service.removeTaskShare(widget.taskId, shareId);

      if (!mounted) return;

      await loadShares();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thu hồi quyền chia sẻ!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thu hồi quyền: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hiển thị từng người dùng tìm được
  Widget buildUserItem(dynamic user) {
    final id = getUserId(user);

    if (id.isEmpty) {
      return const SizedBox.shrink();
    }

    final alreadyShared = isAlreadyShared(id);
    final selected = selectedIds.contains(id);

    return Card(
      child: CheckboxListTile(
        value: alreadyShared || selected,
        onChanged: alreadyShared
            ? null
            : (_) => toggleUser(id),
        secondary: alreadyShared
            ? const Icon(
          Icons.check_circle,
          color: Colors.green,
        )
            : const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(getUserName(user)),
        subtitle: Text(
          alreadyShared
              ? '${getUserEmail(user)} • Đã chia sẻ'
              : getUserEmail(user),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  // Danh sách người được chia sẻ
  Widget buildShareList() {
    if (isLoadingShares) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (shares.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Chưa chia sẻ công việc cho ai.'),
          ),
        ),
      );
    }

    return Column(
      children: shares.map((share) {
        final user = share['userId'];
        final permission =
            share['permission']?.toString() ?? 'viewer';

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(getUserName(user)),
            subtitle: Text(
              '${getUserEmail(user)}\n'
                  'Quyền: ${permissionText(permission)}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              tooltip: 'Quản lý quyền',
              onSelected: (value) {
                if (value == 'remove') {
                  removeShare(share);
                } else {
                  changePermission(share, value);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'viewer',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 20),
                      const SizedBox(width: 10),
                      const Text('Cấp quyền chỉ xem'),
                      if (permission == 'viewer') ...[
                        const Spacer(),
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'editor',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 10),
                      const Text('Cấp quyền chỉnh sửa'),
                      if (permission == 'editor') ...[
                        const Spacer(),
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_remove,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Thu hồi quyền',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chia sẻ công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TÌM NGƯỜI DÙNG',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc email người dùng',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: isSearching ? null : searchUsers,
                ),
              ),
              onSubmitted: (_) => searchUsers(),
            ),

            const SizedBox(height: 12),

            if (isSearching)
              const Center(
                child: CircularProgressIndicator(),
              ),

            ...users.map(buildUserItem),

            if (selectedIds.isNotEmpty) ...[
              const SizedBox(height: 16),

              Text(
                'Đã chọn ${selectedIds.length} người',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 12),

              // Chọn quyền khi chia sẻ
              DropdownButtonFormField<String>(
                value: selectedPermission,
                decoration: const InputDecoration(
                  labelText: 'Quyền truy cập',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 10),
                        Text('Viewer - Chỉ xem'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'editor',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 10),
                        Text('Editor - Chỉnh sửa'),
                      ],
                    ),
                  ),
                ],
                onChanged: isSharing
                    ? null
                    : (value) {
                  if (value != null) {
                    setState(() {
                      selectedPermission = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed:
                  isSharing ? null : shareSelectedUsers,
                  icon: isSharing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.share),
                  label: Text(
                    isSharing
                        ? 'Đang chia sẻ...'
                        : 'Chia sẻ công việc',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            const Divider(),

            const Text(
              'DANH SÁCH NGƯỜI ĐƯỢC CHIA SẺ',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Nhấn dấu ba chấm bên cạnh người dùng để thay đổi '
                  'quyền hoặc thu hồi quyền chia sẻ.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            buildShareList(),
          ],
        ),
      ),
    );
  }
}
