import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:3000/api/tasks';

  // Lấy danh sách công việc
  Future<List<dynamic>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập!');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['tasks'] ?? [];
    }

    throw Exception(data['message'] ?? 'Không thể tải danh sách công việc!');
  }

  // Lấy chi tiết công việc
  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập!');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(data['message'] ?? 'Không thể tải chi tiết công việc!');
  }
}
