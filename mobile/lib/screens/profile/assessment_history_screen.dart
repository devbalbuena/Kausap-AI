import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class AssessmentHistoryScreen extends StatefulWidget {
  const AssessmentHistoryScreen({super.key});

  @override
  State<AssessmentHistoryScreen> createState() => _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {
  static const _storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final raw = await _storage.read(key: 'assessment_history');
    if (mounted) {
      setState(() {
        _history = raw != null
            ? List<Map<String, dynamic>>.from(
                (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
            : [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAssessmentResult({
    required String testName,
    required int score,
    required int maxScore,
    required String severity,
    required Color severityColor,
    required String interpretation,
  }) async {
    final today = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final entry = {
      'testName': testName,
      'score': score,
      'maxScore': maxScore,
      'severity': severity,
      'date': today,
      'interpretation': interpretation,
    };

    final raw = await _storage.read(key: 'assessment_history');
    final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
    list.insert(0, entry);
    await _storage.write(key: 'assessment_history', value: jsonEncode(list));

    await _loadHistory();
  }

  void _startScreener(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScreenerFlowScreen(
          screenerType: type,
          onComplete: (score, maxScore, severity, color, interpretation) async {
            await _saveAssessmentResult(
              testName: type == 'phq9' ? 'PHQ-9 Depression Screener' : 'GAD-7 Anxiety Screener',
              score: score,
              maxScore: maxScore,
              severity: severity,
              severityColor: color,
              interpretation: interpretation,
            );
          },
        ),
      ),
    );
  }

  void _showSelectAssessmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Self-Assessment', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Clinically-backed screening tools to monitor your mental wellness trends.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            _buildAssessmentOption(
              title: 'PHQ-9 (Depression Screener)',
              subtitle: '9 questions • Measures mood, energy, and depression symptoms',
              icon: Icons.spa_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(ctx);
                _startScreener('phq9');
              },
            ),
            const SizedBox(height: 12),

            _buildAssessmentOption(
              title: 'GAD-7 (Anxiety Screener)',
              subtitle: '7 questions • Measures anxiety, worry, and nervous tension',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(ctx);
                _startScreener('gad7');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    final lower = severity.toLowerCase();
    if (lower.contains('minimal') || lower.contains('none')) return const Color(0xFF10B981);
    if (lower.contains('mild')) return const Color(0xFF3B82F6);
    if (lower.contains('moderate')) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
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
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Assessment History', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                    onPressed: _showSelectAssessmentSheet,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.assignment_outlined, size: 40, color: AppColors.primary),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Assessments Yet',
                                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Self-assessments like PHQ-9 and GAD-7 help you and your therapist understand your emotional trends over time.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _showSelectAssessmentSheet,
                                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                                  label: const Text('Take Self-Assessment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _history.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            final severity = item['severity'] as String? ?? 'Minimal';
                            final color = _getSeverityColor(severity);

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0x1AC0C9C2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['testName'] as String? ?? 'Clinical Screener',
                                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          severity,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Score: ${item['score']}/${item['maxScore']}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        item['date'] as String? ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item['interpretation'] != null &&
                                      (item['interpretation'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item['interpretation'] as String,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Interactive Screener Flow ────────────────────────────────────────────────
class _ScreenerFlowScreen extends StatefulWidget {
  final String screenerType; // 'phq9' | 'gad7'
  final Function(int score, int maxScore, String severity, Color color, String interpretation) onComplete;

  const _ScreenerFlowScreen({required this.screenerType, required this.onComplete});

  @override
  State<_ScreenerFlowScreen> createState() => _ScreenerFlowScreenState();
}

class _ScreenerFlowScreenState extends State<_ScreenerFlowScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {};

  final List<String> _options = [
    'Not at all',
    'Several days',
    'More than half the days',
    'Nearly every day',
  ];

  late final List<String> _questions;

  @override
  void initState() {
    super.initState();
    if (widget.screenerType == 'phq9') {
      _questions = [
        'Little interest or pleasure in doing things?',
        'Feeling down, depressed, or hopeless?',
        'Trouble falling or staying asleep, or sleeping too much?',
        'Feeling tired or having little energy?',
        'Poor appetite or overeating?',
        'Feeling bad about yourself — or that you are a failure or have let yourself down?',
        'Trouble concentrating on things, such as reading or studying?',
        'Moving or speaking slowly, or being fidgety/restless?',
        'Thoughts that you would be better off dead, or of hurting yourself?',
      ];
    } else {
      _questions = [
        'Feeling nervous, anxious, or on edge?',
        'Not being able to stop or control worrying?',
        'Worrying too much about different things?',
        'Trouble relaxing?',
        'Being so restless that it is hard to sit still?',
        'Becoming easily annoyed or irritable?',
        'Feeling afraid, as if something awful might happen?',
      ];
    }
  }

  void _selectAnswer(int value) {
    setState(() {
      _answers[_currentQuestionIndex] = value;
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishAssessment();
    }
  }

  void _finishAssessment() {
    int totalScore = 0;
    for (final v in _answers.values) {
      totalScore += v;
    }

    String severity;
    Color color;
    String interpretation;
    final maxScore = widget.screenerType == 'phq9' ? 27 : 21;

    if (widget.screenerType == 'phq9') {
      if (totalScore <= 4) {
        severity = 'Minimal';
        color = const Color(0xFF10B981);
        interpretation = 'Your score suggests minimal to no depression symptoms. Keep maintaining your healthy wellness routines.';
      } else if (totalScore <= 9) {
        severity = 'Mild';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild depressive symptoms noted. Regular mindfulness, sleep hygiene, and journaling can help boost mood.';
      } else if (totalScore <= 14) {
        severity = 'Moderate';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate symptoms noted. Talking with a counselor or therapist can provide valuable coping strategies.';
      } else {
        severity = 'Moderately Severe';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated symptoms noted. We recommend scheduling a 1-on-1 session with a mental health professional.';
      }
    } else {
      if (totalScore <= 4) {
        severity = 'Minimal Anxiety';
        color = const Color(0xFF10B981);
        interpretation = 'Your score suggests minimal anxiety levels. Continue your grounding and relaxation practices.';
      } else if (totalScore <= 9) {
        severity = 'Mild Anxiety';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild anxiety symptoms noted. Breathing exercises like 4-7-8 and regular pauses can help reduce tension.';
      } else if (totalScore <= 14) {
        severity = 'Moderate Anxiety';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate anxiety noted. Structured therapy sessions can help develop personalized anxiety management tools.';
      } else {
        severity = 'Severe Anxiety';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated anxiety noted. Reaching out to a counselor or mental health specialist is strongly advised.';
      }
    }

    widget.onComplete(totalScore, maxScore, severity, color, interpretation);

    // Show Result Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📋 ', style: TextStyle(fontSize: 22)),
            Expanded(child: Text('Assessment Result', style: AppTextStyles.heading2.copyWith(fontSize: 17))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(
                '$severity (Score: $totalScore / $maxScore)',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: color, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(interpretation, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.45, color: Color(0xFF374151))),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return to assessment history
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save to History'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

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
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.screenerType == 'phq9' ? 'PHQ-9 Depression Screener' : 'GAD-7 Anxiety Screener',
                    style: AppTextStyles.heading2.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      Text('${(progress * 100).round()}%', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Over the last 2 weeks, how often have you been bothered by:',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _questions[_currentQuestionIndex],
                      style: AppTextStyles.heading2.copyWith(fontSize: 18, height: 1.35),
                    ),
                    const SizedBox(height: 28),

                    // Options
                    ...List.generate(4, (index) {
                      final isSelected = _answers[_currentQuestionIndex] == index;
                      return GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withAlpha(20) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : const Color(0x1AC0C9C2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            _options[index],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
