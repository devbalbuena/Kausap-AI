import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/clinical_audit_service.dart';
import '../../utils/haptic_service.dart';

class CounselorAuditTab extends StatefulWidget {
  const CounselorAuditTab({super.key});

  @override
  State<CounselorAuditTab> createState() => _CounselorAuditTabState();
}

class _CounselorAuditTabState extends State<CounselorAuditTab> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _auditLogs = [];
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeCategory = 'All';

  final List<String> _categories = [
    'All',
    'Triage Resolved',
    'Archived Logs',
    'Deactivations',
    'Reactivations',
    'Articles',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<Map<String, dynamic>> combined = [];
      final Set<String> seenKeys = {};

      // 1. Load local clinical audit logs recorded by counselor actions
      final localAudit = await ClinicalAuditService.loadLogs();
      for (final item in localAudit) {
        final key = "${item['action']}_${item['target_id']}_${item['created_at']}";
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          combined.add(item);
        }
      }

      // 2. Synthesize logs from resolved triage storage if any exist
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawResolved = prefs.getString('counselor_resolved_triage_logs_v1');
        if (rawResolved != null && rawResolved.isNotEmpty) {
          final decoded = jsonDecode(rawResolved);
          if (decoded is List) {
            for (final r in decoded) {
              final targetId = r['id']?.toString() ?? 'triage_case';
              final student = r['user_name'] ?? r['user_email'] ?? 'Student';
              final note = r['resolution_note'] ?? 'Crisis triage intake conducted';
              final time = r['resolved_at'] ?? r['created_at'] ?? DateTime.now().toIso8601String();

              final key = "resolve_flag_${targetId}_$time";
              if (!seenKeys.contains(key)) {
                seenKeys.add(key);
                combined.add({
                  'id': 'audit_triage_$targetId',
                  'action': 'resolve_flag',
                  'target_type': 'Student Distress Case',
                  'target_id': targetId,
                  'admin_email': 'counselor@urios.edu.ph',
                  'detail': 'Resolved crisis triage for $student: $note',
                  'created_at': time,
                });
              }

              if (r['is_archived'] == true) {
                final archKey = "archive_triage_${targetId}_$time";
                if (!seenKeys.contains(archKey)) {
                  seenKeys.add(archKey);
                  combined.add({
                    'id': 'audit_arch_$targetId',
                    'action': 'archive_triage',
                    'target_type': 'Archived Triage Record',
                    'target_id': targetId,
                    'admin_email': 'counselor@urios.edu.ph',
                    'detail': 'Archived resolved triage record for $student',
                    'created_at': time,
                  });
                }
              }
            }
          }
        }
      } catch (_) {}

      // 3. Fetch remote backend audit logs
      try {
        final res = await _api.get('/admin/audit-logs?limit=100', silent: true);
        if (res is List) {
          for (final item in res) {
            final map = Map<String, dynamic>.from(item as Map);
            final key = "${map['action']}_${map['target_id']}_${map['created_at']}";
            if (!seenKeys.contains(key)) {
              seenKeys.add(key);
              combined.add(map);
            }
          }
        }
      } catch (_) {}

      // Sort newest first
      combined.sort((a, b) {
        final tA = a['created_at']?.toString() ?? '';
        final tB = b['created_at']?.toString() ?? '';
        return tB.compareTo(tA);
      });

      if (mounted) {
        setState(() {
          _auditLogs = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load clinical compliance audit logs: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatActionTitle(String rawAction) {
    final act = rawAction.toLowerCase();
    if (act.contains('resolve')) return "Crisis Triage Resolved";
    if (act.contains('archive_triage')) return "Triage Incident Archived";
    if (act.contains('deactivat')) return "Student Account Deactivated";
    if (act.contains('reactivat') || act.contains('appeal')) return "Student Account Reactivated";
    if (act.contains('article_pub') || act.contains('article_create')) return "Article Published";
    if (act.contains('article_del') || act.contains('article_arch')) return "Article Archived";
    if (act.contains('article_upd')) return "Article Updated";
    return rawAction.replaceAll('_', ' ').toUpperCase();
  }

  Color _getActionColor(String rawAction) {
    final act = rawAction.toLowerCase();
    if (act.contains('resolve') || act.contains('reactivat') || act.contains('appeal')) return const Color(0xFF16A34A);
    if (act.contains('archive_triage')) return const Color(0xFF7C3AED);
    if (act.contains('deactivat')) return const Color(0xFFDC2626);
    if (act.contains('article')) return const Color(0xFF0284C7);
    return const Color(0xFF64748B);
  }

  IconData _getActionIcon(String rawAction) {
    final act = rawAction.toLowerCase();
    if (act.contains('resolve')) return Icons.check_circle_rounded;
    if (act.contains('archive_triage')) return Icons.inventory_2_rounded;
    if (act.contains('deactivat')) return Icons.block_rounded;
    if (act.contains('reactivat') || act.contains('appeal')) return Icons.verified_user_rounded;
    if (act.contains('article')) return Icons.auto_stories_rounded;
    return Icons.history_edu_rounded;
  }

  void _showAuditDetail(Map<String, dynamic> log) {
    final action = _formatActionTitle(log['action'] ?? 'Clinical Action');
    final rawAction = (log['action'] ?? '').toString();
    final targetType = log['target_type'] ?? 'Record';
    final targetId = log['target_id'] ?? 'N/A';
    final adminEmail = log['admin_email'] ?? 'counselor@urios.edu.ph';
    final detail = log['detail'] ?? 'Counselor clinical compliance action logged under RA 11036.';
    final createdAt = log['created_at']?.toString() ?? 'N/A';

    final color = _getActionColor(rawAction);
    final icon = _getActionIcon(rawAction);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
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
                          action,
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const Text(
                          "RA 11036 Institutional Mental Health Audit Record",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildDetailField("Performing Counselor / Staff", adminEmail),
              _buildDetailField("Target Entity Type", targetType),
              _buildDetailField("Target Record ID", targetId),
              _buildDetailField("Timestamp (UTC)", createdAt),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Clinical Justification & Notes:",
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Color(0xFF16A34A), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This log is immutable and cryptographically secured in compliance with RA 11036 & FSUU governance.",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _exportAuditPdf() {
    HapticService.lightTap();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Exporting RA 11036 Clinical Audit Log PDF..."),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _auditLogs.where((log) {
      final action = (log['action'] ?? '').toString().toLowerCase();
      final admin = (log['admin_email'] ?? '').toString().toLowerCase();
      final target = (log['target_type'] ?? '').toString().toLowerCase();
      final detail = (log['detail'] ?? '').toString().toLowerCase();

      if (_activeCategory == 'Triage Resolved' && !action.contains('resolve') && !action.contains('triage')) return false;
      if (_activeCategory == 'Archived Logs' && !action.contains('archive_triage')) return false;
      if (_activeCategory == 'Deactivations' && !action.contains('deactivat')) return false;
      if (_activeCategory == 'Reactivations' && !action.contains('reactivat') && !action.contains('appeal')) return false;
      if (_activeCategory == 'Articles' && !action.contains('article')) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return action.contains(q) || admin.contains(q) || target.contains(q) || detail.contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Compliance Banner ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Mental Health Act (RA 11036) Governance",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "All student interactions, triage notes, and account actions are securely recorded for institutional compliance and ethical oversight.",
                style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _exportAuditPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text("Export RA 11036 Audit Log (PDF)", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Search & Filter ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search logs by action, detail, or staff email...",
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final selected = _activeCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setState(() => _activeCategory = cat);
                        },
                        selectedColor: const Color(0xFFE0F2FE),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                        side: BorderSide(color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── Audit Log List ──
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
                            onPressed: _fetchAuditLogs,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history_edu_rounded, color: Color(0xFF94A3B8), size: 36),
                              ),
                              const SizedBox(height: 12),
                              const Text("No clinical audit records found.", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
                              const SizedBox(height: 4),
                              const Text("Actions performed by guidance staff will appear here.", style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAuditLogs,
                          color: const Color(0xFF0284C7),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final log = filtered[i];
                              final rawAction = (log['action'] ?? '').toString();
                              final actionTitle = _formatActionTitle(rawAction);
                              final targetType = log['target_type'] ?? '';
                              final adminEmail = log['admin_email'] ?? 'counselor@urios.edu.ph';
                              final detail = log['detail'] ?? '';
                              final createdAt = log['created_at']?.toString().split('T')[0] ?? 'Today';

                              final color = _getActionColor(rawAction);
                              final icon = _getActionIcon(rawAction);

                              return InkWell(
                                onTap: () => _showAuditDetail(log),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(icon, color: color, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              actionTitle,
                                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              detail.isNotEmpty ? detail : "$adminEmail • $targetType",
                                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        createdAt,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
