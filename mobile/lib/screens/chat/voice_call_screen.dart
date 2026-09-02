import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import '../../models/avatar_model.dart';
import '../../utils/ambient_audio_service.dart';
import '../../services/voice_audio_service.dart';

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
  bool _isAiSpeaking = false;
  bool _isListening = false;

  String _currentDialogue = "Connecting to Kausap Voice...";
  String _userSpeechBuffer = "";

  Timer? _pollTimer;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Start Call Timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _callSeconds++);
    });

    // Play greeting chime and speak greeting out loud
    _audioService.playChime(frequency: 440.0, durationSeconds: 0.8);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        final greeting = "Kumusta! I'm ${widget.avatar.name}. I'm listening. Tell me what's on your mind today.";
        _aiSpeak(greeting);
      }
    });

    if (kIsWeb) {
      _startSpeechPoller();
    }
  }

  void _startSpeechPoller() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_isAiSpeaking || _isMuted) return;

      try {
        final transcript = js.context['window']['_kausapVoiceTranscript'] as String?;
        if (transcript != null && transcript.isNotEmpty && transcript != _userSpeechBuffer) {
          setState(() {
            _userSpeechBuffer = transcript;
            _currentDialogue = 'You: "$transcript"';
          });

          // Reset silence timer to wait for student to finish sentence
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(milliseconds: 1600), () {
            if (_userSpeechBuffer.trim().isNotEmpty && !_isAiSpeaking) {
              final spoken = _userSpeechBuffer;
              js.context.callMethod('eval', ['window._kausapVoiceTranscript = "";']);
              _processUserSpokenInput(spoken);
            }
          });
        }
      } catch (_) {}
    });
  }

  void _startListening() {
    if (_isMuted || _isAiSpeaking || !kIsWeb) return;
    try {
      final jsCode = '''
      (function() {
        var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRec) return;
        if (window._kausapVoiceRec) {
          try { window._kausapVoiceRec.stop(); } catch(e) {}
        }
        var rec = new SpeechRec();
        rec.continuous = true;
        rec.interimResults = true;
        rec.lang = 'en-PH';
        window._kausapVoiceRec = rec;

        rec.onresult = function(event) {
          var transcript = '';
          for (var i = 0; i < event.results.length; ++i) {
            transcript += event.results[i][0].transcript + ' ';
          }
          if (transcript.trim().length > 0) {
            window._kausapVoiceTranscript = transcript.trim();
          }
        };

        rec.start();
      })();
      ''';
      js.context.callMethod('eval', [jsCode]);
      setState(() => _isListening = true);
    } catch (_) {}
  }

  void _stopListening() {
    if (!kIsWeb) return;
    try {
      final jsCode = '''
      (function() {
        if (window._kausapVoiceRec) {
          try { window._kausapVoiceRec.stop(); } catch(e) {}
          window._kausapVoiceRec = null;
        }
      })();
      ''';
      js.context.callMethod('eval', [jsCode]);
      if (mounted) setState(() => _isListening = false);
    } catch (_) {}
  }

  void _aiSpeak(String text, {String? emotion}) {
    if (!mounted) return;
    setState(() {
      _isAiSpeaking = true;
      _currentDialogue = text;
    });

    _stopListening();

    if (_isSpeakerOn) {
      VoiceAudioService().speak(
        text,
        emotion: emotion,
        onDone: () {
          if (mounted) {
            setState(() {
              _isAiSpeaking = false;
              _userSpeechBuffer = "";
            });
            _startListening();
          }
        },
      );
    } else {
      final wordCount = text.split(' ').length;
      final speakDuration = Duration(milliseconds: (wordCount * 320).clamp(2400, 7500));
      Future.delayed(speakDuration, () {
        if (mounted) {
          setState(() {
            _isAiSpeaking = false;
            _userSpeechBuffer = "";
          });
          _startListening();
        }
      });
    }
  }

  void _processUserSpokenInput(String userInput) {
    final lower = userInput.toLowerCase();
    String reply;
    String emotion = 'neutral';

    if (lower.contains('depre') || lower.contains('sad') || lower.contains('lungkot') || lower.contains('crying')) {
      reply = "I hear the sadness in your voice. Please know that it's okay to feel this way, and you are not alone. Let's take a slow breath together.";
      emotion = 'sad';
    } else if (lower.contains('family') || lower.contains('parents') || lower.contains('mom') || lower.contains('dad')) {
      reply = "Family situations can be so overwhelming. Your feelings are completely valid. What's been the hardest part for you recently?";
      emotion = 'sad';
    } else if (lower.contains('stress') || lower.contains('exam') || lower.contains('school') || lower.contains('study') || lower.contains('thesis')) {
      reply = "Academic stress can feel like a heavy burden. Remember that your grades don't define your worth. Have you taken a short break today?";
      emotion = 'sad';
    } else if (lower.contains('anxious') || lower.contains('panic') || lower.contains('scared') || lower.contains('kaba')) {
      reply = "I'm right here with you. Let's ground ourselves: feel your feet on the floor and breathe in for 4 seconds... and breathe out.";
      emotion = 'sad';
    } else if (lower.contains('sleep') || lower.contains('tired') || lower.contains('insomnia')) {
      reply = "Rest is so essential. When your mind is racing, try not to fight it. Just breathe gently and allow yourself to pause.";
      emotion = 'sad';
    } else if (lower.contains('happy') || lower.contains('masaya') || lower.contains('salamat') || lower.contains('thanks') || lower.contains('gumaan')) {
      reply = "I'm so glad to hear that! Knowing that you're feeling a bit lighter makes my day. How else can I support you today?";
      emotion = 'happy';
    } else if (lower.contains('passed') || lower.contains('pasa') || lower.contains('nanalo') || lower.contains('won') || lower.contains('congrats')) {
      reply = "Congratulations! That is such wonderful news! I am so proud of your hard work and perseverance!";
      emotion = 'excited';
    } else if (lower.contains('giving up') || lower.contains('die') || lower.contains('suicide') || lower.contains('end it')) {
      reply = "I hear how much pain you're in. You are deeply valued, and support is here. You can call the 24/7 NCMH hotline at 1553 anytime.";
      emotion = 'sad';
    } else {
      reply = "Thank you for sharing that with me. I'm listening closely. Tell me more about what you're feeling right now.";
      emotion = 'curious';
    }

    _aiSpeak(reply, emotion: emotion);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pollTimer?.cancel();
    _silenceTimer?.cancel();
    _stopListening();
    VoiceAudioService().stopSpeaking();
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
      backgroundColor: const Color(0xFF0F172A),
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
                        _isAiSpeaking
                            ? 'Speaking...'
                            : (_isListening ? 'Listening to you...' : 'Voice Call • ${_formatCallDuration(_callSeconds)}'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _isAiSpeaking
                              ? const Color(0xFF38BDF8)
                              : (_isListening ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8)),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: _isSpeakerOn ? const Color(0xFF38BDF8) : Colors.white54,
                    ),
                    onPressed: () {
                      setState(() => _isSpeakerOn = !_isSpeakerOn);
                      if (!_isSpeakerOn && kIsWeb) {
                        try {
                          js.context.callMethod('eval', ['if ("speechSynthesis" in window) window.speechSynthesis.cancel();']);
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Animated Avatar Waveform Center
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                final scale = _isAiSpeaking ? _waveController.value : (_isListening ? 0.3 : 0.05);
                final waveColor = _isAiSpeaking ? const Color(0xFF38BDF8) : const Color(0xFF4ADE80);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsating wave
                    Container(
                      width: 220 + (40 * scale),
                      height: 220 + (40 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: waveColor.withAlpha((35 * (1 - scale * 0.4)).toInt()),
                      ),
                    ),
                    // Middle wave
                    Container(
                      width: 170 + (25 * scale),
                      height: 170 + (25 * scale),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: waveColor.withAlpha((60 * (1 - scale * 0.4)).toInt()),
                      ),
                    ),
                    // Avatar circle
                    Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isAiSpeaking ? const Color(0xFF38BDF8) : (_isListening ? const Color(0xFF4ADE80) : Colors.white24),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: waveColor.withAlpha(100),
                            blurRadius: 24,
                            spreadRadius: 3,
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

            // Live Spoken Dialogue Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isAiSpeaking
                        ? const Color(0xFF38BDF8).withAlpha(120)
                        : (_isListening ? const Color(0xFF4ADE80).withAlpha(120) : Colors.white.withAlpha(30)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAiSpeaking
                          ? Icons.volume_up_rounded
                          : (_isListening ? Icons.mic_rounded : Icons.graphic_eq_rounded),
                      color: _isAiSpeaking
                          ? const Color(0xFF38BDF8)
                          : (_isListening ? const Color(0xFF4ADE80) : Colors.white70),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _currentDialogue,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
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
                    bgColor: _isMuted ? Colors.red.withAlpha(50) : Colors.white12,
                    iconColor: _isMuted ? const Color(0xFFF87171) : Colors.white,
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      if (_isMuted) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
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

                  // Grounding Calm Resonance Button
                  _CallControlBtn(
                    icon: Icons.spa_rounded,
                    label: 'Grounding',
                    bgColor: Colors.white12,
                    iconColor: const Color(0xFF34D399),
                    onTap: () {
                      _audioService.playChime(frequency: 528.0, durationSeconds: 1.5);
                      _aiSpeak("Let's pause together and listen to this 528 hertz calming resonance. Breathe in slowly... and let go.");
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
