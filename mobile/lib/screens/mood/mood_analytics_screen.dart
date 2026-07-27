import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

class MoodAnalyticsScreen extends StatefulWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  State<MoodAnalyticsScreen> createState() => _MoodAnalyticsScreenState();
}

class _MoodAnalyticsScreenState extends State<MoodAnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  // Mood label mapping
  static const Map<int, String> _moodLabels = {
    1: '😞',
    2: '😕',
    3: '😐',
    4: '🙂',
    5: '😄',
  };

  static const Map<int, String> _moodNames = {
    1: 'Very Low',
    2: 'Low',
    3: 'Neutral',
    4: 'Good',
    5: 'Great',
  };

  @override
  void initState() {
    super.initState();
    _fetchMoodData();
  }

  Future<void> _fetchMoodData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
          _error = 'Failed to load mood data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Returns last 7 days of mood data as FlSpot list.
  List<FlSpot> _getLast7DaySpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      // Find entries for this day, take the average if multiple
      final dayEntries = _entries.where((e) {
        final created = e['created_at'] ?? '';
        return created.startsWith(dayStr);
      }).toList();

      if (dayEntries.isNotEmpty) {
        final avg = dayEntries.map((e) => (e['mood_level'] as num).toDouble()).reduce((a, b) => a + b) / dayEntries.length;
        spots.add(FlSpot((6 - i).toDouble(), avg));
      }
      // Skip days with no data — the line will have gaps
    }

    return spots;
  }

  String _dayLabel(int index) {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - index));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[day.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mood Analytics',
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchMoodData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMoodData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final spots = _getLast7DaySpots();
    final hasData = spots.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchMoodData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header summary ────────────────────────────────────────────────
          _buildSummaryRow(),
          const SizedBox(height: 20),

          // ── 7-Day Line Chart ──────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('7-Day Mood Trend', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Your emotional journey this week',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                hasData
                    ? SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: const Color(0xFFE2E8F0),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, _) {
                                    final emoji = _moodLabels[value.toInt()] ?? '';
                                    return Text(emoji, style: const TextStyle(fontSize: 12));
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  getTitlesWidget: (value, _) => Text(
                                    _dayLabel(value.toInt()),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            minY: 1,
                            maxY: 5,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                                    radius: 5,
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                    strokeColor: AppColors.primary,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withAlpha(60),
                                      AppColors.primary.withAlpha(5),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 120,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sentiment_neutral_rounded, size: 40, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'No mood entries yet this week.\nComplete a daily check-in to see your trends!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Recent Entries ────────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Recent Check-ins', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                ]),
                const SizedBox(height: 12),
                if (_entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No check-ins yet. Start your first one!',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ..._entries.take(7).map((entry) => _buildEntryRow(entry)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    if (_entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final avg = _entries.map((e) => (e['mood_level'] as num).toDouble()).reduce((a, b) => a + b) / _entries.length;
    final latest = (_entries.first['mood_level'] as num).toInt();
    final totalEntries = _entries.length;

    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Average', avg.toStringAsFixed(1), _moodLabels[avg.round()] ?? '😐', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('Latest', _moodNames[latest] ?? '', _moodLabels[latest] ?? '😐', const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('Total', '$totalEntries', '📋', const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(Map<String, dynamic> entry) {
    final level = (entry['mood_level'] as num).toInt();
    final note = entry['note'] as String? ?? '';
    final createdAt = entry['created_at'] as String? ?? '';
    String formattedDate = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      formattedDate = '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(_moodLabels[level] ?? '😐', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _moodNames[level] ?? 'Neutral',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            formattedDate,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}
