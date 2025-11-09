import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engademy/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:engademy/presentation/screens/onboarding_screen.dart';
import 'package:engademy/presentation/screens/student/main_student_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Something went wrong. No user found.')));
    }

    // Chuyển từ FutureBuilder sang StreamBuilder để lắng nghe thay đổi real-time
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        // Xử lý trường hợp user bị xóa khỏi Firestore nhưng vẫn đăng nhập
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Mặc định cho về trang student để tránh bị kẹt
          return const MainStudentScreen(); 
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        // --- KIỂM TRA ONBOARDING ---
        // Mặc định là false cho user mới, nếu trường này không tồn tại
        final hasCompletedOnboarding = userData['hasCompletedOnboarding'] as bool? ?? false;

        if (!hasCompletedOnboarding) {
          return const OnboardingScreen();
        }
        // --- KẾT THÚC KIỂM TRA ONBOARDING ---

        // Nếu đã hoàn thành onboarding, kiểm tra vai trò như bình thường
        final userRole = userData['role'] as String?;

        if (userRole == 'admin') {
          return const AdminDashboardScreen();
        } else {
          return const MainStudentScreen(); // Mặc định cho 'student' hoặc các vai trò khác
        }
      },
    );
  }
}
