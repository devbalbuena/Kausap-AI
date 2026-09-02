import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeMoodTrendsCard extends StatelessWidget {
  final List<double?> weeklyMoods;
  final List<String?>? latestEmojis;
  final List<int>? logCounts;
  final double? weeklyAverage;
  final int totalLogsThisWeek;
  final VoidCallback onInsightsTap;

  const HomeMoodTrendsCard({
    super.key,
    required this.weeklyMoods,
    this.latestEmojis,
    this.logCounts,
    required this.weeklyAverage,
    required this.totalLogsThisWeek,
    required this.onInsightsTap,
  });

  static Color getMoodColor(double level) {
    if (level >= 4.5) return const Color(0xFF06B6D4); // Great (Cyan)
    if (level >= 3.5) return const Color(0xFF10B981); // Good (Emerald)
    if (level >= 2.5) return const Color(0xFFF59E0B); // Okay (Amber)
    if (level >= 1.5) return const Color(0xFFF97316); // Low (Orange)
    return const Color(0xFFEF4444);                   // Rough (Red)
  }

  static String getMoodEmoji(double level) {
    if (level >= 4.5) return '😄';
    if (level >= 3.5) return '🙂';
    if (level >= 2.5) return '😐';
    if (level >= 1.5) return '😟';
    return '😞';
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIdx = DateTime.now().weekday - 1; // Mon=0, Sun=6

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mood Trends', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Your Week at a Glance', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              if (weeklyAverage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: getMoodColor(weeklyAverage!).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: getMoodColor(weeklyAverage!).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(getMoodEmoji(weeklyAverage!), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '${weeklyAverage!.toStringAsFixed(1)} / 5',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: getMoodColor(weeklyAverage!),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // 7-Day Chart
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final mood = (i < weeklyMoods.length) ? weeklyMoods[i] : null;
                final isToday = i == todayIdx;
                final isFuture = i > todayIdx;

                final barHeight = mood != null ? ((mood / 5.0) * 65).clamp(14.0, 65.0) : 0.0;
                final color = mood != null ? getMoodColor(mood) : AppColors.primary;
                final latestEmoji = (latestEmojis != null && latestEmojis!.length > i && latestEmojis![i] != null)
                    ? latestEmojis![i]!
                    : (mood != null ? getMoodEmoji(mood) : null);
                final logCount = (logCounts != null && logCounts!.length > i) ? logCounts![i] : 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Top Emoji or Indicator
                        SizedBox(
                          height: 18,
                          child: mood != null
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      latestEmoji ?? getMoodEmoji(mood),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (logCount > 1)
                                      Positioned(
                                        top: -3,
                                        right: -7,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${logCount}x',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : (isToday
                                  ? Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                        const SizedBox(height: 4),

                        // Bar
                        Expanded(
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary.withAlpha(20)
                                  : Colors.black.withAlpha(8),
                              borderRadius: BorderRadius.circular(10),
                              border: isToday
                                  ? Border.all(color: AppColors.primary.withAlpha(80), width: 1.2)
                                  : null,
                            ),
                            child: mood != null
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                    width: double.infinity,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          color,
                                          color.withAlpha(180),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withAlpha(50),
                                          blurRadius: 4,
                                          offset: const Offset(0, -1),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: isFuture ? 4 : 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isFuture
                                          ? Colors.black.withAlpha(12)
                                          : (isToday ? AppColors.primary.withAlpha(60) : Colors.black.withAlpha(25)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Day label
                        Text(
                          days[i],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : (isFuture ? AppColors.textSecondary.withAlpha(100) : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Footer info row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  totalLogsThisWeek > 0 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: totalLogsThisWeek > 0 ? const Color(0xFF10B981) : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalLogsThisWeek > 0
                        ? '$totalLogsThisWeek ${totalLogsThisWeek == 1 ? "day" : "days"} logged this week. Keep it up!'
                        : 'No logs yet this week. Tap "How are you feeling today?" to start!',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onInsightsTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Insights',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
