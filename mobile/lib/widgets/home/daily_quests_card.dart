import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DailyQuestsCard extends StatelessWidget {
  final List<Map<String, dynamic>> dailyQuests;
  final VoidCallback onLogMoodTap;
  final VoidCallback onWriteJournalTap;
  final VoidCallback onMindfulnessTap;
  final VoidCallback onCompletedMoodTap;

  const DailyQuestsCard({
    super.key,
    required this.dailyQuests,
    required this.onLogMoodTap,
    required this.onWriteJournalTap,
    required this.onMindfulnessTap,
    required this.onCompletedMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = dailyQuests.where((q) => q['completed'] as bool).length;
    final totalQuests = dailyQuests.length;
    final progress = totalQuests > 0 ? completedCount / totalQuests : 0.0;
    final allDone = completedCount == totalQuests;

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
              Row(
                children: [
                  const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text('Daily Quests', style: AppTextStyles.heading2),
                ],
              ),
              Text(
                '$completedCount/$totalQuests completed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: allDone ? const Color(0xFF16A34A) : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.streakTrack,
              color: allDone ? const Color(0xFF16A34A) : AppColors.primary,
              minHeight: 8,
            ),
          ),

          // Celebration Banner when all 3 quests completed
          if (allDone) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFCE8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFEF08A)),
              ),
              child: const Row(
                children: [
                  Text('🌟', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All 3 Quests Complete! Outstanding job nurturing your mind today! 🎉',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF854D0E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          ...dailyQuests.asMap().entries.map((entry) {
            final idx = entry.key;
            final quest = entry.value;
            final isCompleted = quest['completed'] as bool;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (idx == 0) {
                    if (isCompleted) {
                      onCompletedMoodTap();
                    } else {
                      onLogMoodTap();
                    }
                  } else if (idx == 1) {
                    onWriteJournalTap();
                  } else if (idx == 2) {
                    onMindfulnessTap();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? const Color(0xFF16A34A) : AppColors.divider,
                            width: 2,
                          ),
                          color: isCompleted ? const Color(0xFF16A34A) : Colors.transparent,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quest['title'] as String,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                            color: isCompleted ? const Color(0xFF16A34A) : AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isCompleted ? const Color(0xFF16A34A) : AppColors.divider,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
