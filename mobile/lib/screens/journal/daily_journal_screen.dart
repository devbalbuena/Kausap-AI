import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../utils/haptic_service.dart';
import 'journal_history_screen.dart';

class DailyJournalScreen extends StatefulWidget {
  final Map<String, dynamic>? entryToEdit;

  const DailyJournalScreen({super.key, this.entryToEdit});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final DateTime _today = DateTime.now();
  
  bool _isSaving = false;
  bool _isListening = false;
  bool _isDisposed = false;  // Guard against setState after dispose
  Timer? _speechTimer;

  String _selectedMoodTag = '🌿 Calm';
  String? _activePrompt;

  static const List<String> _moodTags = [
    '🌿 Calm',
    '😊 Grateful',
    '💭 Reflective',
    '⚡ Stressed',
    '💪 Motivated',
    '🌧️ Down',
  ];

  static const List<String> _promptTemplates = [
    '🌟 Best moment of my day:',
    '💖 3 things I am grateful for today:',
    '🧠 What is on my mind right now:',
    '🎯 One small win I had today:',
    '🍃 How I took care of myself today:',
  ];

  bool get _isEditing => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final entry = widget.entryToEdit!;
      _journalController.text = entry['content']?.toString() ?? '';
      _selectedMoodTag = entry['mood_tag']?.toString() ?? entry['type']?.toString() ?? '🌿 Calm';
      _activePrompt = entry['prompt']?.toString();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speechTimer?.cancel();
    _speechTimer = null;
    // Stop speech recognition without calling setState (widget already disposed)
    _stopSpeechEngineOnly();
    _journalController.dispose();
    super.dispose();
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
    if (!_isDisposed && mounted) {
      setState(() => _isListening = false);
    } else {
      _isListening = false;
    }
    _speechTimer?.cancel();
    _speechTimer = null;
    _stopSpeechEngineOnly();
  }

  /// Stops the JS speech engine only — safe to call from dispose() without setState
  void _stopSpeechEngineOnly() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          'if (window._kausapJournalSpeechRec) { try { window._kausapJournalSpeechRec.stop(); } catch(e){} window._kausapJournalSpeechRec = null; }'
        ]);
      } catch (_) {}
    }
  }

  void _insertPrompt(String prompt) {
    HapticService.lightTap();
    setState(() {
      _activePrompt = prompt;
      final current = _journalController.text.trim();
      if (current.isEmpty) {
        _journalController.text = '$prompt\n- ';
      } else {
        _journalController.text = '$current\n\n$prompt\n- ';
      }
      _journalController.selection = TextSelection.fromPosition(
        TextPosition(offset: _journalController.text.length),
      );
    });
  }

  void _clearDraft() {
    if (_journalController.text.trim().isEmpty) return;
    HapticService.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Draft?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Are you sure you want to clear your current writing?', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _journalController.clear();
                _activePrompt = null;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
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
    HapticService.mediumTap();

    final dateKey = DateFormat('yyyy-MM-dd').format(_today);
    final nowIso = DateTime.now().toIso8601String();
    
    try {
      if (_isEditing) {
        // Edit existing entry
        final entryId = widget.entryToEdit!['id']?.toString() ?? '';
        if (entryId.isNotEmpty && entryId.contains('-') && entryId.length > 20) {
          try {
            await ApiClient().put(
              '${ApiConfig.journal}/$entryId',
              body: {
                'content': content,
                'mood_tag': _selectedMoodTag,
                'prompt': _activePrompt,
              },
              silent: true,
            );
          } catch (_) {}
        }
      } else {
        // Create brand new separate entry
        try {
          await ApiClient().post(
            ApiConfig.journal,
            body: {
              'content': content,
              'entry_date': dateKey,
              'mood_tag': _selectedMoodTag,
              'prompt': _activePrompt,
            },
            silent: true,
          );
        } catch (_) {}
      }

      // Persist to local storage for offline resilience
      await _storage.write(key: 'journal_$dateKey', value: content);
      await _storage.write(key: 'journal_mood_$dateKey', value: _selectedMoodTag);

      // Append/Update unified journal_history in local storage
      final rawHistory = await _storage.read(key: 'journal_history');
      final List<dynamic> history = rawHistory != null ? jsonDecode(rawHistory) as List : [];
      
      if (_isEditing) {
        final entryId = widget.entryToEdit!['id']?.toString();
        final idx = history.indexWhere((e) => e['id']?.toString() == entryId);
        if (idx != -1) {
          history[idx]['content'] = content;
          history[idx]['mood_tag'] = _selectedMoodTag;
          history[idx]['type'] = _selectedMoodTag;
          history[idx]['prompt'] = _activePrompt;
        }
      } else {
        history.insert(0, {
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'date': dateKey,
          'entry_date': dateKey,
          'type': _selectedMoodTag,
          'mood_tag': _selectedMoodTag,
          'content': content,
          'prompt': _activePrompt,
          'created_at': nowIso,
        });
      }
      await _storage.write(key: 'journal_history', value: jsonEncode(history));
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Journal entry updated! ✅' : 'New journal entry saved! ✅ Daily quest updated.'),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true); // Return true to update home quest counter
    }
  }

  int _getWordCount() {
    final text = _journalController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('EEEE, MMMM d, yyyy').format(_today);
    final wordCount = _getWordCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Journal' : 'Daily Journal',
          style: const TextStyle(
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
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF64748B), size: 22),
              tooltip: 'Clear Draft',
              onPressed: _clearDraft,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
            tooltip: 'View Past Journals',
            onPressed: () async {
              _stopSpeechRecognition();
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalHistoryScreen()),
              );
              if (res == true && mounted) {
                // If an action occurred in history, refresh state
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today Date Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFD97706), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? "EDITING ENTRY" : "NEW ENTRY • TODAY",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            dateDisplay,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$wordCount words',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Mood Tag Selector
              const Text(
                'Emotional Tone',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _moodTags.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final tag = _moodTags[i];
                    final isSelected = _selectedMoodTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedMoodTag = tag);
                      },
                      selectedColor: const Color(0xFFE0F2FE),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Reflection Starter Prompts Chips
              const Text(
                'Starter Prompts (Tap to add)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _promptTemplates.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final prompt = _promptTemplates[i];
                    return ActionChip(
                      label: Text(prompt),
                      onPressed: () => _insertPrompt(prompt),
                      backgroundColor: Colors.white,
                      labelStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0284C7),
                      ),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Journal Text Input Area
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
                      BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 3)),
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
                          color: Color(0xFF0F172A),
                          height: 1.55,
                        ),
                        decoration: InputDecoration(
                          hintText: _isEditing
                              ? 'Edit your journal entry...'
                              : 'Write down your thoughts, reflections, or speak into the mic...',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                        ),
                      ),

                      // Mic Button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Tooltip(
                          message: _isListening ? 'Stop Recording' : 'Voice-to-Text Dictation',
                          child: InkWell(
                            onTap: _toggleSpeechRecognition,
                            borderRadius: BorderRadius.circular(30),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isListening ? const Color(0xFFEF4444) : AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening ? const Color(0xFFEF4444) : AppColors.primary).withAlpha(80),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
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
              ),

              const SizedBox(height: 14),

              // Save / Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveJournal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isEditing ? 'Update Journal Entry' : 'Save Entry & Complete Quest',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
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
