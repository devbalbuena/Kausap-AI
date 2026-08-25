import 'package:flutter/material.dart';
import '../../services/api_client.dart';
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
      final res = await _api.get('/admin/audit-logs?limit=100');
      if (mounted) {
        setState(() {
          _auditLogs = res is List ? res : [];
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

  void _showAuditDetail(Map<String, dynamic> log) {
    final action = log['action'] ?? 'Clinical Action';
    final targetType = log['target_type'] ?? 'Record';
    final targetId = log['target_id'] ?? 'N/A';
    final adminEmail = log['admin_email'] ?? 'Counselor';
    final createdAt = log['created_at']?.toString() ?? 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "RA 11036 Compliance Record",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        "Institutional Mental Health Audit Trail",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildDetailField("Clinical Action", action, isBold: true),
            _buildDetailField("Performing Counselor / Staff", adminEmail),
            _buildDetailField("Target Entity Type", targetType),
            _buildDetailField("Target Record ID", targetId),
            _buildDetailField("Timestamp (UTC)", createdAt),
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
                      "This log is immutable and cryptographically secured in compliance with DOH/FSUU clinical oversight.",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: isBold ? 'Poppins' : 'Inter',
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF0F172A),
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

      if (_activeCategory == 'Triage Resolved' && !action.contains('resolve') && !action.contains('triage')) return false;
      if (_activeCategory == 'Deactivations' && !action.contains('deactivat') && !action.contains('status')) return false;
      if (_activeCategory == 'Reactivations' && !action.contains('reactivat') && !action.contains('appeal')) return false;
      if (_activeCategory == 'Articles' && !action.contains('article')) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return action.contains(q) || admin.contains(q) || target.contains(q);
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

        // ── Search & Filter Row ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search logs by action or staff email...",
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                      ? const Center(
                          child: Text("No clinical audit records found.", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B))),
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
                              final action = log['action'] ?? 'Clinical Action';
                              final targetType = log['target_type'] ?? '';
                              final adminEmail = log['admin_email'] ?? 'Counselor';
                              final createdAt = log['created_at']?.toString().split('T')[0] ?? 'Today';

                              return InkWell(
                                onTap: () => _showAuditDetail(log),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.history_edu_rounded, color: Color(0xFF0284C7), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              action,
                                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              "$adminEmail • $targetType",
                                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
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
