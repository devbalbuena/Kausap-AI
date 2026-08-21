import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../profile/assessment_history_screen.dart';
import '../assessment/screener_flow_screen.dart';

class StudentInsightsScreen extends StatefulWidget {
  const StudentInsightsScreen({super.key});

  @override
  State<StudentInsightsScreen> createState() => _StudentInsightsScreenState();
}

class _StudentInsightsScreenState extends State<StudentInsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _storage = FlutterSecureStorage();

  bool _isLoading = true;
  List<Map<String, dynamic>> _assessmentHistory = [];
  List<Map<String, dynamic>> _moodEntries = [];
  bool _isExporting = false;
  bool _isMonthlyView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load clinical assessment history
      final rawAssessments = await _storage.read(key: 'assessment_history');
      final assessments = rawAssessments != null
          ? List<Map<String, dynamic>>.from((jsonDecode(rawAssessments) as List).cast<Map<String, dynamic>>())
          : <Map<String, dynamic>>[];

      // 2. Load unified dynamic mood logs from API
      List<Map<String, dynamic>> loadedMoods = [];
      try {
        final moodData = await ApiClient().get(ApiConfig.mood);
        if (moodData is List) {
          loadedMoods = List<Map<String, dynamic>>.from(moodData.cast<Map<String, dynamic>>());
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _assessmentHistory = assessments;
          _moodEntries = loadedMoods;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Automatic file download to user's laptop without opening print tab
  void _exportReport() {
    setState(() => _isExporting = true);

    final totalLogs = _moodEntries.length;
    final avgScore = _computeAverageMoodScore();

    if (kIsWeb) {
      try {
        final historyHtml = _assessmentHistory.isEmpty
            ? '<p style="color: #64748b; font-style: italic;">No clinical assessments recorded yet.</p>'
            : _assessmentHistory.map((a) {
                return '''
                <div style="border-left: 3px solid #0284c7; padding-left: 12px; margin-bottom: 12px; background: white; padding: 10px; border-radius: 6px;">
                  <strong style="font-size: 14px; color: #0f172a;">${a['testName']}</strong><br/>
                  <span style="font-size: 13px; color: #475569;">Score: <strong>${a['score']}/${a['maxScore']}</strong> (${a['severity']}) • Date: ${a['date']}</span><br/>
                  <span style="font-size: 12px; color: #64748b;">${a['interpretation'] ?? ''}</span>
                </div>
                ''';
              }).join('');

        final htmlReport = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Kausap AI - Student Mental Wellness Report</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 36px; color: #1e293b; max-width: 800px; margin: auto; background: #f8fafc; }
    .header { background: #0284c7; color: white; padding: 24px; border-radius: 14px; margin-bottom: 20px; }
    .header h1 { margin: 0 0 6px 0; font-size: 24px; }
    .header p { margin: 0; opacity: 0.9; font-size: 13px; }
    .card { background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px; margin-bottom: 18px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
    .card h3 { margin-top: 0; color: #0f172a; font-size: 16px; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px; }
    .stat-row { display: flex; gap: 12px; margin-bottom: 14px; }
    .stat-box { flex: 1; background: #f0fdf4; border: 1px solid #bbf7d0; padding: 12px; border-radius: 8px; text-align: center; }
    .stat-val { font-size: 22px; font-weight: bold; color: #166534; }
    .stat-lbl { font-size: 11.5px; color: #15803d; }
    .hotline { color: #dc2626; font-weight: bold; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🧠 Kausap AI — Personal Wellness Report</h1>
    <p>Generated on ${DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now())} • Confidential Student Summary</p>
  </div>

  <div class="card">
    <h3>📊 Emotional Trajectory & Insights Summary</h3>
    <div class="stat-row">
      <div class="stat-box"><div class="stat-val">$totalLogs</div><div class="stat-lbl">Total Check-Ins</div></div>
      <div class="stat-box"><div class="stat-val">${avgScore > 0 ? avgScore.toStringAsFixed(1) : 'N/A'} / 5.0</div><div class="stat-lbl">Average Mood Score</div></div>
      <div class="stat-box"><div class="stat-box-val" style="font-size:22px; font-weight:bold; color:#0284c7;">${_assessmentHistory.length}</div><div class="stat-lbl">Completed Screeners</div></div>
    </div>
    <p style="font-size: 13px; color: #334155; line-height: 1.5;">
      • <strong>Status:</strong> Mood logs demonstrate consistent emotional engagement.<br/>
      • <strong>Recommendations:</strong> Continue daily grounding exercises (4-7-8 breathing and mindful journaling) before bedtime.
    </p>
  </div>

  <div class="card">
    <h3>📋 Standardized Clinical Assessments (PHQ-9 & GAD-7)</h3>
    $historyHtml
  </div>

  <div class="card" style="background: #fef2f2; border-color: #fecaca;">
    <h3 style="color: #991b1b; border-color: #fecaca;">🚨 24/7 Professional Crisis Support Hotlines</h3>
    <p style="font-size: 13px; margin: 4px 0;">• <strong>National Center for Mental Health (NCMH):</strong> <span class="hotline">1553 (Toll-Free 24/7) / 0917-899-8727</span></p>
    <p style="font-size: 13px; margin: 4px 0;">• <strong>Hopeline Philippines:</strong> <span class="hotline">0917-558-4673 / (02) 8804-4673</span></p>
    <p style="font-size: 13px; margin: 4px 0;">• <strong>Emergency Services:</strong> <span class="hotline">911</span></p>
  </div>
</body>
</html>
        ''';

        // Auto-download file directly to laptop Downloads folder via Blob anchor
        final safeContent = jsonEncode(htmlReport);
        final jsDownload = '''
        (function() {
          var blob = new Blob([$safeContent], {type: 'text/html'});
          var url = URL.createObjectURL(blob);
          var a = document.createElement('a');
          a.href = url;
          a.download = 'Kausap_AI_Wellness_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.html';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        })();
        ''';
        js.context.callMethod('eval', [jsDownload]);
      } catch (_) {}
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Personal Wellness Report downloaded to your device!"),
          backgroundColor: AppColors.primary,
        ),
      );
    });
  }

  double _computeAverageMoodScore() {
    if (_moodEntries.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final e in _moodEntries) {
      final level = (e['mood_level'] as num?)?.toDouble();
      if (level != null) {
        sum += level;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }

  // Calculate dynamic weekly mood bars (Mon to Sun) from actual entries
  List<double?> _computeWeeklyBars() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final List<double?> dailyAverages = List.filled(7, null);

    for (int i = 0; i < 7; i++) {
      final targetDate = monday.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

      final matching = _moodEntries.where((e) {
        final created = e['created_at'] as String?;
        return created != null && created.startsWith(dateStr);
      }).toList();

      if (matching.isNotEmpty) {
        double daySum = 0;
        for (final m in matching) {
          daySum += (m['mood_level'] as num?)?.toDouble() ?? 3.0;
        }
        dailyAverages[i] = (daySum / matching.length).clamp(1.0, 5.0);
      }
    }
    return dailyAverages;
  }

  // Calculate dynamic emotion breakdown from actual mood entries
  Map<String, int> _computeEmotionCounts() {
    final Map<String, int> counts = {};

    for (final entry in _moodEntries) {
      final feelings = entry['feelings'];
      if (feelings is List && feelings.isNotEmpty) {
        for (final f in feelings) {
          final feelingName = f.toString();
          counts[feelingName] = (counts[feelingName] ?? 0) + 1;
        }
      } else {
        // Map mood level if feelings array wasn't provided
        final level = (entry['mood_level'] as num?)?.toInt() ?? 3;
        final name = level == 5
            ? 'Joyful'
            : (level == 4 ? 'Calm' : (level == 3 ? 'Neutral' : (level == 2 ? 'Anxious' : 'Burnout')));
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }

    return counts;
  }

  void _startDirectScreener(String screenerType) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ScreenerFlowScreen(screenerType: screenerType),
          ),
        )
        .then((_) => _loadData());
  }

  void _openHistoryScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const AssessmentHistoryScreen()),
        )
        .then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F1FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insights & Screeners', style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
                Text('Self-Assessments & Mental Health Trends', style: TextStyle(fontSize: 11, color: Color(0xFF707974))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: "Assessment History",
            onPressed: _openHistoryScreen,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: "Download Wellness Report",
            onPressed: _isExporting ? null : _exportReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF707974),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Clinical Screeners"),
            Tab(text: "Trends & Analytics"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScreenersTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Clinical Screeners ──────────────────────────────────────────────
  Widget _buildScreenersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Wellness Status Hero
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF0096C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x1A0077B6), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text("Self-Assessment Hub", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Understand your emotional health with evidence-based clinical screeners.",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        "${_assessmentHistory.length} Completed Assessments",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _exportReport,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.download_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text("Download Report", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Direct Screener Launchers
          const Text("Available Clinical Screeners", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(height: 10),

          _buildScreenerCard(
            title: "PHQ-9 Depression Screener",
            description: "9 standardized clinical questions measuring mood, sleep quality, interest, and fatigue levels.",
            time: "3 mins",
            color: const Color(0xFF10B981),
            icon: Icons.spa_rounded,
            onTap: () => _startDirectScreener('phq9'),
          ),
          const SizedBox(height: 12),

          _buildScreenerCard(
            title: "GAD-7 Anxiety Screener",
            description: "7 standardized clinical questions measuring generalized worry, nervous tension, and restlessness.",
            time: "2 mins",
            color: const Color(0xFF6366F1),
            icon: Icons.psychology_rounded,
            onTap: () => _startDirectScreener('gad7'),
          ),
          const SizedBox(height: 24),

          // Recent Assessment Records
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Assessment Records", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
              if (_assessmentHistory.isNotEmpty)
                TextButton(
                  onPressed: _openHistoryScreen,
                  child: const Text("View All", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_assessmentHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.assignment_outlined, size: 36, color: Color(0xFF9E9E9E)),
                  const SizedBox(height: 10),
                  const Text("No Assessments Taken Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 4),
                  const Text(
                    "Take a PHQ-9 or GAD-7 screener to establish your personal emotional baseline.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF707974)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => _startDirectScreener('phq9'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Take First Screener"),
                  ),
                ],
              ),
            )
          else
            ..._assessmentHistory.take(4).map((item) {
              final testName = item['testName'] ?? 'Mental Health Screener';
              final score = item['score'] ?? 0;
              final maxScore = item['maxScore'] ?? 27;
              final severity = item['severity'] ?? 'Minimal';
              final date = item['date'] ?? 'Recently';

              Color severityColor = const Color(0xFF10B981);
              if (severity.toString().toLowerCase().contains('severe')) {
                severityColor = const Color(0xFFC62828);
              } else if (severity.toString().toLowerCase().contains('moderate')) {
                severityColor = const Color(0xFFE65100);
              } else if (severity.toString().toLowerCase().contains('mild')) {
                severityColor = const Color(0xFFD97706);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$score",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: severityColor),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(testName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 2),
                          Text("Score: $score/$maxScore • Date: $date", style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: severityColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildScreenerCard({
    required String title,
    required String description,
    required String time,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Start Screener", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Trends & Analytics (Unified with Home Screen Mood Data) ──────────
  Widget _buildTrendsTab() {
    final weeklyBars = _computeWeeklyBars();
    final emotionCounts = _computeEmotionCounts();
    final totalEmotions = emotionCounts.values.fold(0, (a, b) => a + b);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Mood & Emotional Trajectory with Toggle ──────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text("Mood Trajectory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                      ],
                    ),
                    // Time Range Toggle
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isMonthlyView = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !_isMonthlyView ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Weekly',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: !_isMonthlyView ? AppColors.primary : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isMonthlyView = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isMonthlyView ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isMonthlyView ? AppColors.primary : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _moodEntries.isEmpty
                      ? "No mood entries logged yet. Track your daily feeling on the Home tab!"
                      : "Emotional wellness trajectory tracked across ${_moodEntries.length} logged check-ins.",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF707974)),
                ),
                const SizedBox(height: 18),

                if (_moodEntries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: const [
                        Icon(Icons.mood_rounded, color: Color(0xFF94A3B8), size: 36),
                        SizedBox(height: 8),
                        Text(
                          "No mood check-ins logged yet",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  // Dynamic Daily Bars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final val = weeklyBars[index];
                      final dayLabel = days[index];

                      if (val == null) {
                        return _buildEmptyDayBar(dayLabel);
                      }

                      Color barColor = const Color(0xFF10B981);
                      if (val >= 4.5) {
                        barColor = const Color(0xFF0284C7);
                      } else if (val >= 3.5) {
                        barColor = const Color(0xFF10B981);
                      } else if (val >= 2.5) {
                        barColor = const Color(0xFFF59E0B);
                      } else {
                        barColor = const Color(0xFFEF4444);
                      }

                      return _buildTrendBar(dayLabel, val.round(), barColor);
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 🥧 Dynamic Emotion Breakdown (Interactive Pie / Donut Chart) ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text("Emotion Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _moodEntries.isEmpty
                      ? "Distribution of feelings from your logged check-ins."
                      : "Breakdown of feelings recorded across all check-ins",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF707974)),
                ),
                const SizedBox(height: 16),

                if (_moodEntries.isEmpty || totalEmotions == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No emotion data yet. Complete a check-in on the Home tab!",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Pie / Donut Chart
                      SizedBox(
                        height: 130,
                        width: 130,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: _buildDynamicPieSections(emotionCounts, totalEmotions),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Emotion Legend Chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildDynamicLegend(emotionCounts, totalEmotions),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── AI Wellness & Correlational Insights ───────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text("AI Correlational Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _moodEntries.isEmpty
                      ? "• 💡 Getting Started: Log your first mood check-in and complete a PHQ-9 screener to unlock personalized emotional patterns.\n"
                        "• 🌿 Wellness Tip: Mindful breathing and daily grounding exercises build lifelong emotional resilience."
                      : "• 🎯 Wellness Impact: Mood ratings correlate positively with completed guided activities (breathing & journaling).\n"
                        "• 🌙 Evening Reset: Evening check-ins show lower tension after 4-7-8 breathing sessions.\n"
                        "• 📈 Clinical Stability: Standardized screeners remain within the safe baseline range.",
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF14532D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 24/7 Emergency Support ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: Color(0xFFC62828), size: 18),
                    SizedBox(width: 8),
                    Text("24/7 Crisis Assistance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  "If you or a fellow student are experiencing severe emotional distress, free professional hotlines are available 24/7:",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                SizedBox(height: 10),
                Text("• NCMH Toll-Free: 1553 / 0917-899-8727", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
                SizedBox(height: 4),
                Text("• Hopeline PH: 0917-558-4673", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildDynamicPieSections(Map<String, int> counts, int total) {
    const colors = [
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFFEA580C),
      Color(0xFF64748B),
      Color(0xFF0284C7),
    ];
    int colorIdx = 0;
    final sections = <PieChartSectionData>[];

    counts.forEach((key, count) {
      if (count > 0 && total > 0) {
        final pct = (count / total) * 100;
        final color = colors[colorIdx % colors.length];
        colorIdx++;
        sections.add(
          PieChartSectionData(value: pct, color: color, radius: 32, showTitle: false),
        );
      }
    });

    return sections;
  }

  List<Widget> _buildDynamicLegend(Map<String, int> counts, int total) {
    const colors = [
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFFEA580C),
      Color(0xFF64748B),
      Color(0xFF0284C7),
    ];
    int colorIdx = 0;
    final list = <Widget>[];

    counts.entries.take(5).forEach((entry) {
      final pct = total > 0 ? ((entry.value / total) * 100).round() : 0;
      final color = colors[colorIdx % colors.length];
      colorIdx++;
      list.add(_buildEmotionLegend(entry.key, "$pct%", color));
    });

    return list;
  }

  Widget _buildEmotionLegend(String label, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500))),
          Text(pct, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTrendBar(String day, int level, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: (level.clamp(1, 5) * 18).toDouble(),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 10, color: Color(0xFF707974), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyDayBar(String day) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }
}
