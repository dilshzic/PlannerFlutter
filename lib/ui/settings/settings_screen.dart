import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:narwhal/ui/help/help_screen.dart';
import 'package:narwhal/data/database/app_database.dart';
import 'package:flutter_core_firestore_bridge/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.watch<AuthRepository>();
    final user = authRepository.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildAccountSection(context, authRepository, user),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Feedback"),
            subtitle: const Text("FAQs, documentation, and support"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("DANGER ZONE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Master Reset", style: TextStyle(color: Colors.red)),
            subtitle: const Text("Permanently erase all local and cloud (Firebase) data"),
            onTap: () => _confirmMasterReset(context, authRepository),
          ),
          const Divider(),
          const ListTile(
            title: Text("App Version"),
            trailing: Text("1.0.0"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMasterReset(BuildContext context, AuthRepository authRepository) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Master Reset"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This permanently deletes ALL tasks, projects, scratchpad notes, "
                "time logs and time blocks from this device AND from your Firebase "
                "cloud account. This cannot be undone.",
              ),
              const SizedBox(height: 16),
              const Text("Type RESET to confirm:"),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
            TextButton(
              onPressed: controller.text.trim() == "RESET" ? () => Navigator.pop(ctx, true) : null,
              child: const Text("ERASE EVERYTHING", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String message;
    try {
      // 1. Cloud data (live listeners will refresh the in-memory caches).
      await FirestoreService(authRepository).deleteAllUserData();

      // 2. Local database.
      final db = await AppDatabase.instance.database;
      for (final table in ['time_logs', 'tasks', 'project_phases', 'projects', 'categories']) {
        await db.delete(table);
      }

      // 3. Local preferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      message = "App reset complete. All data erased.";
    } catch (e) {
      message = "Reset failed: $e";
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAccountSection(BuildContext context, AuthRepository authRepository, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        if (user == null) ...[
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text("Sign in for Cloud Sync"),
            subtitle: const Text("Keep your tasks synced across devices"),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await authRepository.signInAnonymously();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Sign in failed: $e")),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await authRepository.signInWithGoogle();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Google Sign-In failed: $e")),
                  );
                }
              },
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                height: 18,
              ),
              label: const Text("Sign in with Google"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ] else
          ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.displayName ?? (user.isAnonymous ? "Anonymous User" : "User")),
            subtitle: Text(user.email ?? "ID: ${user.id}"),
            trailing: TextButton(
              onPressed: () => authRepository.signOut(),
              child: const Text("SIGN OUT", style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }
}
