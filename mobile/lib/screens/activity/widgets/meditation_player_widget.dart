import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/ambient_audio_service.dart';
import '../activity_screen.dart';

class MeditationPlayerWidget extends StatefulWidget {
  final ActivityItem activity;
  final VoidCallback onComplete;

  const MeditationPlayerWidget({
    super.key,
    required this.activity,
    required this.onComplete,
  });

  @override
  State<MeditationPlayerWidget> createState() => _MeditationPlayerWidgetState();
}

class _MeditationPlayerWidgetState extends State<MeditationPlayerWidget>
    with SingleTickerProviderStateMixin {
  final AmbientAudioService _audioService = AmbientAudioService();

  // Duration selection in minutes
  final List<int> _durationOptions = [5, 10, 15, 30, 60];
  late int _selectedDurationMinutes;
  late int _totalSeconds;
  int _secondsRemaining = 0;
  int _elapsedSeconds = 0;
  bool _isPlaying = true;
  Timer? _timer;

  // Ambient sound selection
  AmbientSoundType _selectedSound = AmbientSoundType.singingBowl;
  final double _ambientVolume = 0.6;

  // 4 Guided stages
  final List<_MeditationStage> _stages = const [
    _MeditationStage(
      title: 'Arrival & Posture',
      guide: 'Find a comfortable position. Softly close your eyes and let your shoulders drop.',
      icon: Icons.chair_rounded,
    ),
    _MeditationStage(
      title: 'Breath Awareness',
      guide: 'Observe your natural breath. Feel the subtle cool air entering and warm air leaving.',
      icon: Icons.air_rounded,
    ),
    _MeditationStage(
      title: 'Stillness & Clarity',
      guide: 'Allow thoughts to pass like clouds in the sky. Rest in open, peaceful awareness.',
      icon: Icons.spa_rounded,
    ),
    _MeditationStage(
      title: 'Gentle Return',
      guide: 'Slowly deepen your breath. Feel your fingers and toes, carrying this peace into your day.',
      icon: Icons.wb_sunny_rounded,
    ),
  ];

  int get _currentStageIndex {
    if (_totalSeconds <= 0) return 0;
    final progress = _elapsedSeconds / _totalSeconds;
    if (progress < 0.25) return 0;
    if (progress < 0.55) return 1;
    if (progress < 0.85) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _selectedDurationMinutes = 15;
    _totalSeconds = _selectedDurationMinutes * 60;
    _secondsRemaining = _totalSeconds;

    // Start ambient sound
    _audioService.setVolume(_ambientVolume);
    _audioService.play(_selectedSound);

    _startTimer();
  }

  void _changeDuration(int minutes) {
    setState(() {
      _selectedDurationMinutes = minutes;
      _totalSeconds = minutes * 60;
      _secondsRemaining = _totalSeconds;
      _elapsedSeconds = 0;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!_isPlaying) return;

      setState(() {
        _elapsedSeconds++;
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _audioService.playChime(frequency: 528.0, durationSeconds: 3.0);
        }
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _audioService.resume();
      } else {
        _audioService.pause();
      }
    });
  }

  void _setAmbientSound(AmbientSoundType type) {
    setState(() {
      _selectedSound = type;
      _audioService.play(type);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.stop();
    super.dispose();
  }

  String _formatTime(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_currentStageIndex];
    final progress = _totalSeconds > 0 ? (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Serene Wellness Canvas
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Duration Selector Chips (5m, 10m, 15m, 30m, 60m) - HIGH CONTRAST & VISIBLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _durationOptions.map((mins) {
                  final isSelected = mins == _selectedDurationMinutes;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _changeDuration(mins),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: AppColors.primary.withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withAlpha(6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                          ],
                        ),
                        child: Text(
                          '${mins}m',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Circular Timer with Pulsing Aura in Light Theme
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ambient Aura
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withAlpha(15),
                    ),
                  ),
                  // Background ring
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: const CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      color: AppColors.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Digital Time
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(stage.icon, color: AppColors.primary, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Stage ${_currentStageIndex + 1} of 4',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Stage Title & Guided Affirmation Card (Light aesthetic)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      stage.title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stage.guide,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ambient Soundscape Selector Strip (Light floating pill bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSoundOption(AmbientSoundType.singingBowl, '🔔 Singing Bowl'),
                      _buildSoundOption(AmbientSoundType.rain, '🌧️ Rain'),
                      _buildSoundOption(AmbientSoundType.ocean, '🌊 Waves'),
                      _buildSoundOption(AmbientSoundType.forest, '🌲 Forest'),
                      _buildSoundOption(AmbientSoundType.silence, '🔇 Mute'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Controls & Finish Button
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
                      onPressed: _togglePlayPause,
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

  Widget _buildSoundOption(AmbientSoundType type, String label) {
    final isSelected = _selectedSound == type;
    return GestureDetector(
      onTap: () => _setAmbientSound(type),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _MeditationStage {
  final String title;
  final String guide;
  final IconData icon;

  const _MeditationStage({
    required this.title,
    required this.guide,
    required this.icon,
  });
}
