
import 'package:flutter/material.dart';

import 'task_detail_screen.dart';
import 'add_task_screen.dart';
import 'assign_task_screen.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> tasks = [];

  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';
  String statusFilter = 'all';
  String priorityFilter = 'all';
  String assigneeFilter = 'all';
  String sortBy = 'createdAt';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Tải danh sách công việc
  Future<void> loadTasks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _taskService.getTasks();

      if (!mounted) return;

      setState(() {
        tasks = result;
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

  // Mở màn hình thêm công việc
  Future<void> openAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );

    if (mounted) {
      await loadTasks();
    }
  }

  // Mở màn hình giao việc C1
  Future<void> openAssignTask(String taskId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTaskScreen(taskId: taskId),
      ),
    );

    if (mounted) {
      await loadTasks();
    }
  }

  // Chuyển trạng thái sang tiếng Việt
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

  // Chuyển mức độ ưu tiên sang tiếng Việt
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

  // Lấy tên người phụ trách
  String getAssigneeName(dynamic user) {
    if (user == null) return 'Chưa phân công';

    if (user is Map) {
      return user['fullName']?.toString() ?? 'Chưa xác định';
    }

    return user.toString();
  }

  // Lấy ID người phụ trách
  String getAssigneeId(dynamic user) {
    if (user == null) return '';

    if (user is Map) {
      return user['_id']?.toString() ?? '';
    }

    return user.toString();
  }

  // Tìm kiếm, lọc và sắp xếp
  List<dynamic> get filteredTasks {
    List<dynamic> result = List<dynamic>.from(tasks);

    // Tìm kiếm theo tên công việc
    if (searchQuery.trim().isNotEmpty) {
      result = result.where((task) {
        final title = task['title']?.toString().toLowerCase() ?? '';
        return title.contains(searchQuery.trim().toLowerCase());
      }).toList();
    }

    // Lọc theo trạng thái
    if (statusFilter != 'all') {
      result = result.where((task) {
        return task['status']?.toString() == statusFilter;
      }).toList();
    }

    // Lọc theo mức độ ưu tiên
    if (priorityFilter != 'all') {
      result = result.where((task) {
        return task['priority']?.toString() == priorityFilter;
      }).toList();
    }

    // Lọc theo người phụ trách
    if (assigneeFilter != 'all') {
      result = result.where((task) {
        final primaryId = getAssigneeId(task['primaryAssigneeId']);
        final assignees = task['assigneeIds'];

        final hasAssignee = assignees is List &&
            assignees.any((user) {
              return getAssigneeId(user) == assigneeFilter;
            });

        return primaryId == assigneeFilter || hasAssignee;
      }).toList();
    }

    // Sắp xếp công việc
    result.sort((a, b) {
      switch (sortBy) {
        case 'dueDate':
          final dateA = DateTime.tryParse(
            a['dueDate']?.toString() ?? '',
          );
          final dateB = DateTime.tryParse(
            b['dueDate']?.toString() ?? '',
          );

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateA.compareTo(dateB);

        case 'priority':
          const priorityOrder = {
            'high': 1,
            'medium': 2,
            'low': 3,
          };

          final priorityA = priorityOrder[a['priority']] ?? 4;
          final priorityB = priorityOrder[b['priority']] ?? 4;

          return priorityA.compareTo(priorityB);

        case 'createdAt':
        default:
          final dateA = DateTime.tryParse(
            a['createdAt']?.toString() ?? '',
          );
          final dateB = DateTime.tryParse(
            b['createdAt']?.toString() ?? '',
          );

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
      }
    });

    return result;
  }

  // Lấy danh sách người phụ trách để lọc
  List<Map<String, String>> get assigneeOptions {
    final Map<String, String> uniqueUsers = {};

    for (final task in tasks) {
      final users = task['assigneeIds'];

      if (users is List) {
        for (final user in users) {
          if (user is Map) {
            final id = getAssigneeId(user);
            final name = getAssigneeName(user);

            if (id.isNotEmpty) {
              uniqueUsers[id] = name;
            }
          }
        }
      }

      final primary = task['primaryAssigneeId'];

      if (primary is Map) {
        final id = getAssigneeId(primary);
        final name = getAssigneeName(primary);

        if (id.isNotEmpty) {
          uniqueUsers[id] = name;
        }
      }
    }

    return uniqueUsers.entries
        .map((entry) => {
      'id': entry.key,
      'name': entry.value,
    })
        .toList();
  }

  // Xóa toàn bộ bộ lọc
  void resetFilters() {
    setState(() {
      searchController.clear();
      searchQuery = '';
      statusFilter = 'all';
      priorityFilter = 'all';
      assigneeFilter = 'all';
      sortBy = 'createdAt';
    });
  }

  // Mở chi tiết công việc
  Future<void> openTaskDetail(Map<String, dynamic> task) async {
    final id = task['_id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID công việc!'),
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );

    if (result != null && mounted) {
      await loadTasks();

      if (!mounted) return;

      if (result['deleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa công việc thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danh sách công việc đã được cập nhật!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      await loadTasks();
    }
  }

  // Giao diện tìm kiếm
  Widget searchSection() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo tên công việc...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            searchController.clear();
            setState(() {
              searchQuery = '';
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
    );
  }

  // Giao diện lọc
  Widget filterSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'LỌC CÔNG VIỆC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lọc trạng thái
            DropdownButtonFormField<String>(
              value: statusFilter,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả trạng thái'),
                ),
                DropdownMenuItem(
                  value: 'todo',
                  child: Text('Chưa thực hiện'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('Đang thực hiện'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Đã hoàn thành'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  statusFilter = value ?? 'all';
                });
              },
            ),

            const SizedBox(height: 12),

            // Lọc ưu tiên
            DropdownButtonFormField<String>(
              value: priorityFilter,
              decoration: const InputDecoration(
                labelText: 'Mức độ ưu tiên',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả mức ưu tiên'),
                ),
                DropdownMenuItem(
                  value: 'low',
                  child: Text('Thấp'),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Text('Trung bình'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text('Cao'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  priorityFilter = value ?? 'all';
                });
              },
            ),

            const SizedBox(height: 12),

            // Lọc người phụ trách
            DropdownButtonFormField<String>(
              value: assigneeFilter,
              decoration: const InputDecoration(
                labelText: 'Người phụ trách',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả người phụ trách'),
                ),
                ...assigneeOptions.map((user) {
                  return DropdownMenuItem(
                    value: user['id'],
                    child: Text(user['name'] ?? ''),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  assigneeFilter = value ?? 'all';
                });
              },
            ),

            const SizedBox(height: 12),

            // Nút xóa bộ lọc
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Đặt lại bộ lọc'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện sắp xếp
  Widget sortSection() {
    return Row(
      children: [
        const Icon(
          Icons.sort,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 8),
        const Text(
          'Sắp xếp:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: sortBy,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'createdAt',
                child: Text('Thời gian tạo mới nhất'),
              ),
              DropdownMenuItem(
                value: 'dueDate',
                child: Text('Hạn hoàn thành gần nhất'),
              ),
              DropdownMenuItem(
                value: 'priority',
                child: Text('Ưu tiên cao trước'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                sortBy = value ?? 'createdAt';
              });
            },
          ),
        ),
      ],
    );
  }

  // Thẻ công việc
  Widget taskCard(Map<String, dynamic> task) {
    final taskId = task['_id']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 8,
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE7F6),
          child: Icon(
            Icons.assignment,
            color: Colors.deepPurple,
          ),
        ),

        title: Text(
          task['title']?.toString() ?? 'Không có tiêu đề',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              task['description']?.toString() ?? 'Không có mô tả',
            ),
            const SizedBox(height: 6),
            Text(
              'Trạng thái: ${statusText(task['status']?.toString())}',
            ),
            Text(
              'Ưu tiên: ${priorityText(task['priority']?.toString())}',
            ),
            if (task['dueDate'] != null)
              Text(
                'Hạn hoàn thành: ${task['dueDate'].toString().substring(0, 10)}',
              ),
            const SizedBox(height: 5),
            const Text(
              'Nhấn để xem, chỉnh sửa hoặc xóa',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 12,
              ),
            ),
          ],
        ),

        // Menu thao tác
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: Colors.deepPurple,
          ),
          onSelected: (value) {
            if (taskId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không tìm thấy ID công việc!'),
                ),
              );
              return;
            }

            if (value == 'assign') {
              openAssignTask(taskId);
            } else if (value == 'detail') {
              openTaskDetail(task);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'detail',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Xem chi tiết'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'assign',
              child: Row(
                children: [
                  Icon(
                    Icons.group_add,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(width: 8),
                  Text('Giao việc'),
                ],
              ),
            ),
          ],
        ),

        onTap: () => openTaskDetail(task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedTasks = filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddTask,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 45,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadTasks,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            searchSection(),
            const SizedBox(height: 12),
            filterSection(),
            const SizedBox(height: 12),
            sortSection(),
            const SizedBox(height: 16),

            Text(
              'Tìm thấy ${displayedTasks.length} công việc',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 8),

            if (displayedTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'Không tìm thấy công việc phù hợp!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            else
              ...displayedTasks.map((item) {
                final task = Map<String, dynamic>.from(item);
                return taskCard(task);
              }),
          ],
        ),
      ),
    );
  }
}
