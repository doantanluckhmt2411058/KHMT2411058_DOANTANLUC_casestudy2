
import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Lấy thông tin tài khoản
  Future<void> _loadProfile() async {
    try {
      final result = await _authService.getMe();

      if (!mounted) return;

      if (result['user'] != null) {
        user = Map<String, dynamic>.from(result['user']);
      } else if (result['_id'] != null || result['email'] != null) {
        user = result;
      } else {
        user = null;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải thông tin: $e'),
        ),
      );
    }
  }

  // Mở màn hình chỉnh sửa tài khoản
  Future<void> _openEditProfile() async {
    if (user == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: user!),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      setState(() {
        isLoading = true;
      });

      await _loadProfile();
    }
  }

  // Mở màn hình đổi mật khẩu
  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  // Đăng xuất
  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : user == null
          ? const Center(
        child: Text('Không tìm thấy thông tin tài khoản'),
      )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Ảnh đại diện
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.deepPurple,
              backgroundImage:
              user!['avatarUrl'] != null &&
                  user!['avatarUrl']
                      .toString()
                      .isNotEmpty
                  ? NetworkImage(user!['avatarUrl'])
                  : null,
              child: user!['avatarUrl'] == null ||
                  user!['avatarUrl'].toString().isEmpty
                  ? const Icon(
                Icons.person,
                size: 65,
                color: Colors.white,
              )
                  : null,
            ),

            const SizedBox(height: 20),

            // Tên người dùng
            Text(
              user!['fullName'] ?? 'Người dùng',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Họ và tên
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Họ và tên'),
                subtitle: Text(
                  user!['fullName'] ?? '',
                ),
              ),
            ),

            // Email
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(
                  user!['email'] ?? '',
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Nút chỉnh sửa thông tin
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit),
                label: const Text(
                  'CHỈNH SỬA THÔNG TIN',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nút đổi mật khẩu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openChangePassword,
                icon: const Icon(Icons.lock_reset),
                label: const Text(
                  'ĐỔI MẬT KHẨU',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const Spacer(),

            // Nút đăng xuất
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('ĐĂNG XUẤT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
