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

  final List<String> _optionDescriptions = [
    '0 days in past 2 weeks',
    '1 to 7 days',
    '8 to 11 days',
    '12 to 14 days',
  ];

  late final List<String> _questions;
  late final List<String> _categories;

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
      _categories = [
        'Anhedonia & Motivation',
        'Mood & Emotional State',
        'Sleep Quality & Rhythm',
        'Energy & Fatigue',
        'Appetite & Nutrition',
        'Self-Worth & Confidence',
        'Focus & Concentration',
        'Psychomotor Activity',
        'Safety & Distress',
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
      _categories = [
        'Nervous Tension',
        'Worry Control',
        'Generalized Anxiety',
        'Physical Relaxation',
        'Motor Restlessness',
        'Irritability & Stress',
        'Anticipatory Fear',
      ];
    }
  }

  void _selectAnswer(int value) {
    setState(() {
      _answers[_currentQuestionIndex] = value;
    });

    // Brief feedback before advancing
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        _finishAssessment();
      }
    });
  }

  void _goToPrevious() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goToNext() {
    if (_answers.containsKey(_currentQuestionIndex)) {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        _finishAssessment();
      }
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
        interpretation = 'Your score indicates minimal or no depressive symptoms. Keep up your positive wellness routines and healthy habits!';
      } else if (totalScore <= 9) {
        severity = 'Mild';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild depressive symptoms noted. Regular mindfulness, consistent sleep schedules, and journaling can help boost mood.';
      } else if (totalScore <= 14) {
        severity = 'Moderate';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate symptoms noted. Exploring structured CBT coping tools and speaking with a counselor can provide strong support.';
      } else {
        severity = 'Moderately Severe';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated symptoms noted. We strongly encourage scheduling a session with a campus counselor or professional therapist.';
      }
    } else {
      if (totalScore <= 4) {
        severity = 'Minimal Anxiety';
        color = const Color(0xFF10B981);
        interpretation = 'Your score indicates minimal anxiety levels. Continue your grounding and mindful breathing practices.';
      } else if (totalScore <= 9) {
        severity = 'Mild Anxiety';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild anxiety symptoms noted. Grounding exercises like 4-7-8 breathing and regular pauses can help reduce physical tension.';
      } else if (totalScore <= 14) {
        severity = 'Moderate Anxiety';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate anxiety noted. Structured coping exercises can help you develop personalized anxiety-management tools.';
      } else {
        severity = 'Severe Anxiety';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated anxiety noted. Reaching out to a counselor or student wellness specialist is strongly recommended.';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Assessment Complete',
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    severity.toUpperCase(),
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, color: color, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Clinical Score: $totalScore / $maxScore',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              interpretation,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.45, color: Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context, true); // Return to insights screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Save & View Insights', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final isPhq = widget.screenerType == 'phq9';
    final themeColor = isPhq ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPhq ? 'PHQ-9 Depression Screener' : 'GAD-7 Anxiety Screener',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Standardized Clinical Health Check',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _categories[_currentQuestionIndex],
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: themeColor),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Main Question Card & Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Over the last 2 weeks, how often have you been bothered by:',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _questions[_currentQuestionIndex],
                              key: ValueKey(_questions[_currentQuestionIndex]),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Options List
                    ...List.generate(4, (index) {
                      final isSelected = _answers[_currentQuestionIndex] == index;
                      return GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? themeColor.withAlpha(20) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? themeColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? themeColor : const Color(0xFFCBD5E1),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _options[index],
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? themeColor : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      _optionDescriptions[index],
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        color: isSelected ? themeColor.withAlpha(200) : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? themeColor.withAlpha(30) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$index pts',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? themeColor : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _goToPrevious,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _answers.containsKey(_currentQuestionIndex) ? _goToNext : null,
                    icon: Icon(
                      _currentQuestionIndex == _questions.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _currentQuestionIndex == _questions.length - 1 ? 'Finish & Save' : 'Next Question',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
