import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import 'widgets/badge_unlocked_dialog.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _storage = FlutterSecureStorage();
  bool _isLoading = true;
  int _totalCheckins = 0;
  int _streak = 0;
  int _mindfulnessCount = 0;
  int _assessmentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    try {
      // 1. Fetch Mood Entries
      final moodData = await ApiClient().get(ApiConfig.mood);
      final List<dynamic> entries = moodData is List ? moodData : [];
      _totalCheckins = entries.length;

      // Calculate real streak
      final dates = <String>{};
      for (final e in entries) {
        final c = e['created_at'] as String? ?? '';
        if (c.length >= 10) dates.add(c.substring(0, 10));
      }
      int streak = 0;
      var cur = DateTime.now();
      while (true) {
        final dStr =
            '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
        if (dates.contains(dStr)) {
          streak++;
          cur = cur.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      _streak = streak;

      // 2. Fetch Activity History
      final actRaw = await _storage.read(key: 'activity_history');
      if (actRaw != null) {
        final List<dynamic> actList = jsonDecode(actRaw) as List;
        _mindfulnessCount = actList.length;
      }

      // 3. Fetch Assessment History
      final assessRaw = await _storage.read(key: 'assessment_history');
      if (assessRaw != null) {
        final List<dynamic> assessList = jsonDecode(assessRaw) as List;
        _assessmentCount = assessList.length;
      }
    } catch (_) {
      // Keep defaults
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getBadges() {
    return [
      {
        'id': '1',
        'title': 'First Step',
        'description': 'Completed your first daily check-in.',
        'icon': Icons.star_rounded,
        'color': Colors.amber,
        'current': _totalCheckins.clamp(0, 1),
        'target': 1,
        'unlocked': _totalCheckins >= 1,
        'tip': 'Log your mood once to unlock this badge.',
      },
      {
        'id': '2',
        'title': '3-Day Streak',
        'description': 'Checked in for 3 consecutive days.',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.deepOrange,
        'current': _streak.clamp(0, 3),
        'target': 3,
        'unlocked': _streak >= 3,
        'tip': 'Check in every day to keep your streak alive.',
      },
      {
        'id': '3',
        'title': 'Mindful Thinker',
        'description': 'Completed 3 mindfulness activities.',
        'icon': Icons.self_improvement_rounded,
        'color': Colors.teal,
        'current': _mindfulnessCount.clamp(0, 3),
        'target': 3,
        'unlocked': _mindfulnessCount >= 3,
        'tip': 'Complete guided breathing or meditation sessions.',
      },
      {
        'id': '4',
        'title': '7-Day Streak',
        'description': 'Checked in for 7 consecutive days.',
        'icon': Icons.whatshot_rounded,
        'color': Colors.redAccent,
        'current': _streak.clamp(0, 7),
        'target': 7,
        'unlocked': _streak >= 7,
        'tip': 'Reach a full week of consistent daily check-ins.',
      },
      {
        'id': '5',
        'title': 'Self-Discovery',
        'description': 'Completed a clinical self-assessment.',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF6366F1),
        'current': _assessmentCount.clamp(0, 1),
        'target': 1,
        'unlocked': _assessmentCount >= 1,
        'tip': 'Take a PHQ-9 or GAD-7 screener in Assessment History.',
      },
      {
        'id': '6',
        'title': 'Wellness Champion',
        'description': 'Completed 5 check-ins and 2 mindfulness exercises.',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFF10B981),
        'current': (_totalCheckins >= 5 && _mindfulnessCount >= 2) ? 1 : 0,
        'target': 1,
        'unlocked': _totalCheckins >= 5 && _mindfulnessCount >= 2,
        'tip': 'Regularly balance daily check-ins and mindfulness practice.',
      },
    ];
  }

  void _showBadgeDetail(Map<String, dynamic> badge) {
    final bool isUnlocked = badge['unlocked'] as bool;
    if (isUnlocked) {
      showDialog(
        context: context,
        builder: (_) => BadgeUnlockedDialog(
          title: badge['title'] as String,
          description: badge['description'] as String,
          icon: badge['icon'] as IconData,
          color: badge['color'] as Color,
        ),
      );
    } else {
      final current = badge['current'] as int;
      final target = badge['target'] as int;
      final color = badge['color'] as Color;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: 8),
              Text(badge['title'] as String, style: AppTextStyles.heading2.copyWith(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(badge['description'] as String, style: AppTextStyles.body.copyWith(fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                  Text('$current / $target', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x1AC0C9C2)),
                ),
                child: Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        badge['tip'] as String,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF4B5563)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badges = _getBadges();
    final unlockedCount = badges.where((b) => b['unlocked'] as bool).length;
    final totalCount = badges.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Achievements & Badges', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _loadUserProgress();
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        // Progress Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0077B6), Color(0xFF0096C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0077B6).withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text('🏆', style: TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$unlockedCount of $totalCount Badges Unlocked',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      unlockedCount == totalCount
                                          ? 'Incredible! You have unlocked all wellness badges.'
                                          : 'Keep nurturing your wellness journey to earn more.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Badges Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: badges.length,
                          itemBuilder: (context, index) {
                            final badge = badges[index];
                            final bool isUnlocked = badge['unlocked'] as bool;
                            final color = badge['color'] as Color;
                            final current = badge['current'] as int;
                            final target = badge['target'] as int;
                            final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

                            return GestureDetector(
                              onTap: () => _showBadgeDetail(badge),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUnlocked ? Colors.white : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isUnlocked ? color.withAlpha(80) : const Color(0x1AC0C9C2),
                                    width: isUnlocked ? 1.5 : 1,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: color.withAlpha(25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: isUnlocked ? color.withAlpha(35) : const Color(0xFFE5E7EB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isUnlocked ? (badge['icon'] as IconData) : Icons.lock_rounded,
                                        color: isUnlocked ? color : const Color(0xFF9CA3AF),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      badge['title'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isUnlocked ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      badge['description'] as String,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    if (!isUnlocked) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor: const Color(0xFFE5E7EB),
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$current/$target',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ] else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Unlocked ✓',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
