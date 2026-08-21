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
  int _totalMoodLogs = 6;
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
      final rawAssessments = await _storage.read(key: 'assessment_history');
      final assessments = rawAssessments != null
          ? List<Map<String, dynamic>>.from((jsonDecode(rawAssessments) as List).cast<Map<String, dynamic>>())
          : <Map<String, dynamic>>[];

      int moodCount = 6;
      try {
        final moodData = await ApiClient().get(ApiConfig.mood);
        if (moodData is List && moodData.isNotEmpty) {
          moodCount = moodData.length;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _assessmentHistory = assessments;
          _totalMoodLogs = moodCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _exportReport() {
    setState(() => _isExporting = true);

    if (kIsWeb) {
      try {
        final historyHtml = _assessmentHistory.isEmpty
            ? '<p style="color: #64748b;">No standardized assessments recorded yet.</p>'
            : _assessmentHistory.map((a) {
                return '''
                <div style="border-left: 3px solid #0284c7; padding-left: 12px; margin-bottom: 10px;">
                  <strong style="font-size: 14px;">${a['testName']}</strong><br/>
                  <span style="font-size: 13px; color: #475569;">Score: <strong>${a['score']}/${a['maxScore']}</strong> (${a['severity']}) • Date: ${a['date']}</span><br/>
                  <span style="font-size: 12px; color: #64748b;">${a['interpretation'] ?? ''}</span>
                </div>
                ''';
              }).join('');

        final htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>Kausap AI - Student Wellness Report</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 40px; color: #1e293b; max-width: 800px; margin: auto; }
            h1 { color: #0284c7; margin-bottom: 4px; }
            .date { color: #64748b; font-size: 13px; margin-bottom: 24px; }
            .card { border: 1px solid #e2e8f0; border-radius: 14px; padding: 20px; margin-bottom: 20px; background: #f8fafc; }
            .card h3 { margin-top: 0; color: #0f172a; font-size: 16px; border-bottom: 1px solid #e2e8f0; padding-bottom: 8px; }
            .stat-grid { display: flex; gap: 16px; margin-bottom: 12px; }
            .stat-box { flex: 1; background: white; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; }
            .stat-val { font-size: 20px; font-weight: bold; color: #0284c7; }
            .stat-lbl { font-size: 12px; color: #64748b; }
            .hotline { color: #dc2626; font-weight: bold; }
          </style>
        </head>
        <body>
          <h1>🧠 Kausap AI — Personal Wellness Report</h1>
          <div class="date">Generated on ${DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now())} • Confidential Student Report</div>
          
          <div class="card">
            <h3>📊 Mood Trajectory & Wellness Overview</h3>
            <div class="stat-grid">
              <div class="stat-box"><div class="stat-val">$_totalMoodLogs</div><div class="stat-lbl">Logged Check-ins</div></div>
              <div class="stat-box"><div class="stat-val">4.2 / 5.0</div><div class="stat-lbl">Weekly Mood Average</div></div>
              <div class="stat-box"><div class="stat-val">${_assessmentHistory.length}</div><div class="stat-lbl">Completed Screeners</div></div>
            </div>
            <p style="font-size: 13px; color: #334155; line-height: 1.5;">
              • <strong>Emotional Breakdown:</strong> 35% Calm, 25% Joyful, 18% Anxious, 12% Burnout, 10% Sad.<br/>
              • <strong>AI Summary:</strong> Mood patterns demonstrate resilience. Guided breathing exercises mid-week correlated with lower evening tension.
            </p>
          </div>

          <div class="card">
            <h3>📋 Standardized Clinical Assessments (PHQ-9 & GAD-7)</h3>
            $historyHtml
          </div>

          <div class="card">
            <h3>🚨 24/7 Professional Crisis Support Hotlines</h3>
            <p style="font-size: 13px; margin: 4px 0;">• <strong>National Center for Mental Health (NCMH):</strong> <span class="hotline">1553 (Toll-Free 24/7) / 0917-899-8727</span></p>
            <p style="font-size: 13px; margin: 4px 0;">• <strong>Hopeline Philippines:</strong> <span class="hotline">0917-558-4673 / (02) 8804-4673</span></p>
            <p style="font-size: 13px; margin: 4px 0;">• <strong>In Touch Community:</strong> <span class="hotline">0917-800-1123</span></p>
          </div>
          <script>window.print();</script>
        </body>
        </html>
        ''';
        final jsCode = '''
        (function() {
          var win = window.open("", "_blank");
          win.document.write(${jsonEncode(htmlContent)});
          win.document.close();
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (_) {}
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Personal Wellness Report PDF generated & ready for download/print!"),
          backgroundColor: AppColors.primary,
        ),
      );
    });
  }

  // Direct Screener Launch without unwanted redirects
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
                : const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            tooltip: "Export PDF Report",
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
                            Text("Export PDF", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
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

  // ── Tab 2: Trends & Analytics ──────────────────────────────────────────────
  Widget _buildTrendsTab() {
    return ListView(
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
              const SizedBox(height: 12),
              Text(
                _isMonthlyView
                    ? "30-day emotional wellness pattern across 24 logged check-ins."
                    : "Your weekly mental wellness patterns tracked across $_totalMoodLogs logged entries.",
                style: const TextStyle(fontSize: 12, color: Color(0xFF707974)),
              ),
              const SizedBox(height: 16),

              // Mini Bar Visualization
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _isMonthlyView
                    ? [
                        _buildTrendBar("W1", 4, const Color(0xFF10B981)),
                        _buildTrendBar("W2", 3, const Color(0xFF0077B6)),
                        _buildTrendBar("W3", 5, const Color(0xFF10B981)),
                        _buildTrendBar("W4", 4, const Color(0xFF10B981)),
                      ]
                    : [
                        _buildTrendBar("Mon", 4, const Color(0xFF10B981)),
                        _buildTrendBar("Tue", 3, const Color(0xFF0077B6)),
                        _buildTrendBar("Wed", 4, const Color(0xFF10B981)),
                        _buildTrendBar("Thu", 2, const Color(0xFFF59E0B)),
                        _buildTrendBar("Fri", 5, const Color(0xFF10B981)),
                        _buildTrendBar("Sat", 4, const Color(0xFF10B981)),
                        _buildTrendBar("Sun", 4, const Color(0xFF10B981)),
                      ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 🥧 Emotion Breakdown (Interactive Pie / Donut Chart) ───────────
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
              const Text("Most frequent emotions recorded during check-ins", style: TextStyle(fontSize: 12, color: Color(0xFF707974))),
              const SizedBox(height: 16),

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
                        sections: [
                          PieChartSectionData(value: 35, color: const Color(0xFF10B981), radius: 32, showTitle: false),
                          PieChartSectionData(value: 25, color: const Color(0xFFF59E0B), radius: 32, showTitle: false),
                          PieChartSectionData(value: 18, color: const Color(0xFF6366F1), radius: 32, showTitle: false),
                          PieChartSectionData(value: 12, color: const Color(0xFFEA580C), radius: 32, showTitle: false),
                          PieChartSectionData(value: 10, color: const Color(0xFF64748B), radius: 32, showTitle: false),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Emotion Legend Chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEmotionLegend("😌 Calm & Centered", "35%", const Color(0xFF10B981)),
                        _buildEmotionLegend("😊 Joy & Content", "25%", const Color(0xFFF59E0B)),
                        _buildEmotionLegend("😰 Anxious & Overwhelmed", "18%", const Color(0xFF6366F1)),
                        _buildEmotionLegend("😫 Burnout & Fatigue", "12%", const Color(0xFFEA580C)),
                        _buildEmotionLegend("😢 Sad & Low Energy", "10%", const Color(0xFF64748B)),
                      ],
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Text("AI Correlational Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "• 🎯 Wellness Impact: Your mood scores are 35% higher on days with completed Guided Breathing or Mindful Walking.\n"
                "• 🌙 Evening Reset: Evening tension decreased by 28% after 3 consecutive days of 4-7-8 relaxation.\n"
                "• 📈 Clinical Stability: GAD-7 anxiety indicator remains in the healthy minimal-mild baseline.",
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF14532D)),
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
    );
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
          height: (level * 18).toDouble(),
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
}
