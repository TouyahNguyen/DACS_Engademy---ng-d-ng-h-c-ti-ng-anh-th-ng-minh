import 'package:engademy/presentation/screens/admin/manage_topics_screen.dart';
import 'package:engademy/presentation/screens/admin/manage_users_screen.dart';
// import 'package:engademy/presentation/screens/admin/prompt_management_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoggingOut = false;

  Future<void> _signOut() async {
    if (!mounted) return;
    setState(() { _isLoggingOut = true; });
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}'), backgroundColor: Colors.red.shade600),
        );
        setState(() { _isLoggingOut = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            )
          else
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: _signOut,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildManagementTile(
            context: context,
            icon: Icons.folder_copy_rounded,
            color: Theme.of(context).colorScheme.primary,
            title: 'Manage Content',
            subtitle: 'Topics, lessons, and questions',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ManageTopicsScreen(),
              ));
            },
          ),
          const SizedBox(height: 12),
          _buildManagementTile(
            context: context,
            icon: Icons.people_alt_rounded,
            color: Theme.of(context).colorScheme.secondary,
            title: 'Manage Users',
            subtitle: 'View users and manage their roles',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ManageUsersScreen(),
              ));
            },
          ),
          // const SizedBox(height: 12),
          // _buildManagementTile(
          //   context: context,
          //   icon: Icons.smart_toy_rounded,
          //   color: Colors.green, // Consider a color from the theme
          //   title: 'Manage Chatbot Prompt',
          //   subtitle: 'Define the AI\'s personality and rules',
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //       builder: (context) => const PromptManagementScreen(),
          //     ));
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildManagementTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      ),
    );
  }
}
