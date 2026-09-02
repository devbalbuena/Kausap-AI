import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../profile/profile_screen.dart';
import '../profile/assessment_history_screen.dart';
import '../assessment/screener_flow_screen.dart';
import '../crisis/crisis_resources_sheet.dart';
import '../chat/chatbot_screen.dart';
import '../activity/activity_screen.dart';
import '../../widgets/home/mood_influence_sheet.dart';
import '../../services/offline_mood_queue.dart';

class StudentInsightsScreen extends StatefulWidget {
  final int? refreshTrigger;
  const StudentInsightsScreen({super.key, this.refreshTrigger});

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
  void didUpdateWidget(covariant StudentInsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Sync any pending offline moods
      try {
        await OfflineMoodQueue().syncPendingMoods();
      } catch (_) {}

      // 2. Load clinical assessment history
      final rawAssessments = await _storage.read(key: 'assessment_history');
      final assessments = rawAssessments != null
          ? List<Map<String, dynamic>>.from((jsonDecode(rawAssessments) as List).cast<Map<String, dynamic>>())
          : <Map<String, dynamic>>[];

      // 3. Load unified dynamic mood logs from API
      List<Map<String, dynamic>> loadedMoods = [];
      try {
        final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
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
            ? '<p style="color: #64748b; font-style: italic;">No self-check-ins recorded yet.</p>'
            : _assessmentHistory.map((a) {
                return '''
                <div style="border-left: 3px solid #0284c7; padding-left: 12px; margin-bottom: 12px; background: white; padding: 12px; border-radius: 8px;">
                  <strong style="font-size: 14px; color: #0f172a;">${a['testName']}</strong><br/>
                  <span style="font-size: 13px; color: #475569;">Score: <strong>${a['score']}/${a['maxScore']}</strong> (${a['severity']}) • Date: ${a['date']}</span><br/>
                  <p style="font-size: 12px; color: #1e293b; margin: 4px 0 2px 0;"><strong>Insight:</strong> ${a['empatheticInsight'] ?? a['interpretation'] ?? ''}</p>
                  ${a['progressNote'] != null ? '<span style="font-size: 11px; color: #0284c7;">${a['progressNote']}</span>' : ''}
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
      <div class="stat-box"><div class="stat-box-val" style="font-size:22px; font-weight:bold; color:#0284c7;">${_assessmentHistory.length}</div><div class="stat-lbl">Completed Check-Ins</div></div>
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

  // Calculate overall all-time average mood score
  double _computeAverageMoodScore() {
    if (_moodEntries.isEmpty) return 0.0;
    double sum = 0;
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

  // Calculate dynamic weekly average (matching Home dashboard)
  double _computeThisWeekAverage() {
    final weeklyBars = _computeWeeklyBars();
    double sum = 0;
    int count = 0;
    for (final val in weeklyBars) {
      if (val != null) {
        sum += val;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }

  // Robust date parser that handles UTC strings and converts to local timezone
  DateTime? _parseDateLocal(dynamic created) {
    if (created == null) return null;
    try {
      final str = created.toString();
      final dt = DateTime.parse(str);
      return dt.isUtc ? dt.toLocal() : (str.endsWith('Z') || str.contains('+') ? dt.toLocal() : DateTime.parse('${str}Z').toLocal());
    } catch (_) {
      return null;
    }
  }

  // Robust feelings & emotions list extractor (handles List, String, JSON-encoded List, and CSV)
  static String _cleanEmotionText(String input) {
    var text = input
        .replaceAll(r'\ud83d\udcda', '📚')
        .replaceAll(r'\u26a1', '⚡')
        .replaceAll(r'\ud83d\ude34', '😴')
        .replaceAll(r'\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc67', '👨‍👩‍👧')
        .replaceAll(r'\ud83d\udc65', '👥')
        .replaceAll(r'\ud83d\udcb8', '💸')
        .replaceAll(r'\ud83c\udf3f', '🌿')
        .replaceAll(r'\u2764\ufe0f', '❤️')
        .replaceAll(r'\u2764', '❤️')
        .replaceAll(r'\u2615', '☕')
        .replaceAll(r'\ud83e\uddd8', '🧘')
        .replaceAll(r'\ud83c\udfe0', '🏡')
        .replaceAll(r'\ud83e\udde0', '🧠')
        .replaceAll(r'\u2728', '✨');
    try {
      text = text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
        final hex = match.group(1);
        if (hex != null) {
          final code = int.parse(hex, radix: 16);
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      });
    } catch (_) {}
    return text.replaceAll(r'\', '').replaceAll('"', '').replaceAll("'", '').trim();
  }

  List<String> _extractEmotionsList(dynamic raw) {
    if (raw == null) return [];
    List<String> list = [];
    if (raw is List) {
      list = raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (raw is String) {
      final str = raw.trim();
      if (str.isEmpty) return [];
      if (str.startsWith('[') && str.endsWith(']')) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is List) {
            list = decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
          }
        } catch (_) {}
      }
      if (list.isEmpty) {
        if (str.contains(',')) {
          list = str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } else {
          list = [str];
        }
      }
    } else {
      list = [raw.toString().trim()];
    }
    return list.map((e) => _cleanEmotionText(e)).where((s) => s.isNotEmpty).toList();
  }

  int _computeThisWeekLogsCount() {
    final weeklyBars = _computeWeeklyBars();
    return weeklyBars.where((v) => v != null).length;
  }

  // Calculate dynamic weekly mood bars (Mon to Sun) from actual entries with timezone accuracy
  List<double?> _computeWeeklyBars() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final List<double?> dailyAverages = List.filled(7, null);

    for (int i = 0; i < 7; i++) {
      final targetDate = monday.add(Duration(days: i));

      final matching = _moodEntries.where((e) {
        final dt = _parseDateLocal(e['created_at']);
        return dt != null &&
            dt.year == targetDate.year &&
            dt.month == targetDate.month &&
            dt.day == targetDate.day;
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
      final feelings = _extractEmotionsList(entry['feelings'] ?? entry['emotions']);
      for (final f in feelings) {
        counts[f] = (counts[f] ?? 0) + 1;
      }
    }

    return counts;
  }

  // Calculate dynamic stressors & campus triggers strictly from actual entries
  Map<String, int> _computeTriggerCounts() {
    final Map<String, int> counts = {};
    for (final entry in _moodEntries) {
      final triggers = _extractEmotionsList(entry['emotions'] ?? entry['feelings'] ?? entry['reasons'] ?? entry['triggers'] ?? entry['context_tags']);
      for (final t in triggers) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts;
  }

  // Dynamic mood stability variance
  String _computeStabilityStatus() {
    if (_moodEntries.length < 2) return "🌱 Setting Baseline";
    final avg = _computeAverageMoodScore();
    double varianceSum = 0;
    for (final e in _moodEntries) {
      final lvl = (e['mood_level'] as num?)?.toDouble() ?? avg;
      varianceSum += (lvl - avg) * (lvl - avg);
    }
    final stdDev = varianceSum / _moodEntries.length;
    if (stdDev < 0.4) {
      return "🌱 Emotionally Steady";
    } else if (stdDev < 1.2) {
      return "🌊 Normal Weekly Waves";
    } else {
      return "⚡ Dynamic Shifts (Exam Week)";
    }
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
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser ?? {};
                final name = user['first_name'] ?? 'U';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                final avatarUrl = user['avatar_url'] as String?;
                final avatar = CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                      ? Text(
                          initial,
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                        )
                      : null,
                );
                return PopupMenuButton<String>(
                  offset: const Offset(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  child: avatar,
                  onSelected: (value) {
                    if (value == 'profile') {
                      HapticService.lightTap();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary.withAlpha(20),
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                                ? Text(initial,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                              const Text('View Profile & Settings', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
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
            Tab(text: "Wellness Check-Ins"),
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

  // ── Tab 1: Wellness Check-Ins ──────────────────────────────────────────────
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
                    Icon(Icons.spa_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text("Self-Reflection Hub", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Understand how you've been feeling with quick, confidential self-check-ins.",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        "${_assessmentHistory.length} Completed Check-Ins",
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

          // Available Check-Ins
          const Text("Available Self-Check-Ins", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(height: 10),

          _buildScreenerCard(
            title: "Mood & Energy Check-In (PHQ-9)",
            description: "Reflect on your mood, sleep, focus, and energy levels over the last 2 weeks.",
            time: "3 mins",
            color: const Color(0xFF10B981),
            icon: Icons.wb_sunny_rounded,
            onTap: () => _startDirectScreener('phq9'),
          ),
          const SizedBox(height: 12),

          _buildScreenerCard(
            title: "Stress & Peace of Mind Check-In (GAD-7)",
            description: "Check your daily worry, nervousness, and tension levels to find balance.",
            time: "2 mins",
            color: const Color(0xFF6366F1),
            icon: Icons.waves_rounded,
            onTap: () => _startDirectScreener('gad7'),
          ),
          const SizedBox(height: 12),

          _buildScreenerCard(
            title: "Campus Burnout & Fatigue Check-In",
            description: "Assess thesis pressure, deadline fatigue, and academic overwhelm.",
            time: "2 mins",
            color: const Color(0xFFD97706),
            icon: Icons.school_rounded,
            onTap: () => _startDirectScreener('burnout'),
          ),
          const SizedBox(height: 24),

          // Recent Assessment Records
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Check-In Records", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
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
                  const Text("No Check-Ins Taken Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 4),
                  const Text(
                    "Take a quick check-in above to establish your personal emotional baseline.",
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
                    child: const Text("Take First Check-In"),
                  ),
                ],
              ),
            )
          else
            ..._assessmentHistory.take(4).map((item) {
              final testName = item['testName'] ?? 'Self Check-In';
              final score = item['score'] ?? 0;
              final maxScore = item['maxScore'] ?? 27;
              final severity = item['severity'] ?? 'Minimal';
              final date = item['date'] ?? 'Recently';
              final progressNote = item['progressNote'] as String?;
              final empatheticInsight = item['empatheticInsight'] as String?;

              Color severityColor = const Color(0xFF10B981);
              if (severity.toString().toLowerCase().contains('severe') || severity.toString().toLowerCase().contains('high')) {
                severityColor = const Color(0xFFC62828);
              } else if (severity.toString().toLowerCase().contains('moderate')) {
                severityColor = const Color(0xFFE65100);
              } else if (severity.toString().toLowerCase().contains('mild')) {
                severityColor = const Color(0xFFD97706);
              }

              return GestureDetector(
                onTap: () => _showPastAssessmentModal(item, severityColor),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EAED)),
                    boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      if (progressNote != null && progressNote.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            progressNote,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                      ] else if (empatheticInsight != null && empatheticInsight.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            empatheticInsight,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF475569)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showPastAssessmentModal(Map<String, dynamic> item, Color severityColor) {
    final testName = item['testName'] ?? 'Self Check-In';
    final score = item['score'] ?? 0;
    final maxScore = item['maxScore'] ?? 27;
    final severity = item['severity'] ?? 'Minimal';
    final date = item['date'] ?? 'Recently';
    final progressNote = item['progressNote'] as String? ?? 'Personal check-in record.';
    final empatheticInsight = item['empatheticInsight'] as String? ?? (item['interpretation'] as String? ?? 'Take time to reflect and practice gentle self-care.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bookmark_outline_rounded, color: severityColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(testName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                        Text('Recorded on $date', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: severityColor.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Text('$score / $maxScore', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 20, color: severityColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(severity, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: severityColor)),
                          const Text('Personal self-assessment score', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💡 ', style: TextStyle(fontSize: 13)),
                        Text('Empathetic Insight', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF3730A3))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(empatheticInsight, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF312E81), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(progressNote, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF334155))),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActivityScreen()),
                        );
                      },
                      icon: const Icon(Icons.self_improvement_rounded, size: 16),
                      label: const Text('Calm Now 🌿', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Talk to AI 💬', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF2C3E50))),
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
              child: const Text("Start Check-In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Trends & Analytics (Unified Real-Time Dynamic Mood & Health Data) ──
  Widget _buildTrendsTab() {
    final emotionCounts = _computeEmotionCounts();
    final totalEmotions = emotionCounts.values.fold(0, (a, b) => a + b);
    final avgScore = _isMonthlyView ? _computeAverageMoodScore() : _computeThisWeekAverage();
    final totalLogs = _isMonthlyView ? _moodEntries.length : _computeThisWeekLogsCount();
    final topEmotion = _getDominantEmotion(emotionCounts);
    final triggerCounts = _computeTriggerCounts();
    final weeklySpots = _computeWeeklySpots();
    final monthlySpots = _computeMonthlySpots();
    final stabilityStatus = _computeStabilityStatus();
    final dominantColor = _getEmotionColor(topEmotion);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── 1. Top Key Stat Metrics Cards ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  emoji: _getMoodEmoji(avgScore > 0 ? avgScore : 3.0),
                  value: avgScore > 0 ? "${avgScore.toStringAsFixed(1)} / 5.0" : "— / 5.0",
                  label: _isMonthlyView ? "All-Time Mood" : "Weekly Mood",
                  bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  accentColor: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  emoji: _getEmotionEmoji(topEmotion),
                  value: topEmotion ?? "—",
                  label: "Top Factor",
                  bgGradient: topEmotion != null
                      ? [dominantColor.withAlpha(20), dominantColor.withAlpha(45)]
                      : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                  accentColor: dominantColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  emoji: "📋",
                  value: "$totalLogs",
                  label: _isMonthlyView ? "Total Logs" : "Logs This Week",
                  bgGradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                  accentColor: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 2. Emotional Trajectory Chart (Weekly vs Monthly Line Curve) ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Mood Trajectory",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    // Weekly / Monthly Toggle Pill
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isMonthlyView = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: !_isMonthlyView ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: !_isMonthlyView
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(
                                'Weekly',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: !_isMonthlyView ? AppColors.primary : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isMonthlyView = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isMonthlyView ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: _isMonthlyView
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(
                                'Monthly',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isMonthlyView
                            ? "30-day emotional wellness progression over 4 weeks."
                            : "7-day day-by-day emotional progression for this week.",
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stabilityStatus,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Beautiful Smooth Line Chart with Touch Tooltips
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      // Y-Axis Mood Emojis
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("😄", style: TextStyle(fontSize: 14)),
                          Text("🙂", style: TextStyle(fontSize: 14)),
                          Text("😐", style: TextStyle(fontSize: 14)),
                          Text("😟", style: TextStyle(fontSize: 14)),
                          Text("😞", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Chart Canvas
                      Expanded(
                        child: (_isMonthlyView ? monthlySpots.isEmpty : weeklySpots.isEmpty)
                            ? const Center(
                                child: Text(
                                  "No logs recorded for this period.\nCheck in on the Home tab! 😊",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  minY: 1.0,
                                  maxY: 5.0,
                                  minX: 0,
                                  maxX: _isMonthlyView ? 3 : 6,
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (_) => const Color(0xFF0F172A),
                                      tooltipRoundedRadius: 8,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                          final dayName = _isMonthlyView
                                              ? 'Wk ${(spot.x.toInt() + 1)}'
                                              : (spot.x.toInt() < days.length ? days[spot.x.toInt()] : 'Day');
                                          final score = spot.y;
                                          final emoji = _getMoodEmoji(score);
                                          return LineTooltipItem(
                                            '$dayName: $emoji ${score.toStringAsFixed(1)}\n',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                            children: [
                                              TextSpan(
                                                text: score >= 4.0
                                                    ? 'Positive Energy'
                                                    : (score >= 3.0 ? 'Steady Balance' : 'Heavier Load'),
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1.0,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: const Color(0xFFF1F5F9),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (_isMonthlyView) {
                                            const labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
                                            if (idx >= 0 && idx < labels.length) {
                                              return Text(
                                                labels[idx],
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              );
                                            }
                                          } else {
                                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                            if (idx >= 0 && idx < days.length) {
                                              return Text(
                                                days[idx],
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: idx == (DateTime.now().weekday - 1)
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: idx == (DateTime.now().weekday - 1)
                                                      ? AppColors.primary
                                                      : const Color(0xFF64748B),
                                                ),
                                              );
                                            }
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _isMonthlyView ? monthlySpots : weeklySpots,
                                      isCurved: true,
                                      curveSmoothness: 0.25,
                                      color: AppColors.primary,
                                      barWidth: 3.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4.5,
                                            color: Colors.white,
                                            strokeWidth: 3,
                                            strokeColor: AppColors.primary,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withAlpha(50),
                                            AppColors.primary.withAlpha(2),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // 7-Day Day-by-Day Synchronized Rhythm Strip (Matching Home Dashboard)
                if (!_isMonthlyView) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final weeklyBars = _computeWeeklyBars();
                        final mood = weeklyBars[i];
                        final isToday = i == (DateTime.now().weekday - 1);
                        final moodColor = mood != null ? _getEmotionColor(_getMoodEmoji(mood)) : const Color(0xFF94A3B8);

                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                mood != null ? _getMoodEmoji(mood) : '—',
                                style: TextStyle(
                                  fontSize: mood != null ? 13 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: mood != null ? Colors.black : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                mood != null ? mood.toStringAsFixed(1) : '·',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: mood != null ? moodColor : const Color(0xFFCBD5E1),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                days[i],
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                  color: isToday ? AppColors.primary : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 3. Emotion Frequency Breakdown (Interactive Donut Chart) ──────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Emotion Breakdown",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  totalEmotions > 0
                      ? "All-time breakdown of recorded feelings ($totalEmotions data point${totalEmotions == 1 ? '' : 's'})"
                      : "All-time breakdown of recorded feelings (0 tags recorded)",
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                if (_moodEntries.isEmpty || totalEmotions == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text("🏷️", style: TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "No factor tags recorded yet. When checking in on the Home tab, select what influences your day to see your visual breakdown here!",
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      // Donut Chart
                      SizedBox(
                        height: 135,
                        width: 135,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(enabled: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 32,
                            sections: _buildDynamicPieSections(emotionCounts, totalEmotions),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Legend Items
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

          // ── 4. Dynamic Influencing Factors & Campus Triggers ───────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Top Influencing Factors",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Key life and academic contexts linked to your check-ins:",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                if (triggerCounts.isNotEmpty)
                  _buildInfluencingFactorsCloud(triggerCounts)
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Text("🏷️", style: TextStyle(fontSize: 18)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "No mood factors tagged yet. Select what influences your day when checking in on the Home tab, or tap any recent check-in below to tag it!",
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 5. Real-Time Dynamic AI Wellness Observations & Actionable Care
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "AI Wellness Observations",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._generateDynamicObservations(avgScore, topEmotion, _moodEntries.length),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFDCFCE7), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticService.lightTap();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ActivityScreen()),
                          );
                        },
                        icon: const Icon(Icons.self_improvement_rounded, size: 15),
                        label: const Text("Calm Now 🌿", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF166534),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          backgroundColor: Colors.white.withAlpha(200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticService.lightTap();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                        label: const Text("Talk to AI 💬", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 6. Chronological Recent Mood Check-ins Log ─────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Recent Check-ins",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${_moodEntries.length} logs (tap to view)",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_moodEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        "No check-in history yet. Log your feeling today!",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                else
                  ..._buildRecentCheckinRows(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 7. 24/7 Crisis Support ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              onTap: () {
                HapticService.lightTap();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CrisisResourcesSheet(),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "24/7 Crisis Support & Hotlines",
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Tap to access full directory of campus guidance & national emergency lines:",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    SizedBox(height: 8),
                    Text("• FSUU Guidance: (085) 342-1830", style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    SizedBox(height: 4),
                    Text("• NCMH Toll-Free: 1553 / 0917-899-8727", style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    SizedBox(height: 4),
                    Text("• Hopeline PH: 0917-558-4673", style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String emoji,
    required String value,
    required String label,
    required List<Color> bgGradient,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: accentColor.withAlpha(190),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluencingFactorsCloud(Map<String, int> triggers) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: triggers.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.key,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${e.value}",
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String? _getDominantEmotion(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    String dominant = counts.keys.first;
    int maxCount = -1;
    counts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        dominant = k;
      }
    });
    return dominant;
  }

  Color _getEmotionColor(String? emotion) {
    if (emotion == null) return const Color(0xFF64748B);
    final lower = emotion.toLowerCase();
    if (lower.contains('burnout') || lower.contains('exhaust') || lower.contains('drain') || lower.contains('thesis') || lower.contains('deadline')) {
      return const Color(0xFFE11D48); // Rose / Coral
    } else if (lower.contains('anxious') || lower.contains('stress') || lower.contains('worry') || lower.contains('frustrat') || lower.contains('rough') || lower.contains('low') || lower.contains('fatigue') || lower.contains('sleep') || lower.contains('finance')) {
      return const Color(0xFFD97706); // Warm Amber
    } else if (lower.contains('joy') || lower.contains('great') || lower.contains('happy') || lower.contains('grateful') || lower.contains('reliev') || lower.contains('friend') || lower.contains('family')) {
      return const Color(0xFF10B981); // Emerald Green
    } else if (lower.contains('calm') || lower.contains('peace') || lower.contains('good') || lower.contains('routine') || lower.contains('well-being')) {
      return const Color(0xFF06B6D4); // Cyan / Teal
    }
    return const Color(0xFF0284C7); // Sky Blue (Balanced / Neutral)
  }

  String _getEmotionEmoji(String? emotion) {
    if (emotion == null) return "🌱";
    final lower = emotion.toLowerCase();
    if (lower.contains('academic') || lower.contains('thesis')) return "📚";
    if (lower.contains('exam') || lower.contains('deadline')) return "⚡";
    if (lower.contains('sleep') || lower.contains('fatigue')) return "😴";
    if (lower.contains('family')) return "👨‍👩‍👧";
    if (lower.contains('friend') || lower.contains('social')) return "👥";
    if (lower.contains('allowance') || lower.contains('finance')) return "💸";
    if (lower.contains('health') || lower.contains('energy')) return "🌿";
    if (lower.contains('relationship')) return "❤️";
    if (lower.contains('routine') || lower.contains('focus')) return "☕";
    if (lower.contains('burnout') || lower.contains('exhaust')) return "🔥";
    if (lower.contains('anxious') || lower.contains('stress')) return "🌊";
    if (lower.contains('joy') || lower.contains('great')) return "✨";
    if (lower.contains('calm') || lower.contains('peace')) return "🌿";
    return "🌱";
  }

  String _getMoodEmoji(double level) {
    if (level >= 4.5) return "😄";
    if (level >= 3.5) return "🙂";
    if (level >= 2.5) return "😐";
    if (level >= 1.5) return "😟";
    return "😞";
  }

  List<FlSpot> _computeWeeklySpots() {
    final weeklyBars = _computeWeeklyBars();
    final List<FlSpot> spots = [];

    for (int i = 0; i < 7; i++) {
      final val = weeklyBars[i];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }
    return spots;
  }

  List<FlSpot> _computeMonthlySpots() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    for (int week = 3; week >= 0; week--) {
      final start = now.subtract(Duration(days: (week + 1) * 7));
      final end = now.subtract(Duration(days: week * 7));

      final matching = _moodEntries.where((e) {
        final dt = _parseDateLocal(e['created_at']);
        if (dt == null) return false;
        return dt.isAfter(start) && dt.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (matching.isNotEmpty) {
        double sum = 0;
        for (final m in matching) {
          sum += (m['mood_level'] as num?)?.toDouble() ?? 3.0;
        }
        final avg = sum / matching.length;
        spots.add(FlSpot((3 - week).toDouble(), avg.clamp(1.0, 5.0)));
      }
    }
    return spots;
  }

  List<Widget> _generateDynamicObservations(double avg, String? topEmotion, int count) {
    if (count == 0) {
      return [
        const Text(
          "• 💡 Getting Started: Log your first mood check-in to generate personalized AI trends.\n"
          "• 🌿 Wellness Tip: Mindful breathing and daily grounding exercises build lifelong resilience.",
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.5, color: Color(0xFF14532D)),
        )
      ];
    }

    final List<Widget> items = [];

    // 1. Dominant state observation
    if (topEmotion != null) {
      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("• ", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                "Primary Context: Your most frequent influencing factor is $topEmotion across your logged check-ins.",
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: Color(0xFF14532D)),
              ),
            ),
          ],
        ),
      ));
    } else {
      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("• ", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
            const Expanded(
              child: Text(
                "Context Tip: Tagging reasons (like Academics or Sleep) during check-ins unlocks deeper AI wellness patterns.",
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: Color(0xFF14532D)),
              ),
            ),
          ],
        ),
      ));
    }

    // 2. Average trajectory observation
    final statusText = avg >= 3.5
        ? "Positive Stability: Your average mood score is ${avg.toStringAsFixed(1)}/5.0, reflecting strong emotional health."
        : (avg >= 2.5
            ? "Moderate Rhythm: Your average mood is ${avg.toStringAsFixed(1)}/5.0 with normal weekly fluctuations."
            : "Self-Care Advisory: Your average score is ${avg.toStringAsFixed(1)}/5.0. Consider taking extra breaks and using guided breathing.");

    items.add(Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: Color(0xFF14532D)),
            ),
          ),
        ],
      ),
    ));

    // 3. Consistency habit
    items.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            "Tracking Habit: You have accumulated $count total check-in${count == 1 ? '' : 's'}. Consistent tracking enhances self-awareness.",
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: Color(0xFF14532D)),
          ),
        ),
      ],
    ));

    return items;
  }

  List<Widget> _buildRecentCheckinRows() {
    final sorted = List<Map<String, dynamic>>.from(_moodEntries);
    sorted.sort((a, b) {
      final aDate = a['created_at']?.toString() ?? '';
      final bDate = b['created_at']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });

    final top5 = sorted.take(5).toList();

    return top5.map((item) {
      final level = (item['mood_level'] as num?)?.toInt() ?? 3;
      final emoji = _getMoodEmoji(level.toDouble());
      final feelings = _extractEmotionsList(item['feelings'] ?? item['emotions']);
      final dateStr = item['created_at']?.toString() ?? '';
      String formattedDate = dateStr;
      try {
        final dt = _parseDateLocal(dateStr);
        if (dt != null) {
          final now = DateTime.now();
          final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
          final yesterday = now.subtract(const Duration(days: 1));
          final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

          if (isToday) {
            formattedDate = "Today, ${DateFormat('h:mm a').format(dt)}";
          } else if (isYesterday) {
            formattedDate = "Yesterday, ${DateFormat('h:mm a').format(dt)}";
          } else {
            formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dt);
          }
        }
      } catch (_) {}

      final moodName = level == 5
          ? "Great"
          : (level == 4 ? "Good" : (level == 3 ? "Okay" : (level == 2 ? "Low" : "Rough")));

      return GestureDetector(
        onTap: () {
          HapticService.lightTap();
          _showMoodDetailModal(item);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          moodName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFCBD5E1)),
                          ],
                        ),
                      ],
                    ),
                    if (feelings.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 4,
                        children: feelings.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showMoodDetailModal(Map<String, dynamic> item) {
    final level = (item['mood_level'] as num?)?.toInt() ?? 3;
    final emoji = _getMoodEmoji(level.toDouble());
    final feelings = _extractEmotionsList(item['feelings'] ?? item['emotions']);
    final dateStr = item['created_at']?.toString() ?? '';
    final note = item['note']?.toString();
    final moodColor = _getEmotionColor(level == 5 ? 'joy' : (level == 4 ? 'calm' : (level == 3 ? 'neutral' : (level == 2 ? 'anxious' : 'burnout'))));

    String formattedDate = dateStr;
    try {
      final dt = _parseDateLocal(dateStr);
      if (dt != null) {
        formattedDate = DateFormat('MMMM d, yyyy • h:mm a').format(dt);
      }
    } catch (_) {}

    final moodName = level == 5
        ? "Great 😄"
        : (level == 4 ? "Good 🙂" : (level == 3 ? "Okay 😐" : (level == 2 ? "Low 😟" : "Rough 😞")));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: moodColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moodName,
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17, color: moodColor),
                        ),
                        Text(formattedDate, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (feelings.isNotEmpty) ...[
                const Text('Logged Feelings & Context:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: feelings.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: moodColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: moodColor.withAlpha(40)),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: moodColor),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 14),
              ],
              if (note != null && note.trim().isNotEmpty) ...[
                const Text('Personal Reflection Note:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    note,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF334155), height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Influencing factors tag button
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _editMoodInfluences(item);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        feelings.isNotEmpty ? 'Edit Influencing Factors 🏷️' : '+ Tag Influencing Factors 🏷️',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActivityScreen()),
                        );
                      },
                      icon: const Icon(Icons.self_improvement_rounded, size: 16),
                      label: const Text('Calm Now 🌿', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Talk to AI 💬', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMoodInfluences(Map<String, dynamic> item) async {
    final entryId = item['id']?.toString();
    final level = (item['mood_level'] as num?)?.toInt() ?? 3;
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final firstName = currentUser?['first_name'] as String? ?? 'Friend';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MoodInfluenceSheet(
        moodLevel: level,
        firstName: firstName,
        onSave: (factors, note) async {
          Navigator.pop(ctx);
          if (entryId != null && entryId.isNotEmpty) {
            try {
              await ApiClient().patch('${ApiConfig.mood}/$entryId', body: {
                'emotions': factors.isNotEmpty ? factors : null,
                'note': note,
              });
            } catch (_) {}
          }
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updated mood influences! ✅'),
                backgroundColor: Color(0xFF16A34A),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  List<PieChartSectionData> _buildDynamicPieSections(Map<String, int> counts, int total) {
    const colors = [
      Color(0xFF0284C7),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
    ];
    int colorIdx = 0;
    final sections = <PieChartSectionData>[];

    counts.forEach((key, count) {
      if (count > 0 && total > 0) {
        final pct = (count / total) * 100;
        final color = colors[colorIdx % colors.length];
        colorIdx++;
        sections.add(
          PieChartSectionData(
            value: pct,
            color: color,
            radius: 34,
            showTitle: false,
          ),
        );
      }
    });

    return sections;
  }

  List<Widget> _buildDynamicLegend(Map<String, int> counts, int total) {
    const colors = [
      Color(0xFF0284C7),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
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
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
          ),
          Text(pct, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
