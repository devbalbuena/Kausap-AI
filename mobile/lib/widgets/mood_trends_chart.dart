import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import 'package:intl/intl.dart';

class MoodTrendsChart extends StatefulWidget {
  const MoodTrendsChart({super.key});

  @override
  State<MoodTrendsChart> createState() => _MoodTrendsChartState();
}

class _MoodTrendsChartState extends State<MoodTrendsChart> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _fetchMoodData();
  }

  Future<void> _fetchMoodData() async {
    try {
      final data = await ApiClient().get(ApiConfig.mood);
      if (mounted) {
        setState(() {
          _entries = List<Map<String, dynamic>>.from(data as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load mood trends.';
          _isLoading = false;
        });
      }
    }
  }

  /// Build spots only for the past 7 days that actually have data.
  /// X-axis index 0 = 6 days ago, index 6 = today.
  List<FlSpot> _getLast7DaySpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);

      final dayEntries = _entries.where((e) {
        final created = e['created_at'] as String? ?? '';
        return created.startsWith(dayStr);
      }).toList();

      if (dayEntries.isNotEmpty) {
        final avg = dayEntries
                .map((e) => (e['mood_level'] as num).toDouble())
                .reduce((a, b) => a + b) /
            dayEntries.length;
        // x = position (0 = oldest shown, 6 = today)
        spots.add(FlSpot((6 - i).toDouble(), avg));
      }
      // Days with no data simply have no spot — no line drawn
    }
    return spots;
  }

  /// Short label for each of the 7 x-axis positions anchored to real dates.
  String _dayLabel(int xIndex) {
    final day = DateTime.now().subtract(Duration(days: 6 - xIndex));
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return short[day.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 150,
        child: Center(child: Text(_error!, style: AppTextStyles.errorText)),
      );
    }

    final spots = _getLast7DaySpots();
    if (spots.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                'Log your mood to see your trend here 😊',
                style: AppTextStyles.subheading
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 0, bottom: 0),
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 1) return const Text('😞', style: TextStyle(fontSize: 12));
                  if (value == 2) return const Text('😟', style: TextStyle(fontSize: 12));
                  if (value == 3) return const Text('😐', style: TextStyle(fontSize: 12));
                  if (value == 4) return const Text('🙂', style: TextStyle(fontSize: 12));
                  if (value == 5) return const Text('😄', style: TextStyle(fontSize: 12));
                  return const SizedBox.shrink();
                },
                reservedSize: 32,
                interval: 1,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx > 6) return const SizedBox.shrink();
                  final isToday = idx == 6;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      isToday ? 'Today' : _dayLabel(idx),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 1,
          maxY: 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

