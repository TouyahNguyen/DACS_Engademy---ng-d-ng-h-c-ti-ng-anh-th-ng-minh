import 'package:engademy/screens/home_screen.dart';
import 'package:engademy/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the authentication state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has data, it means the user is logged in
        if (snapshot.hasData) {
          // Show the home screen
          return const HomeScreen();
        } else {
          // Otherwise, show the login screen
          return const LoginScreen();
        }
      },
    );
  }
}
