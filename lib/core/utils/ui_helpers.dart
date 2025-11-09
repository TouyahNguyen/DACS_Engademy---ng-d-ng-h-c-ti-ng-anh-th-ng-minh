import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, {bool isError = false, Duration duration = const Duration(seconds: 4)}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ),
  );
}

void handleAuthError(BuildContext context, FirebaseAuthException e) {
  String message;
  switch (e.code) {
    case 'weak-password':
      message = 'Mật khẩu được cung cấp quá yếu.';
      break;
    case 'email-already-in-use':
      message = 'Một tài khoản đã tồn tại với email này.';
      break;
    case 'invalid-email':
      message = 'Địa chỉ email của bạn không hợp lệ.';
      break;
    default:
      message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
  showSnackBar(context, message, isError: true);
}
