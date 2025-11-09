import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  // Shows a dialog to confirm and change a user's role.
  void _showChangeRoleDialog(BuildContext context, DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentRole = userData['role'] ?? 'student';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Role for ${userData['email']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Role: $currentRole'),
              const Divider(height: 30),
              ListTile(
                title: const Text('Promote to Admin'),
                leading: Icon(Icons.shield_rounded, color: Colors.amber.shade800),
                onTap: () {
                  _updateRole(context, userDoc, 'admin');
                },
              ),
              ListTile(
                title: const Text('Demote to Student'),
                leading: Icon(Icons.school_rounded, color: Colors.green.shade700),
                onTap: () {
                  _updateRole(context, userDoc, 'student');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Updates the user's role in Firestore and closes the dialog.
  Future<void> _updateRole(BuildContext context, DocumentSnapshot userDoc, String newRole) async {
    await userDoc.reference.update({'role': newRole});
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $newRole'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: StreamBuilder<QuerySnapshot>(
        // Assumes a 'users' collection exists where user data is stored.
        stream: FirebaseFirestore.instance.collection('users').orderBy('email').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found in Firestore.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final email = userData['email'] ?? 'No Email';
              final role = userData['role'] ?? 'student';

              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => _showChangeRoleDialog(context, userDoc),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  leading: Icon(
                    role == 'admin' ? Icons.shield_rounded : Icons.school_rounded,
                    color: role == 'admin' ? Colors.amber.shade800 : Colors.green.shade700,
                    size: 28,
                  ),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Text('Role: $role', style: const TextStyle(color: Colors.black54)),
                  trailing: const Icon(Icons.edit_note_rounded, size: 24, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
