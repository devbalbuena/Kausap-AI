import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

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
  bool _isAiSpeaking = false;

  String _currentSubtitle = "Connecting video feed...";

  final List<String> _companionPrompts = [
    "Hello! It's so good to see you today. I'm right here with you.",
    "Take all the time you need. How is your day going so far?",
    "Remember to be gentle with yourself. You're doing the best you can.",
    "Let's take a slow breath together whenever you're ready.",
  ];
  int _promptIndex = 0;
  Timer? _dialogueCycleTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _callSeconds++);
    });

    _audioService.playChime(frequency: 587.33, durationSeconds: 0.9);

    if (kIsWeb) {
      _startWebcam();
    }

    // Initial greeting out loud
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _speakCompanion(_companionPrompts[0]);
      }
    });

    // Cycle supportive voice guidance every 12 seconds
    _dialogueCycleTimer = Timer.periodic(const Duration(seconds: 14), (t) {
      if (mounted && !_isMuted) {
        _promptIndex = (_promptIndex + 1) % _companionPrompts.length;
        _speakCompanion(_companionPrompts[_promptIndex]);
      }
    });
  }

  void _startWebcam() {
    if (!kIsWeb) return;
    try {
      final jsCode = '''
      (function() {
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
          navigator.mediaDevices.getUserMedia({video: true, audio: false})
            .then(function(stream) {
              window._kausapCamStream = stream;
            })
            .catch(function(err) {});
        }
      })();
      ''';
      js.context.callMethod('eval', [jsCode]);
      if (mounted) setState(() => _isCameraOn = true);
    } catch (_) {}
  }

  void _stopWebcam() {
    if (!kIsWeb) return;
    try {
      final jsCode = '''
      (function() {
        if (window._kausapCamStream) {
          var tracks = window._kausapCamStream.getTracks();
          for (var i = 0; i < tracks.length; i++) {
            tracks[i].stop();
          }
          window._kausapCamStream = null;
        }
      })();
      ''';
      js.context.callMethod('eval', [jsCode]);
      if (mounted) setState(() => _isCameraOn = false);
    } catch (_) {}
  }

  void _speakCompanion(String text) {
    if (!mounted) return;
    setState(() {
      _isAiSpeaking = true;
      _currentSubtitle = text;
    });

    if (kIsWeb) {
      try {
        final safeText = jsonEncode(text);
        final jsCode = '''
        (function() {
          if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
            var u = new SpeechSynthesisUtterance($safeText);
            u.rate = 0.95;
            u.pitch = 1.05;
            window.speechSynthesis.speak(u);
          }
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (_) {}
    }

    final wordCount = text.split(' ').length;
    final speakDuration = Duration(milliseconds: (wordCount * 320).clamp(2400, 7500));
    Future.delayed(speakDuration, () {
      if (mounted) setState(() => _isAiSpeaking = false);
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _dialogueCycleTimer?.cancel();
    _stopWebcam();
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['if ("speechSynthesis" in window) window.speechSynthesis.cancel();']);
      } catch (_) {}
    }
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
          // Fullscreen Avatar Video Feed with Subtle Breathing Scale
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final scale = 1.0 + (_animController.value * (_isAiSpeaking ? 0.04 : 0.02));
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

          // Vignette Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(160),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(220),
                  ],
                  stops: const [0.0, 0.22, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Top Header (Avatar name + Duration + Indicator)
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
                            decoration: BoxDecoration(
                              color: _isAiSpeaking ? const Color(0xFF38BDF8) : const Color(0xFF22C55E),
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Picture-in-Picture Self Preview (Cam Stream / Status)
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              width: 105,
              height: 145,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isCameraOn ? const Color(0xFF4ADE80) : Colors.white.withAlpha(50),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isCameraOn
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: const Color(0xFF1E293B),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_rounded, color: Color(0xFF4ADE80), size: 28),
                                  SizedBox(height: 4),
                                  Text(
                                    'Camera Active',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Colors.white70),
                                  ),
                                ],
                              ),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 26),
                            SizedBox(height: 4),
                            Text('Cam Off', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white38)),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // Live Subtitles Closed Captions
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Container(
                key: ValueKey(_currentSubtitle),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAiSpeaking ? const Color(0xFF38BDF8).withAlpha(140) : Colors.white.withAlpha(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAiSpeaking ? Icons.volume_up_rounded : Icons.closed_caption_rounded,
                      color: _isAiSpeaking ? const Color(0xFF38BDF8) : Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _currentSubtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: _isAiSpeaking ? FontWeight.w600 : FontWeight.w400,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls (Cam Toggle, Mic Mute, End Call)
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
                  bgColor: _isCameraOn ? const Color(0xFF22C55E).withAlpha(40) : Colors.white12,
                  iconColor: _isCameraOn ? const Color(0xFF4ADE80) : Colors.white60,
                  onTap: () {
                    if (_isCameraOn) {
                      _stopWebcam();
                    } else {
                      _startWebcam();
                    }
                  },
                ),

                // Mic Mute Toggle
                _VideoControlBtn(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  bgColor: _isMuted ? Colors.red.withAlpha(40) : Colors.white12,
                  iconColor: _isMuted ? const Color(0xFFF87171) : Colors.white,
                  onTap: () {
                    setState(() => _isMuted = !_isMuted);
                    if (_isMuted && kIsWeb) {
                      try {
                        js.context.callMethod('eval', ['if ("speechSynthesis" in window) window.speechSynthesis.cancel();']);
                      } catch (_) {}
                    }
                  },
                ),

                // End Call Button (Red)
                _VideoControlBtn(
                  icon: Icons.call_end_rounded,
                  label: 'End',
                  bgColor: const Color(0xFFEF4444),
                  iconColor: Colors.white,
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
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isEnd;

  const _VideoControlBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    this.iconColor,
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
            child: Icon(icon, color: iconColor ?? Colors.white, size: isEnd ? 30 : 22),
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
