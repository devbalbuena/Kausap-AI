import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// Stub - will be implemented in Commit 3
class CrisisResourcesSheet extends StatelessWidget {
  const CrisisResourcesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Crisis Resources', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          const Text('Coming soon...'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
