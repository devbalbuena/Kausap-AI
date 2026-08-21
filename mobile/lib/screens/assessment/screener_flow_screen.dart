import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class ScreenerFlowScreen extends StatefulWidget {
  final String screenerType; // 'phq9' | 'gad7'
  final Function(int score, int maxScore, String severity, Color color, String interpretation)? onComplete;

  const ScreenerFlowScreen({super.key, required this.screenerType, this.onComplete});

  @override
  State<ScreenerFlowScreen> createState() => _ScreenerFlowScreenState();
}

class _ScreenerFlowScreenState extends State<ScreenerFlowScreen> {
  static const _storage = FlutterSecureStorage();
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

  Future<void> _finishAssessment() async {
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

    // Save result to local storage
    final today = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final testName = widget.screenerType == 'phq9' ? 'PHQ-9 Depression Screener' : 'GAD-7 Anxiety Screener';
    final entry = {
      'testName': testName,
      'score': totalScore,
      'maxScore': maxScore,
      'severity': severity,
      'date': today,
      'interpretation': interpretation,
    };

    try {
      final raw = await _storage.read(key: 'assessment_history');
      final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
      list.insert(0, entry);
      await _storage.write(key: 'assessment_history', value: jsonEncode(list));
    } catch (_) {}

    if (widget.onComplete != null) {
      widget.onComplete!(totalScore, maxScore, severity, color, interpretation);
    }

    if (!mounted) return;

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
              decoration: BoxDecoration(color: color.withAlpha(35), borderRadius: BorderRadius.circular(8)),
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
              Navigator.pop(context, true); // Return with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done'),
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
                          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.screenerType == 'phq9' ? 'PHQ-9 Depression Screener' : 'GAD-7 Anxiety Screener',
                      style: AppTextStyles.heading2.copyWith(fontSize: 16),
                    ),
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
                              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
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
