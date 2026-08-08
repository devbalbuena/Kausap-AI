import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TherapistProfileSheet extends StatelessWidget {
  final String name;
  final String? role;
  final String? specialty;
  final bool isOnline;
  final String? bio;
  final List<String> languages;
  final int sessionCount;
  final double rating;

  const TherapistProfileSheet({
    super.key,
    required this.name,
    this.role,
    this.specialty,
    required this.isOnline,
    this.bio,
    this.languages = const [],
    this.sessionCount = 0,
    this.rating = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar & Status
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(name, style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (specialty != null)
                  Text(specialty!, style: AppTextStyles.subheading),
                if (specialty != null && role != null)
                  const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                if (role != null)
                  Text(role!.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      )),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Available now' : 'Currently offline',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _StatCard(label: 'Sessions', value: '$sessionCount'),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Rating', value: '⭐ $rating'),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Languages',
                    value: languages.isNotEmpty ? languages.join(', ') : 'English',
                  ),
                ],
              ),
            ),
            if (bio != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      bio!,
                      style: AppTextStyles.subheading.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Send a Message', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
