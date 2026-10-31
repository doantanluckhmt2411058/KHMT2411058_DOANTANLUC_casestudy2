
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
static const String baseUrl = 'http://localhost:3000/api/auth';

// Đăng ký
Future<Map<String, dynamic>> register({
required String fullName,
required String email,
required String password,
}) async {
final response = await http.post(
Uri.parse('$baseUrl/register'),
headers: {'Content-Type': 'application/json'},
body: jsonEncode({
'fullName': fullName,
'email': email,
'password': password,
}),
);

return jsonDecode(response.body);
}

// Đăng nhập
Future<Map<String, dynamic>> login({
required String email,
required String password,
}) async {
final response = await http.post(
Uri.parse('$baseUrl/login'),
headers: {'Content-Type': 'application/json'},
body: jsonEncode({
'email': email,
'password': password,
}),
);

final data = jsonDecode(response.body);

if (response.statusCode == 200) {
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', data['token']);
}

return data;
}

// Lấy token
Future<String?> getToken() async {
final prefs = await SharedPreferences.getInstance();
return prefs.getString('token');
}

// Đăng xuất
Future<void> logout() async {
final prefs = await SharedPreferences.getInstance();
await prefs.remove('token');
}

// Xem thông tin cá nhân
Future<Map<String, dynamic>> getMe() async {
final token = await getToken();

final response = await http.get(
Uri.parse('$baseUrl/me'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
);

return jsonDecode(response.body);
}

// Cập nhật hồ sơ
Future<Map<String, dynamic>> updateMe({
required String fullName,
String? avatarUrl,
}) async {
final token = await getToken();

final response = await http.put(
Uri.parse('$baseUrl/me'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
body: jsonEncode({
'fullName': fullName,
if (avatarUrl != null) 'avatarUrl': avatarUrl,
}),
);

return jsonDecode(response.body);
}

// Đổi mật khẩu
Future<Map<String, dynamic>> changePassword({
required String currentPassword,
required String newPassword,
}) async {
final token = await getToken();

final response = await http.put(
Uri.parse('$baseUrl/change-password'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
body: jsonEncode({
'currentPassword': currentPassword,
'newPassword': newPassword,
}),
);

return jsonDecode(response.body);
}
}
