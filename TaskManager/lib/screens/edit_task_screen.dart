
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  late DateTime startDate;
  late DateTime dueDate;
  late String priority;
  late String status;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.task['title']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.task['description']?.toString() ?? '',
    );

    startDate = DateTime.tryParse(
      widget.task['startDate']?.toString() ?? '',
    ) ??
        DateTime.now();

    dueDate = DateTime.tryParse(
      widget.task['dueDate']?.toString() ?? '',
    ) ??
        startDate;

    priority = widget.task['priority']?.toString() ?? 'medium';
    status = widget.task['status']?.toString() ?? 'todo';
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> selectDate(bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        startDate = selected;
        if (dueDate.isBefore(startDate)) {
          dueDate = startDate;
        }
      } else {
        dueDate = selected;
      }
    });
  }

  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (dueDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hạn hoàn thành không được trước ngày bắt đầu!'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final taskId = widget.task['_id'].toString();

      final updatedTask = await _taskService.updateTask(
        taskId,
        {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'startDate': startDate.toIso8601String(),
          'dueDate': dueDate.toIso8601String(),
          'priority': priority,
          'status': status,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật công việc thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, updatedTask);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THÔNG TIN CÔNG VIỆC',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên công việc',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên công việc';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả công việc',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Ngày bắt đầu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: Colors.deepPurple,
                ),
                title: Text(formatDate(startDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () => selectDate(true),
              ),

              const Divider(),

              const Text(
                'Hạn hoàn thành',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.event,
                  color: Colors.deepPurple,
                ),
                title: Text(formatDate(dueDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () => selectDate(false),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
                  border: OutlineInputBorder(),
                ),
                items: const [
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
                  if (value != null) {
                    setState(() => priority = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
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
                  if (value != null) {
                    setState(() => status = value);
                  }
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveTask,
                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
