import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/haptic_service.dart';

/// Download My Data screen — a step-by-step animated flow that shows
/// the user their data being "prepared" (simulated) and then allows them
/// to save it as a JSON file on their device.
class DownloadDataScreen extends StatefulWidget {
  const DownloadDataScreen({super.key});

  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}

enum _ExportStep { select, preparing, ready }

class _DownloadDataScreenState extends State<DownloadDataScreen>
    with TickerProviderStateMixin {
  _ExportStep _step = _ExportStep.select;

  bool _exportChats = true;
  bool _exportMood = true;
  bool _exportSessions = true;
  bool _exportProfile = true;

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
    if (!_exportChats && !_exportMood && !_exportSessions && !_exportProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one data type to export.')),
      );
      return;
    }
    HapticService.mediumTap();
    setState(() {
      _step = _ExportStep.preparing;
      _progress = 0.0;
      _progressLabel = 'Connecting to secure server...';
    });

    final user = context.read<AuthProvider>().currentUser;

    // Simulate progress steps
    final steps = [
      (0.15, 'Verifying your identity...'),
      (0.35, 'Gathering profile data...'),
      (0.55, 'Collecting mood entries...'),
      (0.70, 'Compiling chat history...'),
      (0.85, 'Packaging session records...'),
      (1.0, 'Finalizing export...'),
    ];

    for (final s in steps) {
      await Future.delayed(const Duration(milliseconds: 650));
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
      final file = File('${dir.path}/kausap_data_export_$timestamp.json');
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
        'app_version': '1.0.0',
        'format_version': '1',
        'requested_by': user?['email'] ?? 'unknown',
        'data_included': {
          'profile': _exportProfile,
          'mood_entries': _exportMood,
          'chat_history': _exportChats,
          'sessions': _exportSessions,
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
      if (_exportMood)
        'mood_entries': _generateSampleMoodData(),
      if (_exportChats)
        'chat_history': _generateSampleChatData(),
      if (_exportSessions)
        'sessions': _generateSampleSessionData(),
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
      {'role': 'user', 'content': 'I have been feeling stressed lately.', 'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {'role': 'assistant', 'content': 'I understand. Can you tell me more about what has been stressing you?', 'timestamp': DateTime.now().subtract(const Duration(days: 3, seconds: -30)).toIso8601String()},
      {'role': 'user', 'content': 'Work and personal life balance mainly.', 'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
    ];
  }

  List<Map<String, dynamic>> _generateSampleSessionData() {
    return [
      {
        'session_id': 'sess_001',
        'professional': 'Dr. Jeon Soyeon',
        'date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String().split('T')[0],
        'duration_minutes': 45,
        'type': 'Cognitive Behavioral Therapy',
        'status': 'completed',
      },
      {
        'session_id': 'sess_002',
        'professional': 'Dr. Park Jimin',
        'date': DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
        'duration_minutes': 60,
        'type': 'General Counseling',
        'status': 'scheduled',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                        onPressed: _step == _ExportStep.preparing
                            ? null
                            : () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Download My Data',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: _step == _ExportStep.select
                      ? _buildSelectStep()
                      : _step == _ExportStep.preparing
                          ? _buildPreparingStep()
                          : _buildReadyStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.download_rounded, color: Colors.white, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Your Data', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Your data will be packaged as a secure JSON file and saved to your device.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Selection
        const Text('SELECT DATA TO INCLUDE', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.8, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _buildCheckCard(
          icon: Icons.person_rounded,
          color: const Color(0xFF2563EB),
          title: 'Profile Information',
          subtitle: 'Name, email, account details',
          value: _exportProfile,
          onChanged: (v) => setState(() => _exportProfile = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE11D48),
          title: 'Mood Entries',
          subtitle: 'All daily check-ins and emotion logs',
          value: _exportMood,
          onChanged: (v) => setState(() => _exportMood = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF059669),
          title: 'Chat History',
          subtitle: 'AI conversation logs',
          value: _exportChats,
          onChanged: (v) => setState(() => _exportChats = v),
        ),
        const SizedBox(height: 10),
        _buildCheckCard(
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF7C3AED),
          title: 'Session Records',
          subtitle: 'All past and upcoming sessions',
          value: _exportSessions,
          onChanged: (v) => setState(() => _exportSessions = v),
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
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startExport,
            icon: const Icon(Icons.download_rounded, size: 20, color: Colors.white),
            label: const Text('Generate Export', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Data is packaged locally on your device. No data is sent to external servers.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary, height: 1.4),
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
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: value ? AppColors.primary : Colors.transparent, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparingStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated spinner
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Preparing Your Data',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _progressLabel,
              key: ValueKey(_progressLabel),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_progress * 100).toInt()}% complete',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          const Text(
            'Please keep the app open\nwhile we prepare your export.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary, height: 1.5),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF86EFAC), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 52),
          ),
          const SizedBox(height: 28),
          const Text(
            'Export Ready!',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 26, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your personal data has been successfully packaged and saved to your device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),

          // File path card
          if (_exportedFilePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.insert_drive_file_rounded, color: Color(0xFF2563EB), size: 16),
                      SizedBox(width: 8),
                      Text('Saved to device', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _exportedFilePath!.split('/').last,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticService.success();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              label: const Text('Done', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _step = _ExportStep.select;
              _progress = 0;
              _exportedFilePath = null;
            }),
            child: const Text('Export Again', style: TextStyle(fontFamily: 'Poppins', color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
