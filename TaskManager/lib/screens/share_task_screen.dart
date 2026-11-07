
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

  // Chia sẻ cho nhiều người với quyền chỉ xem
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
        'viewer',
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
        const SnackBar(
          content: Text('Chia sẻ công việc thành công!'),
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

  // Kiểm tra người đã được chia sẻ chưa
  bool isAlreadyShared(String userId) {
    return shares.any((share) {
      final user = share['userId'];
      return getUserId(user) == userId;
    });
  }

  // Hiển thị từng người dùng
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
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa chia sẻ công việc cho ai.'),
      );
    }

    return Column(
      children: shares.map((share) {
        final user = share['userId'];
        final permission = share['permission']?.toString() ?? 'viewer';

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(getUserName(user)),
          subtitle: Text(getUserEmail(user)),
          trailing: Chip(
            avatar: Icon(
              permission == 'editor'
                  ? Icons.edit
                  : Icons.visibility,
              size: 16,
            ),
            label: Text(
              permission == 'editor' ? 'Chỉnh sửa' : 'Chỉ xem',
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
              const SizedBox(height: 12),
              Text(
                'Đã chọn ${selectedIds.length} người',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isSharing ? null : shareSelectedUsers,
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
                        : 'Chia sẻ cho những người đã chọn',
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

            const SizedBox(height: 12),
            buildShareList(),
          ],
        ),
      ),
    );
  }
}
