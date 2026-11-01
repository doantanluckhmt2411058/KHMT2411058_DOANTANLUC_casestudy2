import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:3000/api/tasks';

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

    throw Exception(
      data['message'] ?? 'Không thể tải danh sách công việc!',
    );
  }
}
