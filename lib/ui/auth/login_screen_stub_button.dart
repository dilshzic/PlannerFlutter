// Native (Linux/Android) stub — uses a regular button since GIS renderButton is web-only
import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required BuildContext context,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
          height: 24,
          errorBuilder: (_, _, _) => const Icon(Icons.login, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'Sign in with Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
