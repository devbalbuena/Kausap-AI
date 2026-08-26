import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/clinical_audit_service.dart';
import '../../utils/haptic_service.dart';

class CounselorTriageTab extends StatefulWidget {
  const CounselorTriageTab({super.key});

  @override
  State<CounselorTriageTab> createState() => _CounselorTriageTabState();
}

class _CounselorTriageTabState extends State<CounselorTriageTab> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _flaggedMessages = [];
  String _resolvedSearch = '';
  final TextEditingController _resolvedSearchCtrl = TextEditingController();
  bool _showArchivedResolved = false;

  // Dynamic Emergency Hotlines State
  static const List<Map<String, dynamic>> _fallbackHotlines = [
    {
      "id": "fsuu-default-1",
      "name": "FSUU Guidance Center Emergency Line",
      "phone": "(085) 342-1830",
      "email": "guidance@urios.edu.ph",
      "description": "Main Campus, Father Saturnino Urios University, Butuan City",
      "category": "campus",
      "type": "call",
      "is_active": true,
      "sort_order": 1,
    },
    {
      "id": "ncmh-default-2",
      "name": "National Center for Mental Health (NCMH)",
      "phone": "1553 / 0917-899-8727",
      "email": "ncmh.gov.ph",
      "description": "24/7 National Mental Health Crisis Hotline (Toll-Free Nationwide)",
      "category": "national",
      "type": "call",
      "is_active": true,
      "sort_order": 2,
    },
    {
      "id": "hopeline-default-3",
      "name": "Hopeline Philippines",
      "phone": "0917-558-4673 / (02) 8804-4673",
      "email": "hopeline@ngf-hope.org",
      "description": "24/7 Suicide Prevention & Crisis Support Line",
      "category": "national",
      "type": "call",
      "is_active": true,
      "sort_order": 3,
    },
    {
      "id": "intouch-default-4",
      "name": "In Touch Community Services",
      "phone": "+63 917 800 1123 / +63 2 8893 7603",
      "email": "crisisline@in-touch.org",
      "description": "Crisis Line Philippines 24/7 Multilingual Support",
      "category": "national",
      "type": "call",
      "is_active": true,
      "sort_order": 4,
    },
    {
      "id": "911-default-5",
      "name": "Philippine Emergency Hotline (911)",
      "phone": "911",
      "email": null,
      "description": "National Emergency First Responders, Police & Ambulance",
      "category": "emergency",
      "type": "call",
      "is_active": true,
      "sort_order": 5,
    },
    {
      "id": "text-crisis-default-6",
      "name": "Text Crisis Support Line",
      "phone": "09178626820",
      "email": null,
      "description": "Text HELLO to this number for confidential SMS chat support",
      "category": "national",
      "type": "sms",
      "is_active": true,
      "sort_order": 6,
    },
  ];

  List<Map<String, dynamic>> _hotlinesList = [];
  bool _isLoadingHotlines = false;
  String _selectedHotlineCategory = 'all';

  static const String _resolvedStorageKey = 'counselor_resolved_triage_logs_v1';

  final List<String> _clinicalActionPresets = [
    "Conducted immediate 1-on-1 intake session",
    "Scheduled follow-up consultation with guidance staff",
    "Dispatched emergency contact & NCMH 1553 hotlines",
    "Referred to Student Affairs & Guidance testing center",
    "Reviewed context: False positive / safe emotional expression",
  ];

  @override
  void initState() {
    super.initState();
    _hotlinesList = List<Map<String, dynamic>>.from(_fallbackHotlines);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && mounted) {
        _fetchHotlines();
      }
    });
    _fetchFlaggedMessages();
    _fetchHotlines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _resolvedSearchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadLocalResolved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_resolvedStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalResolved(List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_resolvedStorageKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _fetchFlaggedMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final localResolved = await _loadLocalResolved();
      final resolvedIds = localResolved.map((r) => r['id'].toString()).toSet();

      final res = await _api.get('/admin/flagged-messages');
      if (mounted) {
        final remote = res is List ? res : [];
        final List<Map<String, dynamic>> combined = [];

        // Active alerts from remote (not yet marked resolved locally)
        for (final item in remote) {
          final map = Map<String, dynamic>.from(item as Map);
          final idStr = map['id'].toString();
          if (resolvedIds.contains(idStr)) {
            continue;
          }
          if (map['is_resolved'] == true) {
            combined.add(map);
          } else {
            combined.add(map);
          }
        }

        // Add all locally saved resolved logs
        for (final loc in localResolved) {
          combined.add(loc);
        }

        setState(() {
          _flaggedMessages = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final localResolved = await _loadLocalResolved();
        setState(() {
          _flaggedMessages = localResolved;
          _error = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveFlag(Map<String, dynamic> flag) async {
    final flagId = flag['id'].toString();
    final studentName = flag['user_name'] ?? flag['user_email']?.toString().split('@')[0] ?? 'Student';
    final noteCtrl = TextEditingController(text: _clinicalActionPresets[0]);
    String selectedPreset = _clinicalActionPresets[0];

    final resolved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 22),
              SizedBox(width: 8),
              Text(
                "Resolve Crisis Triage",
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Document the clinical action taken for $studentName:",
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Clinical Action Quick Presets:",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _clinicalActionPresets.map((preset) {
                    final isSelected = selectedPreset == preset;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedPreset = preset;
                          noteCtrl.text = preset;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Custom Clinical Note *",
                    hintText: "Add specific counseling intake notes for RA 11036 compliance...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
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
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Confirm Resolution", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (resolved != true) return;

    try {
      HapticService.lightTap();

      final resolvedRecord = Map<String, dynamic>.from(flag);
      resolvedRecord['is_resolved'] = true;
      resolvedRecord['is_archived'] = false;
      resolvedRecord['resolution_note'] = noteCtrl.text.trim();
      resolvedRecord['resolved_at'] = DateTime.now().toIso8601String();

      // 1. Save locally so it's permanently stored in Resolved Log
      final localResolved = await _loadLocalResolved();
      localResolved.removeWhere((r) => r['id'].toString() == flagId);
      localResolved.insert(0, resolvedRecord);
      await _saveLocalResolved(localResolved);

      // 2. Record in Clinical Audit Log
      await ClinicalAuditService.recordLog(
        action: 'resolve_flag',
        targetType: 'Student Distress Case',
        targetId: flagId,
        detail: 'Resolved crisis triage for $studentName: ${noteCtrl.text.trim()}',
      );

      // 3. Update state immediately
      setState(() {
        _flaggedMessages.removeWhere((f) => f['id'].toString() == flagId);
        _flaggedMessages.insert(0, resolvedRecord);
      });

      // 4. Sync resolution with API backend
      try {
        await _api.patch(
          '/admin/flagged-messages/$flagId/resolve',
          body: {'resolution_note': noteCtrl.text.trim()},
          silent: true,
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Crisis triage case for $studentName resolved & logged."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to resolve triage: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _archiveResolvedLog(Map<String, dynamic> item) async {
    final flagId = item['id'].toString();
    final studentName = item['user_name'] ?? item['user_email'] ?? 'Student';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Color(0xFF7C3AED), size: 22),
            SizedBox(width: 8),
            Text(
              "Archive Resolved Record?",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          "Move the resolved clinical log for $studentName to the compliance archive?\n\nYou can access archived records anytime via the Archive view.",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Archive Record", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.lightTap();

      final localResolved = await _loadLocalResolved();
      final idx = localResolved.indexWhere((r) => r['id'].toString() == flagId);
      if (idx != -1) {
        localResolved[idx]['is_archived'] = true;
        await _saveLocalResolved(localResolved);
      }

      await ClinicalAuditService.recordLog(
        action: 'archive_triage',
        targetType: 'Archived Triage Record',
        targetId: flagId,
        detail: 'Soft-deleted / archived resolved triage log for $studentName',
      );

      setState(() {
        final stateIdx = _flaggedMessages.indexWhere((f) => f['id'].toString() == flagId);
        if (stateIdx != -1) {
          final updated = Map<String, dynamic>.from(_flaggedMessages[stateIdx]);
          updated['is_archived'] = true;
          _flaggedMessages[stateIdx] = updated;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Resolved record for $studentName archived."),
          backgroundColor: const Color(0xFF7C3AED),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error archiving record: $e"), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _restoreArchivedLog(Map<String, dynamic> item) async {
    final flagId = item['id'].toString();
    final studentName = item['user_name'] ?? item['user_email'] ?? 'Student';

    try {
      HapticService.lightTap();

      final localResolved = await _loadLocalResolved();
      final idx = localResolved.indexWhere((r) => r['id'].toString() == flagId);
      if (idx != -1) {
        localResolved[idx]['is_archived'] = false;
        await _saveLocalResolved(localResolved);
      }

      await ClinicalAuditService.recordLog(
        action: 'restore_triage',
        targetType: 'Restored Triage Record',
        targetId: flagId,
        detail: 'Restored archived triage record for $studentName back to active resolved view.',
      );

      setState(() {
        final stateIdx = _flaggedMessages.indexWhere((f) => f['id'].toString() == flagId);
        if (stateIdx != -1) {
          final updated = Map<String, dynamic>.from(_flaggedMessages[stateIdx]);
          updated['is_archived'] = false;
          _flaggedMessages[stateIdx] = updated;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Record restored to active resolved list."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (_) {}
  }

  Future<void> _permanentlyDeleteLog(Map<String, dynamic> item) async {
    final flagId = item['id'].toString();
    final studentName = item['user_name'] ?? item['user_email'] ?? 'Student';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              "Permanently Delete Log?",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently purge the archived record for $studentName? This cannot be undone.",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Delete Permanently", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.lightTap();

      final localResolved = await _loadLocalResolved();
      localResolved.removeWhere((r) => r['id'].toString() == flagId);
      await _saveLocalResolved(localResolved);

      await ClinicalAuditService.recordLog(
        action: 'purge_triage_log',
        targetType: 'Purged Triage Record',
        targetId: flagId,
        detail: 'Permanently deleted archived triage record for $studentName.',
      );

      setState(() {
        _flaggedMessages.removeWhere((f) => f['id'].toString() == flagId);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Archived log permanently deleted."),
          backgroundColor: Color(0xFF334155),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final active = _flaggedMessages.where((f) => f['is_resolved'] != true).toList();
    final allResolved = _flaggedMessages.where((f) => f['is_resolved'] == true).toList();
    final activeResolved = allResolved.where((f) => f['is_archived'] != true).toList();
    final archivedResolved = allResolved.where((f) => f['is_archived'] == true).toList();

    return Column(
      children: [
        // ── Subtab Header ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0284C7),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0284C7),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Active Queue"),
                    if (active.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${active.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Resolved Log (${activeResolved.length})"),
                  ],
                ),
              ),
              const Tab(text: "Emergency Hotlines"),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchFlaggedMessages,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveList(active),
                        _buildResolvedList(activeResolved, archivedResolved),
                        _buildHotlinesTab(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildActiveList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Active Crisis Triggers",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              "All student conversations are within safe clinical boundaries.",
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFlaggedMessages,
      color: const Color(0xFF0284C7),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final item = list[i];
          final student = item['user_name'] ?? item['user_email']?.toString().split('@')[0] ?? 'Student';
          final email = item['user_email'] ?? '';
          final reason = item['flag_reason'] ?? 'Crisis Trigger';
          final rawExcerpt = (item['content'] ?? item['message_text'] ?? '').toString().trim();
          final excerpt = rawExcerpt.isNotEmpty ? rawExcerpt : "🚨 1-Tap Campus SOS Emergency Assistance Triggered";
          final createdAt = item['created_at']?.toString().split('T')[0] ?? 'Today';

          final isHighRisk = reason.toLowerCase().contains('suicide') || reason.toLowerCase().contains('harm') || reason.toLowerCase().contains('crisis') || excerpt.contains('SOS');

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isHighRisk ? const Color(0xFFFCA5A5) : const Color(0xFFFED7AA)),
              boxShadow: const [BoxShadow(color: Color(0x08EF4444), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isHighRisk ? const Color(0xFFFEE2E2) : const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isHighRisk ? Icons.emergency_rounded : Icons.warning_amber_rounded,
                            color: isHighRisk ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student,
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              email,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isHighRisk ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isHighRisk ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        isHighRisk ? "🚨 $reason" : "⚠️ $reason",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isHighRisk ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '"$excerpt"',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF334155), fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Flagged: $createdAt",
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _resolveFlag(item),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                      label: const Text("Resolve Triage", style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResolvedList(List<dynamic> activeResolved, List<dynamic> archivedResolved) {
    final currentList = _showArchivedResolved ? archivedResolved : activeResolved;

    final filtered = currentList.where((item) {
      if (_resolvedSearch.isEmpty) return true;
      final q = _resolvedSearch.toLowerCase();
      final name = (item['user_name'] ?? item['user_email'] ?? '').toString().toLowerCase();
      final note = (item['resolution_note'] ?? '').toString().toLowerCase();
      return name.contains(q) || note.contains(q);
    }).toList();

    return Column(
      children: [
        // ── Search & Filter Controls ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              TextField(
                controller: _resolvedSearchCtrl,
                onChanged: (val) => setState(() => _resolvedSearch = val),
                decoration: InputDecoration(
                  hintText: "Search resolved logs by student or note...",
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text("Active Resolved (${activeResolved.length})"),
                    selected: !_showArchivedResolved,
                    onSelected: (val) {
                      if (val) setState(() => _showArchivedResolved = false);
                    },
                    selectedColor: const Color(0xFFDCFCE7),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: !_showArchivedResolved ? FontWeight.w700 : FontWeight.w500,
                      color: !_showArchivedResolved ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                    side: BorderSide(color: !_showArchivedResolved ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text("Archived (${archivedResolved.length})"),
                    selected: _showArchivedResolved,
                    onSelected: (val) {
                      if (val) setState(() => _showArchivedResolved = true);
                    },
                    selectedColor: const Color(0xFFF3E8FF),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: _showArchivedResolved ? FontWeight.w700 : FontWeight.w500,
                      color: _showArchivedResolved ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                    ),
                    side: BorderSide(color: _showArchivedResolved ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showArchivedResolved ? Icons.inventory_2_outlined : Icons.check_circle_outline_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _showArchivedResolved ? "No archived clinical records." : "No active resolved crisis records found.",
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showArchivedResolved ? "Soft-deleted records will be safely retained here." : "Resolved crisis cases will be cataloged here.",
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    final student = item['user_name'] ?? item['user_email']?.toString().split('@')[0] ?? 'Student';
                    final email = item['user_email'] ?? '';
                    final note = item['resolution_note'] ?? 'Resolved by Counselor';
                    final resolvedAt = item['resolved_at']?.toString().split('T')[0] ?? 'Today';
                    final isArchived = item['is_archived'] == true;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student,
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isArchived ? const Color(0xFFF3E8FF) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isArchived ? const Color(0xFFD8B4FE) : const Color(0xFF86EFAC)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isArchived ? Icons.inventory_2_rounded : Icons.check_circle_rounded,
                                          color: isArchived ? const Color(0xFF7C3AED) : const Color(0xFF16A34A),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isArchived ? "Archived" : "Resolved",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            color: isArchived ? const Color(0xFF7C3AED) : const Color(0xFF16A34A),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (!isArchived)
                                    IconButton(
                                      icon: const Icon(Icons.archive_outlined, size: 18, color: Color(0xFF94A3B8)),
                                      tooltip: "Archive Record (Soft Delete)",
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _archiveResolvedLog(item),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.unarchive_outlined, size: 18, color: Color(0xFF16A34A)),
                                          tooltip: "Restore to Resolved",
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _restoreArchivedLog(item),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                          tooltip: "Delete Permanently",
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _permanentlyDeleteLog(item),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          Text(
                            "Clinical Action: $note",
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Resolved On: $resolvedAt",
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _fetchHotlines() async {
    setState(() => _isLoadingHotlines = true);
    try {
      final res = await _api.get('/crisis/hotlines');
      if (mounted && res is List) {
        setState(() {
          _hotlinesList = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoadingHotlines = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHotlines = false);
  }

  Future<void> _deleteHotline(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Archive Hotline?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to archive "$name"? It will be hidden from student SOS & profile screens while preserving audit records.',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 38),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Archive', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticService.heavyTap();
      try {
        await _api.delete('/admin/hotlines/$id');
        if (mounted) {
          setState(() {
            _hotlinesList.removeWhere((h) => h['id'] == id || h['name'] == name);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hotline "$name" archived successfully (soft deleted).'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          _fetchHotlines();
        }
      } catch (e) {
        if (mounted) {
          final String errMsg = e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to archive hotline: $errMsg'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  Future<void> _showHotlineDialog([Map<String, dynamic>? existing]) async {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    String category = existing?['category'] ?? 'campus';
    String type = existing?['type'] ?? 'call';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEditing ? const Color(0xFFE0F2FE) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.add_call,
                  color: isEditing ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Emergency Hotline' : 'Add Emergency Hotline',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This contact will immediately sync to Student SOS, Profile & Insights menus in real time.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  const Text('Category Scope', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'campus', child: Text('🏫 Campus Guidance / Clinic')),
                          DropdownMenuItem(value: 'national', child: Text('🇵🇭 National 24/7 Crisis Hotline')),
                          DropdownMenuItem(value: 'emergency', child: Text('🚑 Local Emergency / 911 First Responders')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => category = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Name
                  const Text('Hotline Name *', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. FSUU Guidance Center Emergency Line',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone Number
                  const Text('Phone / Hotline Number *', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. (085) 342-1830 or 1553',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  const Text('Email Address (Optional)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. guidance@urios.edu.ph',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  const Text('Location / Operating Hours', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Main Campus, Father Saturnino Urios University, Butuan City',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Type
                  Row(
                    children: [
                      const Text('Contact Type: ', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('📞 Call', style: TextStyle(fontSize: 11)),
                        selected: type == 'call',
                        onSelected: (s) {
                          if (s) setDialogState(() => type = 'call');
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('💬 SMS', style: TextStyle(fontSize: 11)),
                        selected: type == 'sms',
                        onSelected: (s) {
                          if (s) setDialogState(() => type = 'sms');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide both Hotline Name and Phone number.')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final payload = {
                          "name": name,
                          "phone": phone,
                          "email": emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          "description": descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          "category": category,
                          "type": type,
                          "is_active": true,
                          "sort_order": category == 'campus' ? 1 : (category == 'national' ? 2 : 3),
                        };

                        if (isEditing) {
                          await _api.put('/admin/hotlines/${existing['id']}', body: payload);
                        } else {
                          await _api.post('/admin/hotlines', body: payload);
                        }

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Hotline updated successfully!' : 'New hotline added & synchronized!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                        await _fetchHotlines();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!mounted) return;
                        final String errMsg = e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', '');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save hotline: $errMsg'), backgroundColor: const Color(0xFFDC2626)),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Save Changes' : 'Add Hotline', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotlinesTab() {
    final filteredHotlines = _hotlinesList.where((h) {
      if (_selectedHotlineCategory == 'all') return true;
      return (h['category'] ?? '').toString().toLowerCase() == _selectedHotlineCategory;
    }).toList();

    return Column(
      children: [
        // Top Action Header & Category Filters
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Crisis & Hotline Directory',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Synchronized across student SOS and guidance workflows',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showHotlineDialog(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+ Add Hotline'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildHotlineFilterChip('All Directories', 'all'),
                    const SizedBox(width: 8),
                    _buildHotlineFilterChip('🏫 Campus', 'campus'),
                    const SizedBox(width: 8),
                    _buildHotlineFilterChip('🇵🇭 National 24/7', 'national'),
                    const SizedBox(width: 8),
                    _buildHotlineFilterChip('🚑 Emergency 911', 'emergency'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Hotlines List
        Expanded(
          child: _isLoadingHotlines
              ? const Center(child: CircularProgressIndicator())
              : filteredHotlines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_disabled_rounded, size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hotlines found in this category.',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showHotlineDialog(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add New Hotline'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHotlines,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHotlines.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final h = filteredHotlines[index];
                          return _buildDynamicHotlineCard(h);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHotlineFilterChip(String label, String category) {
    final isSelected = _selectedHotlineCategory == category;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedHotlineCategory = category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicHotlineCard(Map<String, dynamic> hotline) {
    final name = hotline['name']?.toString() ?? 'Emergency Contact';
    final phone = hotline['phone']?.toString() ?? '';
    final email = hotline['email']?.toString();
    final description = hotline['description']?.toString() ?? '';
    final category = hotline['category']?.toString() ?? 'national';
    final type = hotline['type']?.toString() ?? 'call';
    final id = hotline['id']?.toString() ?? '';

    Color themeColor;
    IconData icon;
    String badgeLabel;

    if (category == 'campus') {
      themeColor = const Color(0xFF0284C7);
      icon = Icons.school_rounded;
      badgeLabel = 'Campus Resource';
    } else if (category == 'emergency') {
      themeColor = const Color(0xFFDC2626);
      icon = Icons.emergency_rounded;
      badgeLabel = 'Emergency 911';
    } else {
      themeColor = const Color(0xFF16A34A);
      icon = type == 'sms' ? Icons.sms_rounded : Icons.health_and_safety_rounded;
      badgeLabel = 'National 24/7';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: themeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 10, color: themeColor),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(type == 'sms' ? Icons.sms_outlined : Icons.phone_rounded, size: 14, color: themeColor),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: themeColor),
                    ),
                  ],
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        email,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions: Edit & Delete
          Column(
            children: [
              IconButton(
                tooltip: 'Edit Hotline',
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                onPressed: () => _showHotlineDialog(hotline),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 10),
              IconButton(
                tooltip: 'Remove Hotline',
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                onPressed: () => _deleteHotline(id, name),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

