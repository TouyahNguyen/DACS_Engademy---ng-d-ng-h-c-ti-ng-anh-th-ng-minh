import 'package:engademy/auth/login_screen.dart';
import 'package:engademy/auth/role_gate.dart';
import 'package:engademy/auth/verify_email_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // FIXED: Use userChanges() to listen for token refreshes (like email verification)
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // User is not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // User is logged in, now check for email verification
        final user = snapshot.data!;
        if (user.emailVerified) {
          // If verified, proceed to the main app via RoleGate
          return const RoleGate();
        } else {
          // If not verified, show the verification screen
          return const VerifyEmailScreen();
        }
      },
    );
  }
}
