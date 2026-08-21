import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/avatar_model.dart';
import '../../utils/ambient_audio_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final AvatarModel avatar;

  const VoiceCallScreen({super.key, required this.avatar});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final AmbientAudioService _audioService = AmbientAudioService();

  int _callSeconds = 0;
  Timer? _callTimer;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  final List<String> _spokenPrompts = [
    "Kumusta! I'm listening. Take all the time you need.",
    "Breathe in gently... I'm right here with you.",
    "Tell me more about what's been on your mind.",
    "You are doing great just by checking in today.",
  ];
  int _currentPromptIndex = 0;
  Timer? _promptTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Start Call Timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _callSeconds++);
    });

    // Play initial gentle chime
    _audioService.playChime(frequency: 440.0, durationSeconds: 0.8);

    // Cycle supportive prompts
    _promptTimer = Timer.periodic(const Duration(seconds: 7), (t) {
      if (mounted) {
        setState(() {
          _currentPromptIndex = (_currentPromptIndex + 1) % _spokenPrompts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _promptTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  String _formatCallDuration(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek immersive dark mode for call
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.avatar.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Voice Call • ${_formatCallDuration(_callSeconds)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Animated Avatar Waveform Center
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                final scale = _waveController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsating wave
                    Container(
                      width: 220 + (30 * scale),
                      height: 220 + (30 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38BDF8).withAlpha((25 * (1 - scale * 0.5)).toInt()),
                      ),
                    ),
                    // Middle wave
                    Container(
                      width: 170 + (20 * scale),
                      height: 170 + (20 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38BDF8).withAlpha((45 * (1 - scale * 0.5)).toInt()),
                      ),
                    ),
                    // Avatar circle
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF38BDF8), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withAlpha(100),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          widget.avatar.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFF1E293B),
                            child: const Icon(Icons.person, color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 36),

            // Live Spoken Prompt Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey(_currentPromptIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: Color(0xFF38BDF8), size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _spokenPrompts[_currentPromptIndex],
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Bottom Call Action Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Mic Button
                  _CallControlBtn(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    bgColor: _isMuted ? Colors.white24 : Colors.white12,
                    iconColor: Colors.white,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),

                  // End Call Button (Red)
                  _CallControlBtn(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    bgColor: const Color(0xFFEF4444),
                    iconColor: Colors.white,
                    isMainEnd: true,
                    onTap: () {
                      _audioService.playChime(frequency: 330.0, durationSeconds: 0.5);
                      Navigator.pop(context);
                    },
                  ),

                  // Audio Grounding Button
                  _CallControlBtn(
                    icon: Icons.spa_rounded,
                    label: 'Grounding',
                    bgColor: Colors.white12,
                    iconColor: const Color(0xFF34D399),
                    onTap: () {
                      _audioService.playChime(frequency: 528.0, durationSeconds: 1.5);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing 528Hz calming grounding resonance...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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

class _CallControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isMainEnd;

  const _CallControlBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.isMainEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isMainEnd ? 68 : 54,
            height: isMainEnd ? 68 : 54,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (isMainEnd)
                  BoxShadow(
                    color: const Color(0xFFEF4444).withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: isMainEnd ? 32 : 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
