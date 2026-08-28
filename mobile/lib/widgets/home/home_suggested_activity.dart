import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../screens/activity/activity_screen.dart';
import '../../screens/activity/activity_start_screen.dart';

class HomeSuggestedActivity extends StatelessWidget {
  final VoidCallback onActivityCompleted;

  const HomeSuggestedActivity({
    super.key,
    required this.onActivityCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Activity',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.activityIcon,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      color: Color(0xFF519C6B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🧘 "5-Minute Breathing Exercise"',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Based on your recent anxiety',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  textStyle: AppTextStyles.button,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    slideRoute(ActivityStartScreen(
                      activity: activityList[0],
                    )),
                  );
                  onActivityCompleted();
                },
                child: const Text('Start Activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
