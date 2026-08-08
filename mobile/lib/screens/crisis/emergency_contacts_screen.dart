import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// Stub - will be implemented in Commit 2
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contacts', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(child: Text('Coming soon...')),
    );
  }
}
