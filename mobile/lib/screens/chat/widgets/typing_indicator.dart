import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// Stub - will be implemented in Commit 2
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text('typing...', style: AppTextStyles.subheading.copyWith(fontSize: 12)),
    );
  }
}
