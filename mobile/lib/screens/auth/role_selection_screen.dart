import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Legacy fallback — routes cleanly to unified LoginScreen.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
