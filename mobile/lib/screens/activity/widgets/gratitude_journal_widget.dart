import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import '../../../theme/app_theme.dart';
import '../../../utils/ambient_audio_service.dart';
import '../activity_screen.dart';
import '../../journal/journal_history_screen.dart';

enum _JournalMode { guided, freeform }

class GratitudeJournalWidget extends StatefulWidget {
  final ActivityItem activity;
  final VoidCallback onComplete;

  const GratitudeJournalWidget({
    super.key,
    required this.activity,
    required this.onComplete,
  });

  @override
  State<GratitudeJournalWidget> createState() => _GratitudeJournalWidgetState();
}

class _GratitudeJournalWidgetState extends State<GratitudeJournalWidget> {
  static const _storage = FlutterSecureStorage();
  final AmbientAudioService _audioService = AmbientAudioService();

  _JournalMode _mode = _JournalMode.guided;

  // Guided prompt controllers
  final TextEditingController _prompt1Controller = TextEditingController();
  final TextEditingController _prompt2Controller = TextEditingController();
  final TextEditingController _prompt3Controller = TextEditingController();

  // Free-form controller
  final TextEditingController _freeformController = TextEditingController();

  bool _isSpeechListening = false;
  bool _isSaving = false;

  final List<String> _prompts = const [
    '☀️ What is one small thing that brought a smile to your face today?',
    '🤝 Who is someone you appreciate, and what did they do?',
    '🌟 What is a moment, effort, or personal win you feel good about?',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingEntries();
  }

  Future<void> _loadExistingEntries() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedGratitude = await _storage.read(key: 'gratitude_$today');
    if (savedGratitude != null && savedGratitude.isNotEmpty) {
      final parts = savedGratitude.split('---SPLIT---');
      if (parts.isNotEmpty) _prompt1Controller.text = parts[0];
      if (parts.length > 1) _prompt2Controller.text = parts[1];
      if (parts.length > 2) _prompt3Controller.text = parts[2];
    }

    final savedFreeform = await _storage.read(key: 'journal_$today');
    if (savedFreeform != null && savedFreeform.isNotEmpty && !savedFreeform.contains('Gratitude Reflection:')) {
      _freeformController.text = savedFreeform;
    }
  }

  /// Free built-in Web Speech recognition without any API keys!
  void _toggleSpeechRecognition() {
    if (_isSpeechListening) {
      setState(() => _isSpeechListening = false);
      if (kIsWeb) {
        try {
          js.context.callMethod('eval', ['if (window._kausapSpeechRec) { window._kausapSpeechRec.stop(); }']);
        } catch (_) {}
      }
      return;
    }

    setState(() => _isSpeechListening = true);

    if (kIsWeb) {
      try {
        final jsCode = '''
        (function() {
          var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
          if (!SpeechRec) {
            alert("Speech recognition is not supported in this browser. Please use Chrome or Edge.");
            return;
          }
          var rec = new SpeechRec();
          rec.continuous = true;
          rec.interimResults = true;
          rec.lang = 'en-US';
          window._kausapSpeechRec = rec;

          rec.onresult = function(event) {
            var transcript = '';
            for (var i = event.resultIndex; i < event.results.length; ++i) {
              if (event.results[i].isFinal) {
                transcript += event.results[i][0].transcript;
              }
            }
            if (transcript.trim().length > 0) {
              window._kausapLastSpeech = transcript;
            }
          };

          rec.onerror = function() {
            window._kausapSpeechRec = null;
          };

          rec.start();
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);

        // Poll speech results periodically to append text
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (!mounted || !_isSpeechListening) {
            timer.cancel();
            return;
          }
          try {
            final lastSpeech = js.context['window']['_kausapLastSpeech'] as String?;
            if (lastSpeech != null && lastSpeech.isNotEmpty) {
              js.context.callMethod('eval', ['window._kausapLastSpeech = "";']);
              setState(() {
                if (_mode == _JournalMode.guided) {
                  if (_prompt1Controller.text.isEmpty) {
                    _prompt1Controller.text = lastSpeech;
                  } else {
                    _prompt1Controller.text += ' $lastSpeech';
                  }
                } else {
                  if (_freeformController.text.isEmpty) {
                    _freeformController.text = lastSpeech;
                  } else {
                    _freeformController.text += ' $lastSpeech';
                  }
                }
              });
            }
          } catch (_) {}
        });
      } catch (_) {}
    }
  }

  Future<void> _saveAndComplete() async {
    setState(() => _isSaving = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String entryContent = '';
    if (_mode == _JournalMode.guided) {
      final p1 = _prompt1Controller.text.trim();
      final p2 = _prompt2Controller.text.trim();
      final p3 = _prompt3Controller.text.trim();
      final fullJournal = [p1, p2, p3].join('---SPLIT---');
      entryContent = 'Gratitude Reflection:\n1. $p1\n2. $p2\n3. $p3';
      await _storage.write(key: 'gratitude_$today', value: fullJournal);
    } else {
      entryContent = _freeformController.text.trim();
    }

    // Save unified daily journal
    await _storage.write(key: 'journal_$today', value: entryContent);

    // Append to unified journal_history
    try {
      final rawHistory = await _storage.read(key: 'journal_history');
      final List<dynamic> history = rawHistory != null ? jsonDecode(rawHistory) as List : [];
      // Remove today if already exists to update it
      history.removeWhere((e) => e['date'] == today);
      history.insert(0, {
        'id': today,
        'date': today,
        'type': _mode == _JournalMode.guided ? 'guided' : 'freeform',
        'content': entryContent,
        'mood': '5',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _storage.write(key: 'journal_history', value: jsonEncode(history));
    } catch (_) {}

    _audioService.playChime(frequency: 528.0, durationSeconds: 2.0);

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    if (_isSpeechListening && kIsWeb) {
      try {
        js.context.callMethod('eval', ['if (window._kausapSpeechRec) { window._kausapSpeechRec.stop(); }']);
      } catch (_) {}
    }
    _prompt1Controller.dispose();
    _prompt2Controller.dispose();
    _prompt3Controller.dispose();
    _freeformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Daily Journal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Speech-to-text dictation button
          IconButton(
            icon: Icon(
              _isSpeechListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isSpeechListening ? Colors.red : AppColors.primary,
            ),
            onPressed: _toggleSpeechRecognition,
            tooltip: 'Speak to Write (Web Speech)',
          ),
          // Past history button
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalHistoryScreen()),
              );
            },
            tooltip: 'Journal History',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector Bar (Guided Prompts vs Free-Form)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = _JournalMode.guided),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mode == _JournalMode.guided ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _mode == _JournalMode.guided
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '💡 3 Guided Prompts',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                fontWeight: _mode == _JournalMode.guided ? FontWeight.w700 : FontWeight.w500,
                                color: _mode == _JournalMode.guided ? AppColors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = _JournalMode.freeform),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mode == _JournalMode.freeform ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _mode == _JournalMode.freeform
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '✍️ Free-Form Journal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                fontWeight: _mode == _JournalMode.freeform ? FontWeight.w700 : FontWeight.w500,
                                color: _mode == _JournalMode.freeform ? AppColors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active Speech banner
            if (_isSpeechListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Listening... Speak clearly to write automatically.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleSpeechRecognition,
                      child: const Text('Stop', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Content Editor
            Expanded(
              child: _mode == _JournalMode.guided ? _buildGuidedView() : _buildFreeformView(),
            ),

            // Save & Complete Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                  ),
                  onPressed: _isSaving ? null : _saveAndComplete,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save & Complete Journal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildPromptCard(
          prompt: _prompts[0],
          controller: _prompt1Controller,
          hint: 'e.g. A warm morning drink, a joke from a friend...',
          color: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFDE68A),
        ),
        const SizedBox(height: 14),
        _buildPromptCard(
          prompt: _prompts[1],
          controller: _prompt2Controller,
          hint: 'e.g. My classmate who shared notes, my professor...',
          color: const Color(0xFFE0F2FE),
          borderColor: const Color(0xFFBAE6FD),
        ),
        const SizedBox(height: 14),
        _buildPromptCard(
          prompt: _prompts[2],
          controller: _prompt3Controller,
          hint: 'e.g. Stayed focused during study, kept my calm...',
          color: const Color(0xFFEDE9FE),
          borderColor: const Color(0xFFDDD6FE),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFreeformView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('✍️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text(
                    'Open Journal & Thoughts',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Write freely about your day, emotions, breakthroughs, or anything on your mind.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const Divider(height: 20),
              TextField(
                controller: _freeformController,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Start typing or tap the microphone to speak your thoughts...',
                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard({
    required String prompt,
    required TextEditingController controller,
    required String hint,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              prompt,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
