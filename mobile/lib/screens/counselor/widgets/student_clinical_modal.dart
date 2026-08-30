import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_client.dart';
import '../../../services/clinical_audit_service.dart';
import '../../../utils/haptic_service.dart';

class StudentClinicalModal extends StatefulWidget {
  final Map<String, dynamic> student;
  final VoidCallback? onStatusChanged;
  final int initialTabIndex;

  const StudentClinicalModal({
    super.key,
    required this.student,
    this.onStatusChanged,
    this.initialTabIndex = 0,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> student,
    VoidCallback? onStatusChanged,
    int initialTabIndex = 0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudentClinicalModal(
        student: student,
        onStatusChanged: onStatusChanged,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<StudentClinicalModal> createState() => _StudentClinicalModalState();
}

class _StudentClinicalModalState extends State<StudentClinicalModal> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  bool _loadingMoods = true;
  List<dynamic> _moods = [];
  String? _moodError;

  bool _loadingChats = true;
  List<dynamic> _chatSessions = [];
  String? _chatError;

  final Set<String> _expandedSessionIds = {};

  final List<String> _deactivationReasonPresets = [
    "Temporary wellness leave requested by student",
    "Account locked pending guidance office consultation",
    "Student graduated or transferred from FSUU",
    "Administrative clinical review in progress",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchMoodHistory();
    _fetchChatSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _studentId => widget.student['id']?.toString() ?? '';
  String get _studentName => widget.student['full_name'] ?? 'Student';
  String get _studentEmail => widget.student['email'] ?? '';
  bool get _isActive => widget.student['is_active'] != false;

  Future<void> _fetchMoodHistory() async {
    if (_studentId.isEmpty) return;
    setState(() {
      _loadingMoods = true;
      _moodError = null;
    });
    try {
      final res = await _api.get('/admin/users/$_studentId/mood-history', silent: true);
      if (mounted) {
        setState(() {
          _moods = res is List ? res : [];
          _loadingMoods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moodError = 'Could not load mood logs';
          _loadingMoods = false;
        });
      }
    }
  }

  Future<void> _fetchChatSessions() async {
    if (_studentId.isEmpty) return;
    setState(() {
      _loadingChats = true;
      _chatError = null;
    });
    try {
      final res = await _api.get('/admin/users/$_studentId/chat-sessions', silent: true);
      if (mounted) {
        setState(() {
          _chatSessions = res is List ? res : [];
          _loadingChats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatError = 'Could not load chat sessions';
          _loadingChats = false;
        });
      }
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _getMoodVisuals(int level) {
    switch (level) {
      case 5:
        return {
          'emoji': '🌟',
          'label': 'Great',
          'color': const Color(0xFF16A34A),
          'bg': const Color(0xFFDCFCE7),
          'border': const Color(0xFF86EFAC),
        };
      case 4:
        return {
          'emoji': '😊',
          'label': 'Good',
          'color': const Color(0xFF0284C7),
          'bg': const Color(0xFFE0F2FE),
          'border': const Color(0xFFBAE6FD),
        };
      case 3:
        return {
          'emoji': '😐',
          'label': 'Okay',
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF1F5F9),
          'border': const Color(0xFFCBD5E1),
        };
      case 2:
        return {
          'emoji': '😔',
          'label': 'Rough / Down',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
          'border': const Color(0xFFFDE68A),
        };
      case 1:
      default:
        return {
          'emoji': '💔',
          'label': 'Distressed',
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEE2E2),
          'border': const Color(0xFFFECACA),
        };
    }
  }

  List<String> _parseEmotions(dynamic emotionsData) {
    if (emotionsData == null) return [];
    if (emotionsData is List) {
      return emotionsData.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    final raw = emotionsData.toString();
    if (raw.startsWith('[') && raw.endsWith(']')) {
      final clean = raw.substring(1, raw.length - 1);
      return clean.split(',').map((e) => e.replaceAll('"', '').replaceAll("'", '').trim()).where((e) => e.isNotEmpty).toList();
    }
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final moodCount = widget.student['mood_entries_count'] ?? _moods.length;
    final chatCount = widget.student['chat_sessions_count'] ?? _chatSessions.length;
    final flagCount = widget.student['flagged_messages_count'] ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Student Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _studentName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isActive ? "Active" : "Inactive",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _studentEmail,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // ── Tab Bar ──
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0284C7),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0284C7),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12.5),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🌈 Moods"),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$moodCount",
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("💬 AI Chats"),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$chatCount",
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(
                  text: "🛡️ Triage & Actions",
                ),
              ],
            ),
          ),

          // ── Tab View Content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMoodJourneyTab(),
                _buildChatTranscriptsTab(),
                _buildOverviewAndActionsTab(flagCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 🌈 TAB 1: Real Emoji Mood Journey & Journal
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMoodJourneyTab() {
    if (_loadingMoods) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0284C7)),
            SizedBox(height: 12),
            Text("Loading student mood timeline...", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (_moodError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
            const SizedBox(height: 8),
            Text(_moodError!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchMoodHistory, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_moods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🌱", style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              const Text(
                "No Mood Check-ins Logged",
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                "This student has not submitted any daily mood check-ins yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMoodHistory,
      color: const Color(0xFF0284C7),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _moods.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final m = _moods[i];
          final level = (m['mood_level'] as num?)?.toInt() ?? 3;
          final visuals = _getMoodVisuals(level);
          final dateStr = _formatDateTime(m['created_at']?.toString());
          final emotions = _parseEmotions(m['emotions']);
          final note = m['note']?.toString();
          final intensity = (m['intensity'] as num?)?.toInt();

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: visuals['border'] as Color, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: (visuals['color'] as Color).withAlpha(15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Emoji + Level Label + Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: visuals['bg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(visuals['emoji'] as String, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                visuals['label'] as String,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: visuals['color'] as Color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (visuals['color'] as Color).withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Level $level/5",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: visuals['color'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    if (intensity != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Intensity $intensity/10",
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ],
                ),

                // Emotion Tags
                if (emotions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: emotions.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (visuals['color'] as Color).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (visuals['color'] as Color).withAlpha(40)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: visuals['color'] as Color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Student Journal Note
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            note,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 💬 TAB 2: Full AI Chat Session Transcripts
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildChatTranscriptsTab() {
    if (_loadingChats) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7C3AED)),
            SizedBox(height: 12),
            Text("Loading student conversation transcripts...", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (_chatError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
            const SizedBox(height: 8),
            Text(_chatError!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchChatSessions, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_chatSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("💬", style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              const Text(
                "No AI Chat Sessions Found",
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                "The student has not started any conversations with the AI companions yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchChatSessions,
      color: const Color(0xFF7C3AED),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _chatSessions.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) {
          final s = _chatSessions[i];
          final sessionId = s['id']?.toString() ?? '$i';
          final topic = s['topic'] ?? 'AI Companion Conversation';
          final dateStr = _formatDateTime(s['created_at']?.toString());
          final messages = (s['messages'] as List<dynamic>?) ?? [];
          final bool isExpanded = _expandedSessionIds.contains(sessionId);
          final bool hasCrisisFlag = messages.any((m) => m['risk_flag'] == true);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasCrisisFlag ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                width: hasCrisisFlag ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasCrisisFlag ? const Color(0x1ADC2626) : const Color(0x06000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Header
                InkWell(
                  onTap: () {
                    HapticService.lightTap();
                    setState(() {
                      if (isExpanded) {
                        _expandedSessionIds.remove(sessionId);
                      } else {
                        _expandedSessionIds.add(sessionId);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasCrisisFlag ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            hasCrisisFlag ? Icons.warning_amber_rounded : Icons.forum_rounded,
                            color: hasCrisisFlag ? const Color(0xFFDC2626) : const Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      topic,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasCrisisFlag) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Crisis Flagged",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$dateStr • ${messages.length} message${messages.length == 1 ? '' : 's'}",
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Conversation Messages
                if (isExpanded) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(14),
                    child: messages.isEmpty
                        ? const Center(
                            child: Text(
                              "No messages exchanged in this session.",
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: messages.map((m) {
                              final role = m['role']?.toString() ?? 'user';
                              final isUser = role == 'user';
                              final content = m['content']?.toString() ?? '';
                              final bool isFlagged = m['risk_flag'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser) ...[
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: const Color(0xFF0284C7),
                                        child: const Text('🤖', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? (isFlagged ? const Color(0xFFDC2626) : const Color(0xFF0284C7))
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: isUser
                                              ? null
                                              : Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: const [
                                            BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (isFlagged) ...[
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Flagged Distress Message",
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 9.5,
                                                      color: isUser ? Colors.white : const Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Text(
                                              content,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12.5,
                                                color: isUser ? Colors.white : const Color(0xFF1E293B),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isUser) ...[
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: const Color(0xFFE0F2FE),
                                        child: Text(
                                          _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
                                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 🛡️ TAB 3: Student Demographics, Appeals & Triage Actions
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewAndActionsTab(int flagCount) {
    final deactivationReason = widget.student['deactivation_reason'];
    final appeal = widget.student['reactivation_appeal'];
    final moodCount = widget.student['mood_entries_count'] ?? _moods.length;
    final chatCount = widget.student['chat_sessions_count'] ?? _chatSessions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Engagement Stats ──
          Row(
            children: [
              Expanded(
                child: _buildModalStatTile("Mood Logs", "$moodCount", Icons.mood_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModalStatTile("Chat Sessions", "$chatCount", Icons.forum_rounded, const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModalStatTile("Crisis Flags", "$flagCount", Icons.emergency_rounded, flagCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A), flagCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Deactivation Reason Notice (if inactive) ──
          if (!_isActive && deactivationReason != null && deactivationReason.toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 16),
                      SizedBox(width: 6),
                      Text("Counselor Deactivation Reason:", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF991B1B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(deactivationReason.toString(), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFB91C1C))),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Student Reactivation Appeal (if pending) ──
          if (appeal != null && appeal.toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mark_email_unread_outlined, color: Color(0xFFD97706), size: 16),
                      SizedBox(width: 6),
                      Text("Student Reactivation Appeal:", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF92400E))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(appeal.toString(), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF78350F))),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _approveAppeal(_studentId, _studentName),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    label: const Text("Approve & Restore Account", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Demographics Card ──
          const Text(
            "Student Demographics (FSUU)",
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow("Institution", "Father Saturnino Urios University"),
                const SizedBox(height: 8),
                _buildInfoRow("Phone", widget.student['phone_number'] ?? 'Not provided'),
                const SizedBox(height: 8),
                _buildInfoRow("Gender", widget.student['gender'] ?? 'Not specified'),
                const SizedBox(height: 8),
                _buildInfoRow("Occupation / Program", widget.student['occupation'] ?? 'Student'),
                const SizedBox(height: 8),
                _buildInfoRow("Birthday", widget.student['birthday'] ?? 'Not provided'),
                const SizedBox(height: 8),
                _buildInfoRow("Account Created", _formatDateTime(widget.student['created_at']?.toString())),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Action Buttons ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _toggleStudentStatus(),
              icon: Icon(_isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
              label: Text(_isActive ? "Deactivate Student Account" : "Reactivate Student Account", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                side: BorderSide(color: _isActive ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalStatTile(String label, String count, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Future<void> _approveAppeal(String studentId, String name) async {
    try {
      HapticService.lightTap();
      await ClinicalAuditService.recordLog(
        action: 'appeal_approved',
        targetType: 'Student Account',
        targetId: studentId,
        detail: 'Approved reactivation appeal for student $name.',
      );

      await _api.patch(
        '/admin/users/$studentId/reactivate',
        body: {'status': 'active'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reactivation appeal approved for $name."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      widget.onStatusChanged?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to approve appeal: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _toggleStudentStatus() async {
    final currentStatus = _isActive;
    final newStatus = !currentStatus;
    final reasonCtrl = TextEditingController(text: _deactivationReasonPresets[0]);
    String selectedPreset = _deactivationReasonPresets[0];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            newStatus ? "Reactivate Student Account" : "Deactivate Student Account",
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newStatus
                      ? "Restore platform access for $_studentName?"
                      : "Document the counselor reason for deactivating $_studentName:",
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
                ),
                if (!newStatus) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Standard Counselor Reasons:",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _deactivationReasonPresets.map((preset) {
                      final isSelected = selectedPreset == preset;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedPreset = preset;
                            reasonCtrl.text = preset;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            preset,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF991B1B) : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Custom Reason / Notes",
                      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(newStatus ? "Confirm Reactivation" : "Confirm Deactivation", style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.heavyTap();
      final reasonText = reasonCtrl.text.trim();

      await ClinicalAuditService.recordLog(
        action: newStatus ? 'user_reactivated' : 'user_deactivated',
        targetType: 'Student Account',
        targetId: _studentId,
        detail: newStatus
            ? 'Reactivated student account for $_studentName'
            : 'Deactivated student account for $_studentName. Reason: $reasonText',
      );

      await _api.patch(
        '/admin/users/$_studentId/status',
        body: {
          'is_active': newStatus,
          'reason': reasonText,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Student $_studentName is now ${newStatus ? 'active' : 'deactivated'}."),
          backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
      widget.onStatusChanged?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating student status: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }
}
