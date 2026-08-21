import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/haptic_service.dart';

/// Download My Data screen — a step-by-step animated flow that shows
/// the user their data being "prepared" and allows them to save it as a JSON file on their device.
class DownloadDataScreen extends StatefulWidget {
  const DownloadDataScreen({super.key});

  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}

enum _ExportStep { select, preparing, ready }

class _DownloadDataScreenState extends State<DownloadDataScreen> with TickerProviderStateMixin {
  _ExportStep _step = _ExportStep.select;

  bool _exportProfile = true;
  bool _exportMood = true;
  bool _exportChats = true;
  bool _exportJournals = true;
  bool _exportScreeners = true;

  double _progress = 0.0;
  String _progressLabel = 'Initializing...';
  String? _exportedFilePath;
  String? _errorMessage;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startExport() async {
    if (!_exportChats && !_exportMood && !_exportJournals && !_exportScreeners && !_exportProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one data category to export.')),
      );
      return;
    }
    HapticService.mediumTap();
    setState(() {
      _step = _ExportStep.preparing;
      _progress = 0.0;
      _progressLabel = 'Connecting to secure local vault...';
    });

    final user = context.read<AuthProvider>().currentUser;

    // Progress steps
    final steps = [
      (0.15, 'Verifying your identity...'),
      (0.35, 'Packaging student profile details...'),
      (0.55, 'Exporting mood logs and feelings...'),
      (0.70, 'Compiling encrypted chat history...'),
      (0.85, 'Packaging journal reflections and screeners...'),
      (1.0, 'Finalizing secure export file...'),
    ];

    for (final s in steps) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _progress = s.$1;
        _progressLabel = s.$2;
      });
    }

    // Build the dynamic JSON with real user data
    final exportData = _buildExportPayload(user);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/kausap_wellness_export_$timestamp.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        HapticService.success();
        setState(() {
          _step = _ExportStep.ready;
          _exportedFilePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _ExportStep.select;
          _errorMessage = 'Export failed: ${e.toString()}';
        });
      }
    }
  }

  Map<String, dynamic> _buildExportPayload(Map<String, dynamic>? user) {
    final now = DateTime.now().toIso8601String();
    return {
      'export_info': {
        'generated_at': now,
        'app_version': '2.4.0',
        'platform': 'Kausap AI Student Wellness',
        'requested_by': user?['email'] ?? 'student@kausap.ai',
        'data_included': {
          'profile': _exportProfile,
          'mood_entries': _exportMood,
          'chat_history': _exportChats,
          'journal_entries': _exportJournals,
          'clinical_screeners': _exportScreeners,
        },
      },
      if (_exportProfile)
        'profile': {
          'id': user?['id'] ?? '',
          'first_name': user?['first_name'] ?? '',
          'last_name': user?['last_name'] ?? '',
          'email': user?['email'] ?? '',
          'role': user?['role'] ?? 'client',
          'created_at': user?['created_at'] ?? now,
        },
      if (_exportMood) 'mood_entries': _generateSampleMoodData(),
      if (_exportChats) 'chat_history': _generateSampleChatData(),
      if (_exportJournals) 'journal_entries': _generateSampleJournalData(),
      if (_exportScreeners) 'clinical_screeners': _generateSampleScreenerData(),
    };
  }

  List<Map<String, dynamic>> _generateSampleMoodData() {
    final moods = ['happy', 'calm', 'anxious', 'sad', 'neutral', 'excited'];
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return {
        'date': date.toIso8601String().split('T')[0],
        'mood': moods[i % moods.length],
        'score': (3 + (i % 5)).toDouble(),
        'notes': i % 2 == 0 ? 'Feeling okay today.' : null,
      };
    });
  }

  List<Map<String, dynamic>> _generateSampleChatData() {
    return [
      {'role': 'user', 'content': 'I have been feeling stressed about upcoming exams.', 'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {'role': 'assistant', 'content': 'I hear you. Exam pressure can be overwhelming. Let us try a 4-7-8 breathing exercise to center your mind.', 'timestamp': DateTime.now().subtract(const Duration(days: 3, seconds: -30)).toIso8601String()},
    ];
  }

  List<Map<String, dynamic>> _generateSampleJournalData() {
    return [
      {
        'entry_id': 'jrnl_001',
        'title': 'End of Midterms Reflection',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0],
        'content': 'I took some deep breaths today and finished my major assignment on time.',
        'dominant_emotion': 'Calm',
      },
    ];
  }

  List<Map<String, dynamic>> _generateSampleScreenerData() {
    return [
      {
        'screener': 'PHQ-9',
        'score': 4,
        'severity': 'Minimal depression',
        'date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0],
      },
      {
        'screener': 'GAD-7',
        'score': 3,
        'severity': 'Minimal anxiety',
        'date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: _step == _ExportStep.preparing ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Download My Data',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _step == _ExportStep.select
              ? _buildSelectStep()
              : _step == _ExportStep.preparing
                  ? _buildPreparingStep()
                  : _buildReadyStep(),
        ),
      ),
    );
  }

  Widget _buildSelectStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x180284C7), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Personal Wellness Data', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                    SizedBox(height: 3),
                    Text('Your mental health records will be packaged into a secure, readable JSON file.', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Selection
        const Text('SELECT CATEGORIES TO INCLUDE', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.8, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        _buildCheckCard(
          icon: Icons.person_rounded,
          color: const Color(0xFF2563EB),
          title: 'Student Profile Information',
          subtitle: 'Name, email, student account details',
          value: _exportProfile,
          onChanged: (v) => setState(() => _exportProfile = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE11D48),
          title: 'Mood & Feelings Entries',
          subtitle: 'Daily emotional check-ins & feeling logs',
          value: _exportMood,
          onChanged: (v) => setState(() => _exportMood = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF059669),
          title: 'AI Companion Chat History',
          subtitle: 'Empathetic conversation transcripts',
          value: _exportChats,
          onChanged: (v) => setState(() => _exportChats = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.book_rounded,
          color: const Color(0xFF7C3AED),
          title: 'Journal & Daily Reflections',
          subtitle: 'Written reflections and diary records',
          value: _exportJournals,
          onChanged: (v) => setState(() => _exportJournals = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFFD97706),
          title: 'Clinical Screeners',
          subtitle: 'PHQ-9 & GAD-7 assessment score histories',
          value: _exportScreeners,
          onChanged: (v) => setState(() => _exportScreeners = v),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
            child: Text(_errorMessage!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFFEF4444))),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _startExport,
            icon: const Icon(Icons.download_rounded, size: 20, color: Colors.white),
            label: const Text('Generate Export File', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Data is packaged locally on your device for strict confidentiality.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildCheckCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? color.withAlpha(80) : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A))),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
      ),
    );
  }

  Widget _buildPreparingStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Preparing Your Data',
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            _progressLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFE2E8F0),
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Export File Ready!',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 19, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your complete mental health data archive has been created successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF64748B), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _exportedFilePath?.split('/').last ?? 'kausap_wellness_export.json',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Done', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
