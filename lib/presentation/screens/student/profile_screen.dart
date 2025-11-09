import 'package:engademy/presentation/providers/theme_provider.dart';
import 'package:engademy/presentation/screens/student/chatbot_screen.dart';
import 'package:engademy/presentation/screens/student/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (!mounted) return;
    setState(() { _isLoggingOut = true; });
    try {
      await FirebaseAuth.instance.signOut();
      // The AuthGate will handle navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign out: ${e.toString()}')));
        setState(() { _isLoggingOut = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Not logged in.'));
          }

          final user = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Settings'),
              const SizedBox(height: 12),
              _buildSettingsCard(context),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Danger Zone'),
              const SizedBox(height: 12),
              _buildLogoutCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    final String initial = (user.displayName?.isNotEmpty == true)
        ? user.displayName!.substring(0, 1).toUpperCase()
        : (user.email?.isNotEmpty == true ? user.email!.substring(0, 1).toUpperCase() : 'A');

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            initial,
            style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Anonymous Learner',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? 'No email',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildListTile(
            context: context,
            icon: Icons.person_outline_rounded,
            iconColor: Colors.blueAccent,
            title: 'Edit Profile',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProfileScreen())),
          ),
          const Divider(height: 1),
          _buildListTile(
            context: context,
            icon: Icons.support_agent_rounded,
            iconColor: Colors.green,
            title: 'AI Assistant',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatbotScreen())),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text('Dark Mode', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: _buildListTile(
        context: context,
        icon: Icons.logout_rounded,
        iconColor: Colors.redAccent,
        title: 'Logout',
        onTap: _isLoggingOut ? null : _logout,
        trailing: _isLoggingOut 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }

  ListTile _buildListTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }
}
