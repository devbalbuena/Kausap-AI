import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/ambient_audio_service.dart';
import '../activity_screen.dart';

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

  final TextEditingController _prompt1Controller = TextEditingController();
  final TextEditingController _prompt2Controller = TextEditingController();
  final TextEditingController _prompt3Controller = TextEditingController();

  bool _isVoiceRecording = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
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
    final saved = await _storage.read(key: 'gratitude_$today');
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split('---SPLIT---');
      if (parts.isNotEmpty) _prompt1Controller.text = parts[0];
      if (parts.length > 1) _prompt2Controller.text = parts[1];
      if (parts.length > 2) _prompt3Controller.text = parts[2];
    }
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isVoiceRecording = !_isVoiceRecording;
      if (_isVoiceRecording) {
        _voiceSeconds = 0;
        _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _voiceSeconds++);
        });
      } else {
        _voiceTimer?.cancel();
        // Append voice memo note to prompt 1
        if (_prompt1Controller.text.isEmpty) {
          _prompt1Controller.text = '🎙️ [Spoken Reflection recorded: $_voiceSeconds seconds]';
        } else {
          _prompt1Controller.text += '\n🎙️ [Voice Memo: $_voiceSeconds s]';
        }
      }
    });
  }

  Future<void> _saveAndComplete() async {
    setState(() => _isSaving = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final fullJournal = [
      _prompt1Controller.text.trim(),
      _prompt2Controller.text.trim(),
      _prompt3Controller.text.trim(),
    ].join('---SPLIT---');

    // Save to gratitude key and unified daily journal key
    await _storage.write(key: 'gratitude_$today', value: fullJournal);
    await _storage.write(
      key: 'journal_$today',
      value: 'Gratitude Reflection:\n1. ${_prompt1Controller.text}\n2. ${_prompt2Controller.text}\n3. ${_prompt3Controller.text}',
    );

    _audioService.playChime(frequency: 528.0, durationSeconds: 2.0);

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _prompt1Controller.dispose();
    _prompt2Controller.dispose();
    _prompt3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF), // Soft lavender tint
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Gratitude Journal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Voice recording mode button
          IconButton(
            icon: Icon(
              _isVoiceRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isVoiceRecording ? Colors.red : AppColors.primary,
            ),
            onPressed: _toggleVoiceRecording,
            tooltip: 'Audio Voice Note',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Voice Recording Banner
            if (_isVoiceRecording)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Recording Voice Note: ${_voiceSeconds}s',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Stop',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Guided Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  _buildPromptCard(
                    prompt: _prompts[0],
                    controller: _prompt1Controller,
                    hint: 'e.g. A warm cup of coffee, a text from a friend...',
                    color: const Color(0xFFFEF3C7),
                    borderColor: const Color(0xFFFDE68A),
                  ),
                  const SizedBox(height: 16),
                  _buildPromptCard(
                    prompt: _prompts[1],
                    controller: _prompt2Controller,
                    hint: 'e.g. My classmate who shared notes, my parents...',
                    color: const Color(0xFFE0F2FE),
                    borderColor: const Color(0xFFBAE6FD),
                  ),
                  const SizedBox(height: 16),
                  _buildPromptCard(
                    prompt: _prompts[2],
                    controller: _prompt3Controller,
                    hint: 'e.g. Finished my study goals, stayed calm during stress...',
                    color: const Color(0xFFEDE9FE),
                    borderColor: const Color(0xFFDDD6FE),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
                    elevation: 2,
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
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.grey.shade400,
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
