import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:flutter_core_entities/app_user.dart';

class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;
  final Widget? loadingChild;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
    this.loadingChild,
  });

  @override
  Widget build(BuildContext context) {
    final authRepository = context.watch<AuthRepository>();

    return StreamBuilder<AppUser?>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingChild ?? const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return authenticatedChild;
        }

        return unauthenticatedChild;
      },
    );
  }
}
