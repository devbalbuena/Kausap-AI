import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Placeholder Home Screen — used until full home UI is built.
/// Shows "Welcome, [first_name]!" and the user's role.
class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user['first_name'] ?? 'User';
    final role = user['role'] ?? 'client';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () {
              // Logout handled in next phase
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'professional'
                      ? Icons.psychology_rounded
                      : Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, $firstName!',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role == 'professional' ? '🩺 Professional' : '💚 Client',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Full home screen coming soon.',
                style: AppTextStyles.subheading,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
