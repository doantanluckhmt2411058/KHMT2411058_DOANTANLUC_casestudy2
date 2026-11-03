
import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? startDate;
  DateTime? dueDate;
  String priority = 'medium';
  String status = 'todo';

  Future<void> selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          startDate = date;
        } else {
          dueDate = date;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    return '${date.day}/${date.month}/${date.year}';
  }

  void saveTask() {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu và hạn hoàn thành'),
        ),
      );
      return;
    }

    if (dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hạn hoàn thành phải sau ngày bắt đầu'),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'startDate': startDate!.toIso8601String(),
      'dueDate': dueDate!.toIso8601String(),
      'priority': priority,
      'status': status,
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm công việc'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin công việc',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              const Text('Tên công việc'),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên công việc',
                  prefixIcon: Icon(Icons.task_alt),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên công việc';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              const Text('Mô tả'),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Nhập mô tả công việc...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Ngày bắt đầu'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => selectDate(true),
                icon: const Icon(Icons.calendar_today),
                label: Text(formatDate(startDate)),
              ),

              const SizedBox(height: 16),
              const Text('Hạn hoàn thành'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => selectDate(false),
                icon: const Icon(Icons.event),
                label: Text(formatDate(dueDate)),
              ),

              const SizedBox(height: 20),
              const Text('Mức độ ưu tiên'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
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

              const SizedBox(height: 20),
              const Text('Trạng thái'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
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

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: saveTask,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Lưu công việc',
                    style: TextStyle(fontSize: 16),
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
