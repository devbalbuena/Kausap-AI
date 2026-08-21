import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/ambient_audio_service.dart';
import '../activity_screen.dart';

class BreathingPlayerWidget extends StatefulWidget {
  final ActivityItem activity;
  final VoidCallback onComplete;

  const BreathingPlayerWidget({
    super.key,
    required this.activity,
    required this.onComplete,
  });

  @override
  State<BreathingPlayerWidget> createState() => _BreathingPlayerWidgetState();
}

enum _BreathingPhase { inhale, hold, exhale, holdAfterExhale }

class _BreathingPlayerWidgetState extends State<BreathingPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final AmbientAudioService _audioService = AmbientAudioService();
  bool _soundEnabled = true;
  bool _isPlaying = true;

  int _currentCycle = 1;
  final int _totalCycles = 4;

  _BreathingPhase _currentPhase = _BreathingPhase.inhale;
  int _phaseSecondsRemaining = 4;
  Timer? _timer;

  // Pattern config
  late int _inhaleSec;
  late int _holdSec;
  late int _exhaleSec;
  late int _holdAfterExhaleSec;

  @override
  void initState() {
    super.initState();
    _configurePattern();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleSec),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.35).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _startPhase(_BreathingPhase.inhale);
  }

  void _configurePattern() {
    final title = widget.activity.title.toLowerCase();
    if (title.contains('box')) {
      _inhaleSec = 4;
      _holdSec = 4;
      _exhaleSec = 4;
      _holdAfterExhaleSec = 4;
    } else {
      // 4-7-8 Breathing
      _inhaleSec = 4;
      _holdSec = 7;
      _exhaleSec = 8;
      _holdAfterExhaleSec = 0;
    }
  }

  void _startPhase(_BreathingPhase phase) {
    if (!mounted) return;
    _currentPhase = phase;

    int duration;
    switch (phase) {
      case _BreathingPhase.inhale:
        duration = _inhaleSec;
        _animController.duration = Duration(seconds: _inhaleSec);
        _animController.forward(from: 0.0);
        break;
      case _BreathingPhase.hold:
        duration = _holdSec;
        break;
      case _BreathingPhase.exhale:
        duration = _exhaleSec;
        _animController.duration = Duration(seconds: _exhaleSec);
        _animController.reverse(from: 1.0);
        break;
      case _BreathingPhase.holdAfterExhale:
        duration = _holdAfterExhaleSec;
        break;
    }

    _phaseSecondsRemaining = duration;

    // Trigger audio & haptic cue
    if (_soundEnabled) {
      _audioService.playBreathingCue(_phaseTitle(phase));
    }
    _triggerHaptic();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!_isPlaying) return;

      setState(() {
        if (_phaseSecondsRemaining > 1) {
          _phaseSecondsRemaining--;
        } else {
          t.cancel();
          _advanceToNextPhase();
        }
      });
    });
  }

  void _advanceToNextPhase() {
    switch (_currentPhase) {
      case _BreathingPhase.inhale:
        if (_holdSec > 0) {
          _startPhase(_BreathingPhase.hold);
        } else {
          _startPhase(_BreathingPhase.exhale);
        }
        break;
      case _BreathingPhase.hold:
        _startPhase(_BreathingPhase.exhale);
        break;
      case _BreathingPhase.exhale:
        if (_holdAfterExhaleSec > 0) {
          _startPhase(_BreathingPhase.holdAfterExhale);
        } else {
          _nextCycleOrFinish();
        }
        break;
      case _BreathingPhase.holdAfterExhale:
        _nextCycleOrFinish();
        break;
    }
  }

  void _nextCycleOrFinish() {
    if (_currentCycle < _totalCycles) {
      setState(() => _currentCycle++);
      _startPhase(_BreathingPhase.inhale);
    } else {
      // Completed all cycles!
      if (_soundEnabled) {
        _audioService.playChime(frequency: 528.0, durationSeconds: 2.5);
      }
      widget.onComplete();
    }
  }

  Future<void> _triggerHaptic() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        Vibration.vibrate(duration: 60);
      }
    } catch (_) {}
  }

  String _phaseTitle(_BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return 'Inhale';
      case _BreathingPhase.hold:
      case _BreathingPhase.holdAfterExhale:
        return 'Hold';
      case _BreathingPhase.exhale:
        return 'Exhale';
    }
  }

  String _phaseSubtitle(_BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return 'Breathe in slowly through your nose';
      case _BreathingPhase.hold:
      case _BreathingPhase.holdAfterExhale:
        return 'Rest comfortably with lungs still';
      case _BreathingPhase.exhale:
        return 'Release gently through your mouth';
    }
  }

  Color _phaseColor(_BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return const Color(0xFF0EA5E9); // Sky blue
      case _BreathingPhase.hold:
      case _BreathingPhase.holdAfterExhale:
        return const Color(0xFF10B981); // Emerald
      case _BreathingPhase.exhale:
        return const Color(0xFF8B5CF6); // Soft purple
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _phaseColor(_currentPhase);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Calming dark canvas
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: _soundEnabled ? AppColors.primary : Colors.white38,
                    ),
                    onPressed: () {
                      setState(() => _soundEnabled = !_soundEnabled);
                    },
                  ),
                ],
              ),
            ),

            // Cycle & Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cycle $_currentCycle of $_totalCycles',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Animated Breathing Sphere
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 260 * _scaleAnimation.value,
                      height: 260 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withAlpha(20),
                      ),
                    ),
                    // Middle aura
                    Container(
                      width: 210 * _scaleAnimation.value,
                      height: 210 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withAlpha(45),
                      ),
                    ),
                    // Core breathing circle
                    Container(
                      width: 160 * _scaleAnimation.value,
                      height: 160 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            currentColor,
                            currentColor.withAlpha(190),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withAlpha(90),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _phaseTitle(_currentPhase),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_phaseSecondsRemaining',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const Spacer(),

            // Phase instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _phaseSubtitle(_currentPhase),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() => _isPlaying = !_isPlaying);
                        if (!_isPlaying) {
                          _animController.stop();
                        } else {
                          _animController.forward();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(_isPlaying ? 'Pause' : 'Resume', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: widget.onComplete,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20),
                          SizedBox(width: 6),
                          Text("I'm Done", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        ],
                      ),
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
