
import 'package:flutter/material.dart';
import '../auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (newPassword.length < 6) {
      _showMessage('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (result['message'] != null &&
          result['error'] == null) {
        _showMessage('Đổi mật khẩu thành công');
        Navigator.pop(context);
      } else {
        _showMessage(
          result['error'] ??
              result['message'] ??
              'Đổi mật khẩu thất bại',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi kết nối máy chủ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cập nhật mật khẩu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),

            TextField(
              controller: _currentPasswordController,
              obscureText: _hideCurrent,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideCurrent
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _hideCurrent = !_hideCurrent);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _newPasswordController,
              obscureText: _hideNew,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideNew
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _hideNew = !_hideNew);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _confirmPasswordController,
              obscureText: _hideConfirm,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideConfirm
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _hideConfirm = !_hideConfirm);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}
