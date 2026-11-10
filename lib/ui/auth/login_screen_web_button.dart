// Web implementation — uses the official GIS renderButton
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget buildGoogleSignInButton({
  required BuildContext context,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 54,
    width: double.infinity,
    child: (GoogleSignInPlatform.instance as GoogleSignInPlugin).renderButton(),
  );
}
