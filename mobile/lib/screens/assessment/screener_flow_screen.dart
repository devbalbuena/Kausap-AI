import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import '../chat/chatbot_screen.dart';
import '../activity/activity_screen.dart';

class ScreenerFlowScreen extends StatefulWidget {
  final String screenerType; // 'phq9' | 'gad7' | 'burnout'
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
    'Not at all (0)',
    'Several days (1)',
    'More than half the days (2)',
    'Nearly every day (3)',
  ];

  late final List<String> _questions;
  late final String _title;
  late final String _subtitle;

  @override
  void initState() {
    super.initState();
    final type = widget.screenerType.toLowerCase();
    if (type.contains('phq')) {
      _title = 'Mood & Energy Check-In (PHQ-9)';
      _subtitle = 'Reflect on your mood, sleep, focus, and energy levels over the last 2 weeks.';
      _questions = [
        'Little interest or pleasure in doing things you usually enjoy?',
        'Feeling down, depressed, or hopeless about things?',
        'Trouble falling or staying asleep, or sleeping too much?',
        'Feeling tired, drained, or having very little energy?',
        'Poor appetite, skipping meals, or stress overeating?',
        'Feeling bad about yourself — or feeling like you have let yourself or family down?',
        'Trouble concentrating on things, such as studying, attending lectures, or reading?',
        'Moving or speaking noticeably slowly, or feeling unusually fidgety and restless?',
        'Thoughts of hurting yourself or wishing you were away from everything?',
      ];
    } else if (type.contains('gad')) {
      _title = 'Stress & Peace of Mind Check-In (GAD-7)';
      _subtitle = 'Check your daily worry, nervousness, and tension levels to find balance.';
      _questions = [
        'Feeling nervous, anxious, or constantly on edge?',
        'Not being able to stop, calm down, or control worrying thoughts?',
        'Worrying too much about multiple things at once (grades, family, future)?',
        'Trouble relaxing or winding down after a busy campus day?',
        'Being so restless that it feels hard to sit still or focus?',
        'Becoming easily annoyed, frustrated, or irritable with others?',
        'Feeling afraid or dreading that something awful might happen?',
      ];
    } else {
      _title = 'Campus Burnout & Fatigue Check-In';
      _subtitle = 'Assess thesis pressure, deadline fatigue, and academic overwhelm.';
      _questions = [
        'Feeling emotionally drained and exhausted by your academic workload?',
        'Feeling tired or lacking enthusiasm in the morning when facing classes or study?',
        'Feeling overwhelmed by project deadlines, thesis requirements, or exams?',
        'Doubting the value of your academic efforts or experiencing imposter syndrome?',
        'Feeling that university demands leave you with almost no energy for your personal life?',
        'Feeling physically or mentally worn out at the end of a university day?',
      ];
    }
  }

  void _selectAnswer(int value) {
    HapticService.lightTap();
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
    HapticService.mediumTap();
    int totalScore = 0;
    for (final v in _answers.values) {
      totalScore += v;
    }

    String severity;
    Color color;
    String interpretation;
    String empatheticInsight;

    final type = widget.screenerType.toLowerCase();
    final bool isPhq = type.contains('phq');
    final bool isGad = type.contains('gad');
    final int maxScore = isPhq ? 27 : (isGad ? 21 : 18);

    if (isPhq) {
      if (totalScore <= 4) {
        severity = 'Minimal to None';
        color = const Color(0xFF10B981);
        interpretation = 'Your responses reflect healthy emotional balance and steady mood.';
        empatheticInsight = 'You are in a great emotional space! Keep nourishing yourself with balanced sleep, physical movement, and joyful campus moments.';
      } else if (totalScore <= 9) {
        severity = 'Mild Fatigue / Low Mood';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild low mood or fatigue noted over the past 2 weeks.';
        empatheticInsight = 'It is completely normal to have occasional low-energy weeks during the semester. Remember to take small daily pauses and be gentle with yourself.';
      } else if (totalScore <= 14) {
        severity = 'Moderate Emotional Weight';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate emotional weight noted. University demands may be taking a toll.';
        empatheticInsight = 'You seem to be carrying a noticeable amount of emotional heaviness. Unpacking these feelings with Kausap AI or a trusted mentor can give you clarity and relief.';
      } else {
        severity = 'Elevated Emotional Weight';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated symptoms noted. Extra care and guidance are recommended.';
        empatheticInsight = 'You have been carrying a very heavy load recently. Please know that you never have to carry this alone. Reaching out to our FSUU Guidance Office can offer warm, supportive care.';
      }
    } else if (isGad) {
      if (totalScore <= 4) {
        severity = 'Peaceful / Minimal Stress';
        color = const Color(0xFF10B981);
        interpretation = 'Your anxiety and nervous tension levels are well-managed.';
        empatheticInsight = 'You have good peace of mind right now! Continue your grounding and relaxing habits.';
      } else if (totalScore <= 9) {
        severity = 'Mild Worry & Tension';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild worry and physical restlessness noted.';
        empatheticInsight = 'College deadlines often trigger mild overthinking. Practicing quick 2-minute box breathing can quickly calm your nervous system.';
      } else if (totalScore <= 14) {
        severity = 'Moderate Stress & Anxiety';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate anxiety noted. Frequent racing thoughts or tension.';
        empatheticInsight = 'Your mind has been running at high speed lately. Let\'s practice grounding exercises together and break down overwhelming tasks into bite-sized steps.';
      } else {
        severity = 'High Stress & Tension';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated anxiety levels noted.';
        empatheticInsight = 'You are experiencing significant nervous tension. Remember to pause, take slow deep breaths, and connect with campus counselors who care deeply about your wellbeing.';
      }
    } else {
      // Academic Burnout
      if (totalScore <= 4) {
        severity = 'Healthy Energy Balance';
        color = const Color(0xFF10B981);
        interpretation = 'Your academic energy and motivation are well-balanced.';
        empatheticInsight = 'You have a healthy rhythm with your studies! Keep protecting your boundaries between schoolwork and rest.';
      } else if (totalScore <= 8) {
        severity = 'Mild Study Fatigue';
        color = const Color(0xFF3B82F6);
        interpretation = 'Mild academic fatigue or occasional study tiredness.';
        empatheticInsight = 'Campus life is demanding. When fatigue hits, taking 15-minute screen-free breaks will refresh your mental stamina.';
      } else if (totalScore <= 13) {
        severity = 'Moderate Academic Burnout';
        color = const Color(0xFFF59E0B);
        interpretation = 'Moderate academic burnout noted. Thesis or deadlines may feel heavy.';
        empatheticInsight = 'You\'ve been pushing yourself very hard lately. It is okay to rest without feeling guilty—you are a human being before a student.';
      } else {
        severity = 'High Academic Exhaustion';
        color = const Color(0xFFEF4444);
        interpretation = 'Elevated study exhaustion and burnout noted.';
        empatheticInsight = 'Your academic battery is deeply drained. Let\'s slow down together, prioritize what truly matters today, and seek mentor support.';
      }
    }

    // Dynamic Comparison with previous check-in of the same test type
    String progressNote = '🌟 First check-in recorded! This sets your personal baseline.';
    try {
      final raw = await _storage.read(key: 'assessment_history');
      final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
      final pastMatches = list.where((item) => item is Map && item['testName'] == _title).toList();

      if (pastMatches.isNotEmpty) {
        final last = pastMatches.first as Map<String, dynamic>;
        final prevScore = (last['score'] as num?)?.toInt() ?? totalScore;
        final diff = totalScore - prevScore;
        if (diff < 0) {
          progressNote = '🌱 Your score dropped by ${diff.abs()} points compared to your last check-in! Great progress practicing self-care.';
        } else if (diff > 0) {
          progressNote = '💙 Your score is $diff points higher than your last check-in. You might be carrying extra campus pressure—be gentle with yourself.';
        } else {
          progressNote = '✨ Your emotional state is steady compared to your last check-in.';
        }
      }

      // Save result to local storage
      final today = DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now());
      final entry = {
        'testName': _title,
        'score': totalScore,
        'maxScore': maxScore,
        'severity': severity,
        'date': today,
        'interpretation': interpretation,
        'empatheticInsight': empatheticInsight,
        'progressNote': progressNote,
      };

      list.insert(0, entry);
      await _storage.write(key: 'assessment_history', value: jsonEncode(list));
    } catch (_) {}

    if (widget.onComplete != null) {
      widget.onComplete!(totalScore, maxScore, severity, color, interpretation);
    }

    if (!mounted) return;

    // Show Empathetic Result Reflection Sheet
    _showEmpatheticResultModal(
      title: _title,
      score: totalScore,
      maxScore: maxScore,
      severity: severity,
      color: color,
      empatheticInsight: empatheticInsight,
      progressNote: progressNote,
    );
  }

  void _showEmpatheticResultModal({
    required String title,
    required int score,
    required int maxScore,
    required String severity,
    required Color color,
    required String empatheticInsight,
    required String progressNote,
  }) {
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
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.favorite_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reflection Complete ✨',
                          style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          title,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Severity & Score Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$score / $maxScore',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            severity,
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: color),
                          ),
                          const Text(
                            'Personal self-assessment score',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Progress Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  progressNote,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155), height: 1.35),
                ),
              ),
              const SizedBox(height: 12),

              // Empathetic Insight Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💡 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'What this means for you',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF3730A3)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      empatheticInsight,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF312E81), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, true);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActivityScreen()),
                        );
                      },
                      icon: const Icon(Icons.self_improvement_rounded, size: 16),
                      label: const Text('Calm Now 🌿', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, true);
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Done & Save to History',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            // Top Header
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: AppTextStyles.heading2.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _subtitle,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

            const SizedBox(height: 16),

            // Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Over the last 2 weeks, how often have you felt:',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _questions[_currentQuestionIndex],
                      style: AppTextStyles.heading2.copyWith(fontSize: 17, height: 1.35),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ...List.generate(4, (index) {
                      final isSelected = _answers[_currentQuestionIndex] == index;
                      return GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
                              fontSize: 13.5,
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
