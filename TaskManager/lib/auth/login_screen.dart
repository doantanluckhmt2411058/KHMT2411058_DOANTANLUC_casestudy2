
import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'register_screen.dart';
import '../screens/profile_screen.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final AuthService _authService = AuthService();

bool _isLoading = false;
bool _obscurePassword = true;

// Đăng nhập
Future<void> _login() async {
if (!_formKey.currentState!.validate()) return;

setState(() => _isLoading = true);

try {
final result = await _authService.login(
email: _emailController.text.trim(),
password: _passwordController.text,
);

if (!mounted) return;

if (result['token'] != null) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => const ProfileScreen(),
),
);
} else {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
result['message'] ?? 'Đăng nhập thất bại!',
),
backgroundColor: Colors.red,
),
);
}
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Không thể kết nối máy chủ: $e'),
),
);
} finally {
if (mounted) {
setState(() => _isLoading = false);
}
}
}

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F6FA),
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Form(
key: _formKey,
child: Column(
children: [
const Icon(
Icons.task_alt,
size: 75,
color: Colors.deepPurple,
),

const SizedBox(height: 16),

const Text(
'TASK MANAGER',
style: TextStyle(
fontSize: 27,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

const Text(
'Đăng nhập vào tài khoản của bạn',
),

const SizedBox(height: 35),

// Email
TextFormField(
controller: _emailController,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: 'Email',
prefixIcon: Icon(Icons.email_outlined),
border: OutlineInputBorder(),
filled: true,
fillColor: Colors.white,
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Vui lòng nhập email';
}

if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
    .hasMatch(value.trim())) {
return 'Email không hợp lệ';
}

return null;
},
),

const SizedBox(height: 18),

// Mật khẩu
TextFormField(
controller: _passwordController,
obscureText: _obscurePassword,
decoration: InputDecoration(
labelText: 'Mật khẩu',
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
icon: Icon(
_obscurePassword
? Icons.visibility
    : Icons.visibility_off,
),
onPressed: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
),
border: const OutlineInputBorder(),
filled: true,
fillColor: Colors.white,
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'Vui lòng nhập mật khẩu';
}

return null;
},
),

const SizedBox(height: 28),

// Nút đăng nhập
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton(
onPressed: _isLoading ? null : _login,
child: _isLoading
? const CircularProgressIndicator()
    : const Text(
'ĐĂNG NHẬP',
style: TextStyle(fontSize: 16),
),
),
),

const SizedBox(height: 12),

// Chuyển sang màn hình đăng ký
TextButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const RegisterScreen(),
),
);
},
child: const Text(
'Chưa có tài khoản? Đăng ký ngay',
style: TextStyle(
color: Colors.deepPurple,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
),
),
);
}
}
