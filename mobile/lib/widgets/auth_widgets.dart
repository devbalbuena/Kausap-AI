import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shared Kausap AI logo + tagline header used on every auth screen.
class KausapHeader extends StatelessWidget {
  const KausapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Kausap AI', style: AppTextStyles.brandName),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Your Mental Wellness Companion.',
          style: AppTextStyles.subheading,
        ),
      ],
    );
  }
}

/// White card container used on auth screens.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Footer branding used at the bottom of auth screens.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Kausap AI © 2026. YOUR MENTAL CLARITY, OUR PRIORITY.',
          style: AppTextStyles.caption.copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('PRIVACY POLICY', style: AppTextStyles.caption.copyWith(fontSize: 10)),
            const SizedBox(width: 12),
            Text('TERMS OF SERVICE', style: AppTextStyles.caption.copyWith(fontSize: 10)),
            const SizedBox(width: 12),
            Text('SUPPORT', style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
