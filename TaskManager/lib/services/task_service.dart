
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  // Địa chỉ Backend
  static const String baseUrl = 'http://localhost:3000/api/tasks';
  static const String usersBaseUrl = 'http://localhost:3000/api/users';

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

  // B1: Lấy danh sách công việc
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

    throw Exception(data['message'] ?? 'Không thể tải danh sách công việc!');
  }

  // B2: Lấy chi tiết công việc
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

    throw Exception(data['message'] ?? 'Không thể tải chi tiết công việc!');
  }

  // B4: Chỉnh sửa công việc
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

    throw Exception(data['message'] ?? 'Không thể cập nhật công việc!');
  }

  // B5: Xóa công việc
  Future<void> deleteTask(String taskId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: _headers(token),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    String message = 'Không thể xóa công việc!';

    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {}
    }

    throw Exception(message);
  }

  // B6: Cập nhật trạng thái công việc
  Future<Map<String, dynamic>> updateTaskStatus(
      String taskId,
      String status,
      ) async {
    final token = await _getToken();

    const allowedStatuses = [
      'todo',
      'in_progress',
      'completed',
    ];

    if (!allowedStatuses.contains(status)) {
      throw Exception('Trạng thái công việc không hợp lệ!');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/$taskId/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(
      data['message'] ?? 'Không thể cập nhật trạng thái công việc!',
    );
  }

  // C1: Tìm kiếm người dùng theo tên hoặc email
  Future<List<dynamic>> searchUsers(String query) async {
    final token = await _getToken();

    final uri = Uri.parse(
      '$usersBaseUrl/search?q=${Uri.encodeQueryComponent(query)}',
    );

    final response = await http.get(
      uri,
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['users'] ?? [];
    }

    throw Exception(data['message'] ?? 'Không thể tìm người dùng!');
  }

  // C1: Giao công việc cho một hoặc nhiều người
  Future<Map<String, dynamic>> assignTask(
      String taskId,
      List<String> userIds,
      ) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/assignees'),
      headers: _headers(token),
      body: jsonEncode({'userIds': userIds}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Giao công việc thất bại!');
  }

  // C1: Xem danh sách người được giao
  Future<List<dynamic>> getTaskAssignees(String taskId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId/assignees'),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['assignees'] ?? [];
    }

    throw Exception(
      data['message'] ?? 'Không thể lấy danh sách người được giao!',
    );
  }
}
