import 'package:flutter/material.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool reminderEnabled = true;
  int reminderHours = 24;

  final List<int> reminderOptions = [1, 6, 12, 24];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt nhắc việc'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'NHẮC VIỆC TRƯỚC HẠN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cấu hình thời gian nhận thông báo trước '
            'khi công việc đến hạn.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.notifications_active,
                color: Colors.deepPurple,
              ),
              title: const Text(
                'Bật nhắc việc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                reminderEnabled ? 'Đang bật nhắc việc' : 'Đang tắt nhắc việc',
              ),
              value: reminderEnabled,
              activeThumbColor: Colors.deepPurple,
              onChanged: (value) {
                setState(() {
                  reminderEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.deepPurple),
                      SizedBox(width: 10),
                      Text(
                        'Thời gian nhắc trước hạn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: reminderHours,
                    decoration: const InputDecoration(
                      labelText: 'Nhắc trước',
                      border: OutlineInputBorder(),
                    ),
                    items: reminderOptions.map((hours) {
                      return DropdownMenuItem<int>(
                        value: hours,
                        child: Text('$hours giờ trước hạn'),
                      );
                    }).toList(),
                    onChanged: reminderEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                reminderHours = value;
                              });
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reminderEnabled
                        ? 'Bạn sẽ được nhắc trước hạn '
                              '$reminderHours giờ.'
                        : 'Bạn đã tắt chức năng nhắc việc.',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Lưu cấu hình'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      reminderEnabled
                          ? 'Đã lưu cấu hình nhắc trước '
                                '$reminderHours giờ'
                          : 'Đã lưu cấu hình tắt nhắc việc',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
