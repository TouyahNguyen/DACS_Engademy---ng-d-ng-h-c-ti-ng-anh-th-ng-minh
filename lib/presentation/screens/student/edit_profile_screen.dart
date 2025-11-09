import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for display name
  late final TextEditingController _displayNameController;
  bool _isNameLoading = false;

  // Controllers for password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isPasswordLoading = false;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: _user?.displayName ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // --- DIALOGS ---
  Future<void> _showSuccessDialog(String message, {bool popTwice = false}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 60),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(fontSize: 18)),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (popTwice) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(child: const Text('Thử lại', style: TextStyle(fontSize: 18)), onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---
  Future<void> _saveProfile() async {
    final newDisplayName = _displayNameController.text.trim();
    if (newDisplayName.isEmpty) {
      _showErrorDialog('Tên hiển thị không được để trống.');
      return;
    }
    setState(() => _isNameLoading = true);
    try {
      await _user?.updateDisplayName(newDisplayName);
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'displayName': newDisplayName});
      if (mounted) _showSuccessDialog('Hồ sơ của bạn đã được cập nhật thành công!');
    } catch (e) {
      if (mounted) _showErrorDialog('Không thể cập nhật hồ sơ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isNameLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmNewPassword = _confirmNewPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty) {
      _showErrorDialog("Vui lòng điền đầy đủ các trường mật khẩu.");
      return;
    }
    if (newPassword != confirmNewPassword) {
      _showErrorDialog("Mật khẩu mới không khớp.");
      return;
    }
    if (newPassword.length < 6) {
      _showErrorDialog("Mật khẩu mới phải có ít nhất 6 ký tự.");
      return;
    }

    setState(() => _isPasswordLoading = true);

    try {
      final user = _user!;
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);

      // Reauthenticate before changing password for security
      await user.reauthenticateWithCredential(cred);

      // If reauthentication is successful, update the password
      await user.updatePassword(newPassword);

      if (mounted) {
        _showSuccessDialog("Mật khẩu đã được thay đổi thành công! Vui lòng đăng nhập lại.", popTwice: true)
          .then((_) => FirebaseAuth.instance.signOut());
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showErrorDialog("Mật khẩu hiện tại không đúng.");
      } else {
        _showErrorDialog("Đã có lỗi xảy ra: ${e.message}");
      }
    } catch (e) {
      _showErrorDialog("Đã có lỗi không mong muốn xảy ra.");
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionTitle('Public Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline_rounded)),
                  ),
                  const SizedBox(height: 16),
                  if (_isNameLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(icon: const Icon(Icons.save_rounded), label: const Text('Save Name'), onPressed: _saveProfile),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Change Password'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: !_isCurrentPasswordVisible,
                    decoration: InputDecoration(labelText: 'Current Password', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_clock_rounded), suffixIcon: _buildVisibilityToggle(_isCurrentPasswordVisible, () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    decoration: InputDecoration(labelText: 'New Password', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline), suffixIcon: _buildVisibilityToggle(_isNewPasswordVisible, () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible))),
                  ),
                  const SizedBox(height: 16),
                   TextField(
                    controller: _confirmNewPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset_rounded)),
                  ),
                  const SizedBox(height: 24),
                  if (_isPasswordLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(icon: const Icon(Icons.shield_rounded), label: const Text('Change Password'), onPressed: _changePassword, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Theme.of(context).colorScheme.onSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600));
  }

  IconButton _buildVisibilityToggle(bool isVisible, VoidCallback onPressed) {
    return IconButton(icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility), onPressed: onPressed);
  }
}
