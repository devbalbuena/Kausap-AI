import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import '../../services/ambient_audio_service.dart';
import 'activity_screen.dart';
import 'widgets/breathing_player_widget.dart';
import 'widgets/meditation_player_widget.dart';
import 'widgets/gratitude_journal_widget.dart';
import 'widgets/mindful_walking_widget.dart';
import 'widgets/grounding_player_widget.dart';

// ── Activity Start Screen ─────────────────────────────────────────────────────
// Phases: idle → active (interactive player) → done
class ActivityStartScreen extends StatefulWidget {
  final ActivityItem activity;

  const ActivityStartScreen({super.key, required this.activity});

  @override
  State<ActivityStartScreen> createState() => _ActivityStartScreenState();
}

enum _Phase { idle, active }

class _ActivityStartScreenState extends State<ActivityStartScreen>
    with SingleTickerProviderStateMixin {
  static const _storage = FlutterSecureStorage();

  _Phase _phase = _Phase.idle;
  late int _totalSeconds;
  int _secondsRemaining = 0;
  int _elapsedSeconds = 0;
  bool _canFinish = false; // unlocks after 30s
  Timer? _timer;

  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseDurationSeconds(widget.activity.duration);
    _secondsRemaining = _totalSeconds;

    _ringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  int _parseDurationSeconds(String dur) {
    final match = RegExp(r'(\d+)').firstMatch(dur);
    final minutes = int.tryParse(match?.group(1) ?? '5') ?? 5;
    return minutes * 60;
  }

  String get _activityId => widget.activity.id;

  void _startActivity() {
    HapticService.mediumTap();
    setState(() {
      _phase = _Phase.active;
      _secondsRemaining = _totalSeconds;
      _elapsedSeconds = 0;
      _canFinish = false;
    });
    _ringController.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_secondsRemaining > 0) _secondsRemaining--;
        if (_elapsedSeconds >= 30) _canFinish = true;
        if (_secondsRemaining == 0) {
          _canFinish = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _completeActivity() async {
    _timer?.cancel();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Save daily completion key
    await _storage.write(
      key: 'activity_${_activityId}_$today',
      value: 'completed',
    );
    // Also mark mindfulness quest for the day
    await _storage.write(key: 'mindfulness_$today', value: 'completed');

    // Show post-exercise reflection dialog before popping
    if (!mounted) return;
    await _showCompletionReflectionDialog(today);
  }

  Future<void> _appendHistory(String date, {String? moodFeedback}) async {
    final raw = await _storage.read(key: 'activity_history');
    final List<dynamic> history = raw != null ? jsonDecode(raw) as List : [];
    history.insert(0, {
      'id': _activityId,
      'title': widget.activity.title,
      'date': date,
      'durationSeconds': _elapsedSeconds > 0 ? _elapsedSeconds : _totalSeconds,
      'moodFeedback': moodFeedback ?? 'Refreshed',
      'completedAt': DateTime.now().toIso8601String(),
    });
    final trimmed = history.take(200).toList();
    await _storage.write(key: 'activity_history', value: jsonEncode(trimmed));
  }

  Future<void> _showCompletionReflectionDialog(String today) async {
    HapticService.success();
    AmbientAudioService.instance.playNotificationChime();

    String? selectedFeedback;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 16,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🌟', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Session Completed! 🎉',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Great job taking time for your mental wellness with "${widget.activity.title}".',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How are you feeling right now?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3 Quick feedback options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeedbackOption(
                        emoji: '🧘',
                        label: 'Much Calmer',
                        isSelected: selectedFeedback == 'Much Calmer',
                        onTap: () {
                          HapticService.lightTap();
                          setDialogState(() => selectedFeedback = 'Much Calmer');
                        },
                      ),
                      _buildFeedbackOption(
                        emoji: '🙂',
                        label: 'A Bit Better',
                        isSelected: selectedFeedback == 'A Bit Better',
                        onTap: () {
                          HapticService.lightTap();
                          setDialogState(() => selectedFeedback = 'A Bit Better');
                        },
                      ),
                      _buildFeedbackOption(
                        emoji: '😐',
                        label: 'About Same',
                        isSelected: selectedFeedback == 'About Same',
                        onTap: () {
                          HapticService.lightTap();
                          setDialogState(() => selectedFeedback = 'About Same');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await _appendHistory(today, moodFeedback: selectedFeedback);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (mounted) nav.pop();
                      },
                      child: const Text(
                        'Done & Claim Quest ✅',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackOption({
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.active,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _phase != _Phase.active) return;
        final navigator = Navigator.of(context);
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Stop activity?'),
            content: const Text('Your progress won\'t be saved if you leave now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Keep going'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Leave', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          _timer?.cancel();
          _ringController.stop();
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _phase == _Phase.active
              ? KeyedSubtree(key: const ValueKey('active'), child: _buildActivePhase())
              : KeyedSubtree(key: const ValueKey('idle'), child: _buildIdlePhase()),
        ),
      ),
    );
  }

  // ── Idle Phase (Detail view + Start button) ───────────────────────────────
  Widget _buildIdlePhase() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTags(),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'What is this?',
                    child: Text(
                      widget.activity.whatIsThis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'How to practice',
                    child: Column(
                      children: widget.activity.steps.map(_buildStep).toList(),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        // Back Button
        Positioned(
          top: 44,
          left: 16,
          child: Semantics(
            label: 'Back',
            button: true,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
        // Start button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(
            label: 'Start Exercise ➔',
            icon: Icons.play_arrow_rounded,
            enabled: true,
            onTap: _startActivity,
          ),
        ),
      ],
    );
  }

  // ── Active Phase (Smart player routing) ───────────────────────────────────
  Widget _buildActivePhase() {
    final cat = widget.activity.category.toLowerCase();
    final title = widget.activity.title.toLowerCase();

    if (cat == 'breathing' || title.contains('breathing')) {
      return BreathingPlayerWidget(
        activity: widget.activity,
        onComplete: _completeActivity,
      );
    } else if (cat == 'grounding' || title.contains('grounding')) {
      return GroundingPlayerWidget(
        activity: widget.activity,
        onComplete: _completeActivity,
      );
    } else if (cat == 'meditation' || title.contains('meditation') || title.contains('compassion')) {
      return MeditationPlayerWidget(
        activity: widget.activity,
        onComplete: _completeActivity,
      );
    } else if (cat == 'journaling' || title.contains('journal')) {
      return GratitudeJournalWidget(
        activity: widget.activity,
        onComplete: _completeActivity,
      );
    } else if (cat == 'exercise' || title.contains('walking')) {
      return MindfulWalkingWidget(
        activity: widget.activity,
        onComplete: _completeActivity,
      );
    }

    // Fallback countdown timer
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _secondsRemaining) / _totalSeconds
        : 1.0;
    final mins = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                Text(widget.activity.title, style: AppTextStyles.heading2),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    color: AppColors.primary.withAlpha(25),
                  ),
                ),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    color: AppColors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$mins:$secs',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text('remaining', style: AppTextStyles.subheading),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(widget.activity.title, style: AppTextStyles.heading1.copyWith(fontSize: 22), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.activity.steps.isNotEmpty ? widget.activity.steps.first.description : 'Follow the steps and breathe.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: AnimatedOpacity(
              opacity: _canFinish ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                'You can finish after 30 seconds…',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildBottomBar(
              label: "I'm Done",
              icon: Icons.check_circle_rounded,
              enabled: _canFinish,
              onTap: _completeActivity,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────
  Widget _buildBottomBar({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _phase == _Phase.active
            ? BorderRadius.circular(14)
            : const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: enabled ? onTap : null,
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? const Color(0xFF0284C7) : AppColors.textSecondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.activity.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: widget.activity.gradient.first.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(50), width: 2),
            ),
            child: Icon(widget.activity.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            widget.activity.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.activity.duration,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14)),
                ),
                Text(
                  widget.activity.difficulty,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.activity.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: tag.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tag.border),
          ),
          child: Text(
            tag.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tag.text,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildStep(ActivityStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Center(
              child: Text(
                '${step.number}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
