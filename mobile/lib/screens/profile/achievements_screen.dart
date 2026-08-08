import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'widgets/badge_unlocked_dialog.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final List<Map<String, dynamic>> _badges = [
    {
      'id': '1',
      'title': 'First Step',
      'description': 'Completed your first check-in.',
      'icon': Icons.star_rounded,
      'color': Colors.amber,
      'unlocked': true,
    },
    {
      'id': '2',
      'title': '3-Day Streak',
      'description': 'Checked in for 3 consecutive days.',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.deepOrange,
      'unlocked': true,
    },
    {
      'id': '3',
      'title': 'Mindful Thinker',
      'description': 'Completed 5 mindfulness exercises.',
      'icon': Icons.self_improvement_rounded,
      'color': Colors.teal,
      'unlocked': false,
    },
    {
      'id': '4',
      'title': 'Journal Keeper',
      'description': 'Wrote 10 daily journal entries.',
      'icon': Icons.edit_note_rounded,
      'color': Colors.blue,
      'unlocked': false,
    },
    {
      'id': '5',
      'title': 'Session Pro',
      'description': 'Attended 3 therapy sessions.',
      'icon': Icons.videocam_rounded,
      'color': Colors.purple,
      'unlocked': false,
    },
    {
      'id': '6',
      'title': '7-Day Streak',
      'description': 'Checked in for 7 consecutive days.',
      'icon': Icons.whatshot_rounded,
      'color': Colors.redAccent,
      'unlocked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Achievements', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(24.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _badges.length,
          itemBuilder: (context, index) {
            final badge = _badges[index];
            final bool isUnlocked = badge['unlocked'] as bool;
            
            return GestureDetector(
              onTap: isUnlocked ? () => _showBadgeDialog(badge) : null,
              child: Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnlocked ? (badge['color'] as Color).withAlpha(100) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: (badge['color'] as Color).withAlpha(30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isUnlocked ? (badge['color'] as Color).withAlpha(40) : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlocked ? (badge['icon'] as IconData) : Icons.lock_rounded,
                      color: isUnlocked ? (badge['color'] as Color) : const Color(0xFF9CA3AF),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    badge['title'] as String,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? AppColors.textPrimary : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      badge['description'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isUnlocked ? AppColors.textSecondary : const Color(0xFF9CA3AF),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ));
          },
        ),
      ),
    );
  }

  void _showBadgeDialog(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (context) => BadgeUnlockedDialog(
        title: badge['title'] as String,
        description: badge['description'] as String,
        icon: badge['icon'] as IconData,
        color: badge['color'] as Color,
      ),
    );
  }
}
