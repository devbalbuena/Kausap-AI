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
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: KausapColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KausapColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: KausapColors.accentShadow(context),
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
                      color: KausapColors.isDark(context)
                          ? const Color(0xFF519C6B).withAlpha(40)
                          : AppColors.activityIcon,
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
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: KausapColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Based on your recent anxiety',
                          style: AppTextStyles.caption.copyWith(
                            color: KausapColors.textMuted(context),
                          ),
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
                  foregroundColor: Colors.white,
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
