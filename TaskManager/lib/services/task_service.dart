
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
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

  // Đọc dữ liệu JSON an toàn
  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return {};

    try {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (_) {
      throw Exception('Phản hồi từ máy chủ không hợp lệ!');
    }
  }

  // B1: Lấy danh sách công việc
  Future<List<dynamic>> getTasks() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: _headers(token),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data['tasks'] ?? [];
    }

    throw Exception(
      data['message'] ?? 'Không thể tải danh sách công việc!',
    );
  }

  // B2: Lấy chi tiết công việc
  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId'),
      headers: _headers(token),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(
      data['message'] ?? 'Không thể tải chi tiết công việc!',
    );
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

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(
      data['message'] ?? 'Không thể cập nhật công việc!',
    );
  }

  // B5: Xóa công việc
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

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception(
      data['message'] ?? 'Không thể cập nhật trạng thái công việc!',
    );
  }

  // C1: Tìm kiếm người dùng
  Future<List<dynamic>> searchUsers(String query) async {
    final token = await _getToken();

    final uri = Uri.parse(
      '$usersBaseUrl/search?q=${Uri.encodeQueryComponent(query)}',
    );

    final response = await http.get(
      uri,
      headers: _headers(token),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data['users'] ?? [];
    }

    throw Exception(
      data['message'] ?? 'Không thể tìm người dùng!',
    );
  }

  // C1 + C2 + D1: Giao công việc và gửi email
  Future<Map<String, dynamic>> assignTask(
      String taskId,
      List<String> userIds,
      String primaryAssigneeId,
      ) async {
    final token = await _getToken();

    // Loại bỏ ID trùng lặp
    final uniqueIds = userIds.toSet().toList();

    if (uniqueIds.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất một thành viên!');
    }

    if (!uniqueIds.contains(primaryAssigneeId)) {
      throw Exception(
        'Người phụ trách chính phải nằm trong danh sách được giao!',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/assignees'),
      headers: _headers(token),
      body: jsonEncode({
        'assigneeIds': uniqueIds,
        'userIds': uniqueIds,
        'primaryAssigneeId': primaryAssigneeId,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ??
          data['error'] ??
          'Giao công việc thất bại!',
    );
  }

  // C1 + C5: Lấy thông tin người được giao
  Future<Map<String, dynamic>> getTaskAssignees(
      String taskId,
      ) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId/assignees'),
      headers: _headers(token),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Không thể lấy danh sách người được giao!',
    );
  }

  // C3: Lấy danh sách người được chia sẻ
  Future<List<dynamic>> getTaskShares(String taskId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId/shares'),
      headers: _headers(token),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data['shares'] ?? [];
    }

    throw Exception(
      data['message'] ?? 'Không thể lấy danh sách chia sẻ!',
    );
  }

  // C5: Lấy toàn bộ danh sách thành viên công việc
  Future<Map<String, dynamic>> getTaskMembers(String taskId) async {
    final assigneeData = await getTaskAssignees(taskId);
    final shares = await getTaskShares(taskId);

    return {
      'createdBy': assigneeData['createdBy'],
      'primaryAssignee': assigneeData['primaryAssignee'],
      'assignees': assigneeData['assignees'] ?? [],
      'shares': shares,
    };
  }

  // C3: Chia sẻ công việc
  // permission: viewer hoặc editor
  Future<Map<String, dynamic>> shareTask(
      String taskId,
      List<String> userIds,
      String permission,
      ) async {
    final token = await _getToken();

    if (!['viewer', 'editor'].contains(permission)) {
      throw Exception('Quyền chia sẻ không hợp lệ!');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/shares'),
      headers: _headers(token),
      body: jsonEncode({
        'userIds': userIds,
        'permission': permission,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Chia sẻ công việc thất bại!',
    );
  }

  // C4: Thay đổi quyền chia sẻ
  Future<Map<String, dynamic>> updateSharePermission(
      String taskId,
      String shareId,
      String permission,
      ) async {
    final token = await _getToken();

    if (!['viewer', 'editor'].contains(permission)) {
      throw Exception('Quyền chia sẻ không hợp lệ!');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/$taskId/shares/$shareId'),
      headers: _headers(token),
      body: jsonEncode({
        'permission': permission,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Không thể thay đổi quyền!',
    );
  }

  // C4: Thu hồi quyền chia sẻ
  Future<void> removeTaskShare(
      String taskId,
      String shareId,
      ) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId/shares/$shareId'),
      headers: _headers(token),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    String message = 'Không thể thu hồi quyền chia sẻ!';

    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {}
    }

    throw Exception(message);
  }
}
