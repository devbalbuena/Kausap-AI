import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'activity_screen.dart';

// ── Activity Start Screen ─────────────────────────────────────────────────────
// Phases: idle → active (countdown) → done
class ActivityStartScreen extends StatefulWidget {
  final ActivityItem activity;

  const ActivityStartScreen({super.key, required this.activity});

  @override
  State<ActivityStartScreen> createState() => _ActivityStartScreenState();
}

enum _Phase { idle, active, done }

class _ActivityStartScreenState extends State<ActivityStartScreen>
    with SingleTickerProviderStateMixin {
  static const _storage = FlutterSecureStorage();

  _Phase _phase = _Phase.idle;
  late int _totalSeconds;
  int _secondsRemaining = 0;
  int _elapsedSeconds = 0;
  bool _canFinish = false; // unlocks after 30s
  Timer? _timer;

  // Animated ring controller
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

  // Parse "5 min", "15 min", "20 min" → seconds
  int _parseDurationSeconds(String dur) {
    final match = RegExp(r'(\d+)').firstMatch(dur);
    final minutes = int.tryParse(match?.group(1) ?? '5') ?? 5;
    return minutes * 60;
  }

  String get _activityId =>
      widget.activity.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');

  void _startActivity() {
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

    // Append to history log
    await _appendHistory(today);

    if (!mounted) return;
    setState(() => _phase = _Phase.done);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.activity.title} completed! 🎉'),
        backgroundColor: const Color(0xFF22C55E),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _appendHistory(String date) async {
    final raw = await _storage.read(key: 'activity_history');
    final List<dynamic> history = raw != null ? jsonDecode(raw) as List : [];
    history.insert(0, {
      'id': _activityId,
      'title': widget.activity.title,
      'date': date,
      'durationSeconds': _elapsedSeconds,
    });
    // Keep max 200 entries
    final trimmed = history.take(200).toList();
    await _storage.write(key: 'activity_history', value: jsonEncode(trimmed));
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
            content: const Text(
                'Your progress won\'t be saved if you leave now.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Keep going')),
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  child: const Text('Leave',
                      style: TextStyle(color: Colors.red))),
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
        backgroundColor: const Color(0xFFF8F9FF),
        body: _phase == _Phase.active
            ? _buildActivePhase()
            : _buildIdlePhase(),
      ),
    );
  }

  // ── Idle Phase (original detail view + Start button) ──────────────────────
  Widget _buildIdlePhase() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
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
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF404944),
                        height: 1.71,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'How it works',
                    child: Column(
                      children: widget.activity.steps.map(_buildStep).toList(),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Material(
              color: Colors.white.withAlpha(40),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
        // Start button
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomBar(
            label: 'Start Activity',
            icon: Icons.play_arrow_rounded,
            enabled: true,
            onTap: _startActivity,
          ),
        ),
      ],
    );
  }

  // ── Active Phase (timer overlay) ───────────────────────────────────────────
  Widget _buildActivePhase() {
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _secondsRemaining) / _totalSeconds
        : 1.0;
    final mins = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                Text(
                  widget.activity.title,
                  style: AppTextStyles.heading2,
                ),
                const Spacer(),
                const SizedBox(width: 48), // balance close button
              ],
            ),
          ),

          const Spacer(),

          // Circular countdown ring
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    color: AppColors.primary.withAlpha(25),
                  ),
                ),
                // Foreground progress
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
                // Countdown text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$mins:$secs',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'remaining',
                      style: AppTextStyles.subheading,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Activity name + step hint
          Text(
            widget.activity.title,
            style: AppTextStyles.heading1.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.activity.steps.isNotEmpty
                  ? widget.activity.steps.first.description
                  : 'Follow the steps and breathe.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(),

          // Unlock notice / I'm Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: AnimatedOpacity(
              opacity: _canFinish ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                'You can finish after 30 seconds…',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary),
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

  // ── Shared bottom action bar ───────────────────────────────────────────────
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
            color: Colors.black.withAlpha(31),
            blurRadius: 5.5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: enabled ? onTap : null,
              icon: Icon(icon, color: Colors.white),
              label: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    enabled ? AppColors.primary : AppColors.textSecondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textSecondary.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable sub-widgets ───────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0x4C005DA7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Icon(widget.activity.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),
          Text(
            widget.activity.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${widget.activity.duration} minutes',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white.withAlpha(128),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 4),
                Text(
                  widget.activity.difficulty,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.14,
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration: BoxDecoration(
            color: tag.bg,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: tag.border),
          ),
          child: Text(
            tag.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tag.text,
              letterSpacing: 0.14,
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
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D405B),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildStep(ActivityStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6FF),
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.number}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D405B),
                letterSpacing: 0.14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D405B),
                    letterSpacing: 0.14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3D405B),
                    height: 1.43,
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
