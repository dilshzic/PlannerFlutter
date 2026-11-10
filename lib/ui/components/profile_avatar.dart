import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:narwhal/ui/settings/settings_screen.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final double iconSize;

  const ProfileAvatar({
    super.key,
    this.radius = 16,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final authRepository = context.watch<AuthRepository>();
    final user = authRepository.currentUser;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: (user != null && user.photoURL != null) ? NetworkImage(user.photoURL!) : null,
          child: (user == null || user.photoURL == null)
              ? Icon(
                  user != null ? Icons.person : Icons.settings_outlined,
                  size: iconSize,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )
              : null,
        ),
      ),
    );
  }
}
