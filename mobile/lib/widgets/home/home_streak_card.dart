import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeStreakCard extends StatelessWidget {
  final int streak;
  final int goal;

  const HomeStreakCard({
    super.key,
    required this.streak,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final clampedStreak = streak.clamp(0, goal);
    final progress = goal > 0 ? clampedStreak / goal : 0.0;

    String rankBadge = '🌱 Novice Explorer';
    if (streak >= 14) {
      rankBadge = '👑 Wellness Legend';
    } else if (streak >= 7) {
      rankBadge = '⚡ Zen Champion';
    } else if (streak >= 3) {
      rankBadge = '🔥 Mindful Trailblazer';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(streak == 0 ? '🌱' : '🔥', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        streak == 0 ? 'Start your streak today!' : '$streak Day Streak',
                        style: AppTextStyles.heading2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  rankBadge,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            streak == 0
                ? 'Check in daily to build your mental wellness momentum'
                : '$clampedStreak of $goal days towards your monthly milestone',
            style: AppTextStyles.subheading.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.streakTrack,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
