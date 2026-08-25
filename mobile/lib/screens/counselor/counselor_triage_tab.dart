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
    _tabController = TabController(length: 3, vsync: this);
    _fetchFlaggedMessages();
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

  Widget _buildHotlinesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHotlineCard(
          "FSUU Guidance Center Emergency Line",
          "(085) 342-1830",
          "guidance@urios.edu.ph",
          "Main Campus, Father Saturnino Urios University, Butuan City",
          Icons.school_rounded,
          const Color(0xFF0284C7),
        ),
        const SizedBox(height: 12),
        _buildHotlineCard(
          "National Center for Mental Health (NCMH)",
          "1553 (Toll-free nationwide) / 0917-899-USAP",
          "ncmh.gov.ph",
          "24/7 National Mental Health Crisis Hotline",
          Icons.health_and_safety_rounded,
          const Color(0xFF16A34A),
        ),
        const SizedBox(height: 12),
        _buildHotlineCard(
          "In Touch Community Services",
          "+63 917 800 1123 / +63 2 8893 7603",
          "crisisline@in-touch.org",
          "Crisis Line Philippines 24/7 Support",
          Icons.support_agent_rounded,
          const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildHotlineCard(String title, String phone, String email, String subtitle, IconData icon, Color color) {
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
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
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
            ),
          ),
        ],
      ),
    );
  }
}
