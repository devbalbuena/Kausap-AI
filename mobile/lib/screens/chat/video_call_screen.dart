import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/avatar_model.dart';
import '../../utils/ambient_audio_service.dart';

class VideoCallScreen extends StatefulWidget {
  final AvatarModel avatar;

  const VideoCallScreen({super.key, required this.avatar});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final AmbientAudioService _audioService = AmbientAudioService();

  int _callSeconds = 0;
  Timer? _callTimer;
  bool _isMuted = false;
  bool _isCameraOn = true;

  final List<String> _captions = [
    "Hello! It's so good to see you today.",
    "I'm here to give you my full attention.",
    "Whatever you're facing, you don't have to carry it alone.",
    "Let's take a slow breath together whenever you're ready.",
  ];
  int _captionIndex = 0;
  Timer? _captionTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _callSeconds++);
    });

    _audioService.playChime(frequency: 587.33, durationSeconds: 0.9);

    _captionTimer = Timer.periodic(const Duration(seconds: 6), (t) {
      if (mounted) {
        setState(() {
          _captionIndex = (_captionIndex + 1) % _captions.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _captionTimer?.cancel();
    _animController.dispose();
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen Avatar Video Feed
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final scale = 1.0 + (_animController.value * 0.03);
                return Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    widget.avatar.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF0F172A),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white24, size: 100),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle Dark Gradient Overlay for Controls Visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(150),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Top Header (Avatar name + Duration)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.avatar.name} • ${_formatCallDuration(_callSeconds)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance spacing
                  ],
                ),
              ),
            ),
          ),

          // Picture-in-Picture (Student self preview)
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isCameraOn
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: const Color(0xFF334155),
                            child: const Center(
                              child: Icon(Icons.person_rounded, color: Colors.white54, size: 42),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 30),
                      ),
              ),
            ),
          ),

          // Live Subtitles / Speech Closed Captions
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Container(
                key: ValueKey(_captionIndex),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.closed_caption_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _captions[_captionIndex],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
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

          // Bottom Controls (Mute, Camera, Flip, End Call)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Toggle
                _VideoControlBtn(
                  icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  label: _isCameraOn ? 'Cam On' : 'Cam Off',
                  bgColor: _isCameraOn ? Colors.white12 : Colors.white24,
                  onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                ),

                // Mute Mic Toggle
                _VideoControlBtn(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  bgColor: _isMuted ? Colors.white24 : Colors.white12,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),

                // End Call Button (Red)
                _VideoControlBtn(
                  icon: Icons.call_end_rounded,
                  label: 'End',
                  bgColor: const Color(0xFFEF4444),
                  isEnd: true,
                  onTap: () {
                    _audioService.playChime(frequency: 330.0, durationSeconds: 0.5);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isEnd;

  const _VideoControlBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.onTap,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isEnd ? 64 : 52,
            height: isEnd ? 64 : 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (isEnd)
                  BoxShadow(
                    color: const Color(0xFFEF4444).withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isEnd ? 30 : 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
