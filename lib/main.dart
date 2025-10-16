import 'package:engademy/screens/auth_gate.dart'; // Import the new AuthGate
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Engademy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Set the home to our new AuthGate
      // It will decide whether to show the LoginScreen or HomeScreen
      home: const AuthGate(),
    );
  }
}
