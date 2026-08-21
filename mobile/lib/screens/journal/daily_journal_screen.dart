import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import '../../theme/app_theme.dart';
import 'journal_history_screen.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final DateTime _today = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isListening = false;
  Timer? _speechTimer;

  @override
  void initState() {
    super.initState();
    _loadTodayJournal();
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _stopSpeechRecognition();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayJournal() async {
    setState(() => _isLoading = true);
    final dateKey = DateFormat('yyyy-MM-dd').format(_today);
    
    try {
      final savedJournal = await _storage.read(key: 'journal_$dateKey');
      if (mounted) {
        setState(() {
          if (savedJournal != null && savedJournal.isNotEmpty) {
            _journalController.text = savedJournal;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Voice dictation toggle for web & mobile
  void _toggleSpeechRecognition() {
    if (_isListening) {
      _stopSpeechRecognition();
    } else {
      _startSpeechRecognition();
    }
  }

  void _startSpeechRecognition() {
    setState(() => _isListening = true);

    if (kIsWeb) {
      try {
        const jsCode = '''
        (function() {
          var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
          if (!SpeechRec) {
            alert("Speech recognition is not supported in this browser. Please use Chrome, Edge, or Safari.");
            return;
          }
          var rec = new SpeechRec();
          rec.continuous = true;
          rec.interimResults = true;
          rec.lang = 'en-US';
          window._kausapJournalSpeechRec = rec;
          window._kausapJournalTranscript = "";

          rec.onresult = function(event) {
            var transcript = '';
            for (var i = event.resultIndex; i < event.results.length; ++i) {
              if (event.results[i].isFinal) {
                transcript += event.results[i][0].transcript;
              }
            }
            if (transcript.trim().length > 0) {
              window._kausapJournalTranscript = transcript;
            }
          };

          rec.onerror = function(e) {
            console.log("Speech recognition error:", e);
            window._kausapJournalSpeechRec = null;
          };

          rec.start();
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);

        // Poll speech results periodically to append to controller
        _speechTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
          if (!mounted || !_isListening) {
            timer.cancel();
            return;
          }
          try {
            final transcript = js.context['window']['_kausapJournalTranscript'] as String?;
            if (transcript != null && transcript.trim().isNotEmpty) {
              js.context.callMethod('eval', ['window._kausapJournalTranscript = "";']);
              setState(() {
                final current = _journalController.text;
                if (current.isEmpty) {
                  _journalController.text = transcript.trim();
                } else {
                  _journalController.text = '$current ${transcript.trim()}';
                }
                _journalController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _journalController.text.length),
                );
              });
            }
          } catch (_) {}
        });
      } catch (e) {
        setState(() => _isListening = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listening to voice input...')),
      );
    }
  }

  void _stopSpeechRecognition() {
    setState(() => _isListening = false);
    _speechTimer?.cancel();
    _speechTimer = null;

    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          'if (window._kausapJournalSpeechRec) { try { window._kausapJournalSpeechRec.stop(); } catch(e){} window._kausapJournalSpeechRec = null; }'
        ]);
      } catch (_) {}
    }
  }

  Future<void> _saveJournal() async {
    final content = _journalController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write or record something before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    _stopSpeechRecognition();

    final dateKey = DateFormat('yyyy-MM-dd').format(_today);
    
    try {
      await _storage.write(key: 'journal_$dateKey', value: content);

      // Append to unified journal_history
      final rawHistory = await _storage.read(key: 'journal_history');
      final List<dynamic> history = rawHistory != null ? jsonDecode(rawHistory) as List : [];
      history.removeWhere((e) => e['date'] == dateKey);
      history.insert(0, {
        'id': dateKey,
        'date': dateKey,
        'type': 'freeform',
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _storage.write(key: 'journal_history', value: jsonEncode(history));
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal saved! ✅ Daily quest updated.'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true); // Pop with true so Home refreshes quests
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('EEEE, MMMM d, yyyy').format(_today);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Daily Journal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
            tooltip: 'View Past Journals',
            onPressed: () async {
              _stopSpeechRecognition();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalHistoryScreen()),
              );
              _loadTodayJournal();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today Date Banner (Clean, without redundant button)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFD97706), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "TODAY'S JOURNAL",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateDisplay,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Prompt Title
                    const Text(
                      'How was your day?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Write down your thoughts, reflections, or whatever is on your mind.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Journal Text Input Area with Single Smart Mic
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isListening ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                            width: _isListening ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _journalController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                height: 1.55,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? '🎙️ Listening... Speak naturally to dictate your journal entry.'
                                    : 'Start typing here, or tap the microphone to speak your thoughts...',
                                hintStyle: TextStyle(
                                  color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                  fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 70),
                              ),
                            ),

                            // Single Smart Mic Dictation Button inside Text Box
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Row(
                                children: [
                                  if (_isListening)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record_rounded, color: Color(0xFFEF4444), size: 12),
                                          SizedBox(width: 6),
                                          Text(
                                            'Listening...',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),

                                  // Voice Dictation Tap Button
                                  Tooltip(
                                    message: _isListening ? 'Stop Dictation' : 'Start Voice Dictation',
                                    child: Material(
                                      color: _isListening ? const Color(0xFFEF4444) : AppColors.primary,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        onTap: _toggleSpeechRecognition,
                                        customBorder: const CircleBorder(),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Icon(
                                            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveJournal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'Save Entry & Complete Quest',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
