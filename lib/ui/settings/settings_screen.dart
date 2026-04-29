import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planner/data/repository/auth_repository.dart';

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
          const ListTile(
            title: Text("App Version"),
            trailing: Text("1.0.0"),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthRepository authRepository, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        if (user == null)
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text("Sign in for Cloud Sync"),
            subtitle: const Text("Keep your tasks synced across devices"),
            onTap: () async {
              try {
                await authRepository.signInAnonymously();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Sign in failed: $e")),
                );
              }
            },
          )
        else
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text("Signed in Anonymously"),
            subtitle: Text("ID: ${user.uid}"),
            trailing: TextButton(
              onPressed: () => authRepository.signOut(),
              child: const Text("SIGN OUT", style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }
}
