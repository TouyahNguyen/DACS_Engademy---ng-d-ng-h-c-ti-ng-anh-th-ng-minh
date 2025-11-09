import 'dart:async';
import 'package:engademy/core/utils/ui_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isEmailVerified = false;
  bool _canResendEmail = true; // Allow resend immediately at first
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!_isEmailVerified) {
      // Check verification status periodically
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showSuccessDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 60),
          content: const Text('Xác thực thành công! Tài khoản của bạn đã được kích hoạt.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text('Bắt đầu học', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // AuthGate will now automatically handle navigation to the main app
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    
    // Only update state and show dialog if mounted and verification status changes
    if (mounted && FirebaseAuth.instance.currentUser!.emailVerified) {
      _timer?.cancel();
      setState(() => _isEmailVerified = true);
      _showSuccessDialog();
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      
      if(mounted) {
        // TODO: Show a snackbar
      }

      setState(() => _canResendEmail = false);
      // Block resend button for 30 seconds to prevent spam
      await Future.delayed(const Duration(seconds: 30));
      if(mounted) setState(() => _canResendEmail = true);

    } catch (e) {
      if(mounted) {
        // TODO: Show a snackbar with the error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // If somehow user lands here but is already verified, AuthGate will handle it,
    // but we can show a placeholder until the navigation happens.
    if (_isEmailVerified) {
      return const Scaffold(
        body: Center(child: Text('Xác thực thành công! Đang chuyển hướng...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực Email')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_read_outlined, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text('Xác thực Email của bạn', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Một email xác thực đã được gửi đến\n${FirebaseAuth.instance.currentUser?.email}.\nVui lòng kiểm tra hộp thư đến và nhấn vào liên kết để tiếp tục.',
                style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Gửi lại Email'),
                onPressed: _canResendEmail ? _sendVerificationEmail : null,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Hủy bỏ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
