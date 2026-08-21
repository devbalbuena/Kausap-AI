import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/ambient_audio_service.dart';
import '../activity_screen.dart';

enum _BreathingPattern { fourSevenEight, box, resonant }
enum _BreathingPhase { inhale, hold, exhale, holdAfterExhale }

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

class _BreathingPlayerWidgetState extends State<BreathingPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final AmbientAudioService _audioService = AmbientAudioService();
  bool _soundEnabled = true;
  bool _isPlaying = true;

  _BreathingPattern _pattern = _BreathingPattern.fourSevenEight;
  int _currentCycle = 1;
  int _totalCycles = 4;

  final List<int> _cycleOptions = [4, 8, 12];

  _BreathingPhase _currentPhase = _BreathingPhase.inhale;
  int _phaseSecondsRemaining = 4;
  Timer? _timer;

  // Pattern durations
  late int _inhaleSec;
  late int _holdSec;
  late int _exhaleSec;
  late int _holdAfterExhaleSec;

  @override
  void initState() {
    super.initState();
    _applyPatternConfig();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleSec),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.35).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _startPhase(_BreathingPhase.inhale);
  }

  void _applyPatternConfig() {
    final title = widget.activity.title.toLowerCase();
    if (title.contains('box')) {
      _pattern = _BreathingPattern.box;
    }

    switch (_pattern) {
      case _BreathingPattern.fourSevenEight:
        _inhaleSec = 4;
        _holdSec = 7;
        _exhaleSec = 8;
        _holdAfterExhaleSec = 0;
        break;
      case _BreathingPattern.box:
        _inhaleSec = 4;
        _holdSec = 4;
        _exhaleSec = 4;
        _holdAfterExhaleSec = 4;
        break;
      case _BreathingPattern.resonant:
        _inhaleSec = 5;
        _holdSec = 0;
        _exhaleSec = 5;
        _holdAfterExhaleSec = 0;
        break;
    }
  }

  void _setPattern(_BreathingPattern newPattern) {
    setState(() {
      _pattern = newPattern;
      _applyPatternConfig();
      _currentCycle = 1;
      _startPhase(_BreathingPhase.inhale);
    });
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
        return const Color(0xFF0284C7); // Sky cyan
      case _BreathingPhase.hold:
      case _BreathingPhase.holdAfterExhale:
        return const Color(0xFF059669); // Emerald
      case _BreathingPhase.exhale:
        return const Color(0xFF7C3AED); // Royal purple
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
      backgroundColor: const Color(0xFFF8FAFC), // Light Serene Wellness Canvas
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: _soundEnabled ? AppColors.primary : const Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      setState(() => _soundEnabled = !_soundEnabled);
                    },
                  ),
                ],
              ),
            ),

            // Pattern Selector Chips (4-7-8 Relax, Box 4-4-4-4, Resonant 5-5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPatternChip(_BreathingPattern.fourSevenEight, '🌬️ 4-7-8 Relax'),
                  const SizedBox(width: 6),
                  _buildPatternChip(_BreathingPattern.box, '📦 Box 4-4-4-4'),
                  const SizedBox(width: 6),
                  _buildPatternChip(_BreathingPattern.resonant, '🌊 5-5 Flow'),
                ],
              ),
            ),

            // Cycle Selector & Live Tracker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                    ),
                    child: Text(
                      'Cycle $_currentCycle of $_totalCycles',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Row(
                    children: _cycleOptions.map((c) {
                      final isSelected = c == _totalCycles;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _totalCycles = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${c}x',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Animated Breathing Sphere in Light Theme
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ripple Glow
                    Container(
                      width: 250 * _scaleAnimation.value,
                      height: 250 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withAlpha(20),
                      ),
                    ),
                    // Middle Ring
                    Container(
                      width: 200 * _scaleAnimation.value,
                      height: 200 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withAlpha(45),
                      ),
                    ),
                    // Core breathing sphere
                    Container(
                      width: 150 * _scaleAnimation.value,
                      height: 150 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            currentColor,
                            currentColor.withAlpha(210),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withAlpha(90),
                            blurRadius: 28,
                            spreadRadius: 3,
                            offset: const Offset(0, 4),
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
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
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

            // Phase instructions Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _phaseSubtitle(_currentPhase),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
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

  Widget _buildPatternChip(_BreathingPattern p, String label) {
    final isSelected = _pattern == p;
    return GestureDetector(
      onTap: () => _setPattern(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withAlpha(50),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
