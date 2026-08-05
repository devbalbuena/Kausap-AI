import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

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

  List<FlSpot> _getLast7DaySpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final dayEntries = _entries.where((e) {
        final created = e['created_at'] ?? '';
        return created.startsWith(dayStr);
      }).toList();

      if (dayEntries.isNotEmpty) {
        final avg = dayEntries.map((e) => (e['mood_level'] as num).toDouble()).reduce((a, b) => a + b) / dayEntries.length;
        spots.add(FlSpot((6 - i).toDouble(), avg));
      }
    }
    return spots;
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
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No mood data for the past week.',
            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 0, bottom: 0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 1) return const Text('😞', style: TextStyle(fontSize: 12));
                  if (value == 3) return const Text('😐', style: TextStyle(fontSize: 12));
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
                  final now = DateTime.now();
                  final day = now.subtract(Duration(days: 6 - value.toInt()));
                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[day.weekday - 1],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
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
