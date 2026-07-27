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

          // ── AI Insights ───────────────────────────────────────────────────
          if (_entries.isNotEmpty) _buildInsightsCard(),
          if (_entries.isNotEmpty) const SizedBox(height: 20),

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

          // ── Mood Distribution Pie Chart ───────────────────────────────────
          _buildCard(child: _buildPieChartSection()),
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

  List<String> _generateInsights() {
    final insights = <String>[];
    if (_entries.isEmpty) return insights;

    final avg = _entries.map((e) => (e['mood_level'] as num).toDouble()).reduce((a, b) => a + b) / _entries.length;
    final latest = (_entries.first['mood_level'] as num).toInt();

    // Trend insight
    if (_entries.length >= 2) {
      final prev = (_entries[1]['mood_level'] as num).toDouble();
      final curr = (_entries[0]['mood_level'] as num).toDouble();
      if (curr > prev) {
        insights.add('📈 Your mood improved compared to your last check-in. Keep it up!');
      } else if (curr < prev) {
        insights.add('📉 Your mood dipped since your last check-in. Consider talking to someone today.');
      } else {
        insights.add('➡️ Your mood has been steady. Consistency is a good sign!');
      }
    }

    // Average insight
    if (avg >= 4.0) {
      insights.add('🌟 Your average mood this period is Great! You are thriving.');
    } else if (avg >= 3.0) {
      insights.add('😊 Your average mood is Neutral to Good. You are doing well overall.');
    } else {
      insights.add('💙 Your average mood has been low lately. Small steps matter — try a 5-minute walk or breathing exercise.');
    }

    // Frequency insight
    if (_entries.length >= 7) {
      insights.add('✅ You have logged ${_entries.length} check-ins. Great consistency building self-awareness!');
    } else if (_entries.length >= 3) {
      insights.add('📋 You have ${_entries.length} check-ins so far. Try to log daily for better insights.');
    } else {
      insights.add('🚀 You are just getting started! Log daily check-ins to unlock deeper patterns.');
    }

    // Latest mood tip
    if (latest <= 2) {
      insights.add('💬 When feeling low, try writing down 3 things you are grateful for. Small shifts help.');
    } else if (latest == 5) {
      insights.add('🎉 You are feeling great today! A great time to connect with someone or try something new.');
    }

    return insights;
  }

  Widget _buildInsightsCard() {
    final insights = _generateInsights();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(20), AppColors.primaryLight.withAlpha(15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🤖', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('AI Insights', style: AppTextStyles.heading2.copyWith(fontSize: 16, color: AppColors.primary)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Personalized observations from your mood data',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    insight,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: AppColors.textPrimary, height: 1.5),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    // Count occurrences of each mood level
    final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in _entries) {
      final level = (e['mood_level'] as num).toInt().clamp(1, 5);
      counts[level] = (counts[level] ?? 0) + 1;
    }
    final total = _entries.length;
    if (total == 0) {
      return Column(
        children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Mood Distribution', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
          ]),
          const SizedBox(height: 24),
          const Center(
            child: Text('No data yet. Complete a check-in to see your distribution.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    const pieColors = [
      Color(0xFFEF4444), // 1 - red
      Color(0xFFF97316), // 2 - orange
      Color(0xFFFACC15), // 3 - yellow
      Color(0xFF34D399), // 4 - green
      Color(0xFF3B82F6), // 5 - blue
    ];

    final sections = <PieChartSectionData>[];
    for (int i = 1; i <= 5; i++) {
      final count = counts[i] ?? 0;
      if (count == 0) continue;
      final pct = (count / total * 100);
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: pieColors[i - 1],
        title: '${pct.round()}%',
        radius: 60,
        titleStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text('Mood Distribution', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
        ]),
        const SizedBox(height: 4),
        Text('All-time breakdown of your moods',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 20),
        Row(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(5, (i) {
                  final level = i + 1;
                  final count = counts[level] ?? 0;
                  final pct = total > 0 ? (count / total * 100).round() : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: pieColors[i], shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          '${_moodLabels[level]} ${_moodNames[level]}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        Text('$pct%',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: pieColors[i])),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
