
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:3000/api/tasks';

  // Lấy token đăng nhập
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập!');
    }

    return token;
  }

  // Header xác thực
  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy danh sách công việc
  Future<List<dynamic>> getTasks() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['tasks'] ?? [];
    }

    throw Exception(
      data['message'] ?? 'Không thể tải danh sách công việc!',
    );
  }

  // Lấy chi tiết công việc
  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId'),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(
      data['message'] ?? 'Không thể tải chi tiết công việc!',
    );
  }

  // Chỉnh sửa công việc
  Future<Map<String, dynamic>> updateTask(
      String taskId,
      Map<String, dynamic> taskData,
      ) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$taskId'),
      headers: _headers(token),
      body: jsonEncode(taskData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(
      data['message'] ?? 'Không thể cập nhật công việc!',
    );
  }

  // Xóa công việc
  Future<void> deleteTask(String taskId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: _headers(token),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    String message = 'Không thể xóa công việc!';

    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {
        // Phản hồi không phải JSON
      }
    }

    throw Exception(message);
  }
}
