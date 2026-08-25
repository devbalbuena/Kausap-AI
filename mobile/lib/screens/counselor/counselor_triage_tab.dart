import 'package:flutter/material.dart';
import '../../services/api_client.dart';
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
  List<dynamic> _flaggedMessages = [];
  String? _error;
  String _resolvedSearch = '';
  final TextEditingController _resolvedSearchCtrl = TextEditingController();

  final List<String> _clinicalActionPresets = [
    "Conducted psychological triage & intake session",
    "Scheduled in-person consultation at FSUU Guidance Center",
    "Dispatched NCMH 1553 emergency resources to student",
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

  Future<void> _fetchFlaggedMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/admin/flagged-messages');
      if (mounted) {
        setState(() {
          _flaggedMessages = res is List ? res : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load crisis triage queue: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveFlag(Map<String, dynamic> flag) async {
    final flagId = flag['id'];
    final studentName = flag['user_name'] ?? 'Student';
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
      await _api.patch(
        '/admin/flagged-messages/$flagId/resolve',
        body: {'resolution_note': noteCtrl.text.trim()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Crisis triage case for $studentName resolved."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _fetchFlaggedMessages();
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

  @override
  Widget build(BuildContext context) {
    final active = _flaggedMessages.where((f) => f['is_resolved'] != true).toList();
    final resolved = _flaggedMessages.where((f) => f['is_resolved'] == true).toList();

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
                          color: const Color(0xFFDC2626),
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
              Tab(text: "Resolved Log (${resolved.length})"),
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
                        _buildResolvedList(resolved),
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
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 14),
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
          final student = item['user_name'] ?? 'Student';
          final email = item['user_email'] ?? '';
          final reason = item['flag_reason'] ?? 'Crisis Trigger';
          final excerpt = item['message_text'] ?? '';
          final createdAt = item['created_at']?.toString().split('T')[0] ?? 'Today';

          final isHighRisk = reason.toLowerCase().contains('suicide') || reason.toLowerCase().contains('harm') || reason.toLowerCase().contains('crisis');

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

  Widget _buildResolvedList(List<dynamic> list) {
    final filtered = list.where((item) {
      if (_resolvedSearch.isEmpty) return true;
      final q = _resolvedSearch.toLowerCase();
      final name = (item['user_name'] ?? '').toString().toLowerCase();
      final note = (item['resolution_note'] ?? '').toString().toLowerCase();
      return name.contains(q) || note.contains(q);
    }).toList();

    return Column(
      children: [
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
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
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text("No resolved crisis records found.", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B))),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['user_name'] ?? 'Student',
                                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                                  SizedBox(width: 4),
                                  Text("Resolved", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Clinical Action: ${item['resolution_note'] ?? 'Resolved by Counselor'}",
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF475569)),
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
          title: "FSUU Guidance & Testing Center",
          description: "On-campus clinical counseling and psychological support",
          phone: "(085) 342-1830",
          email: "guidance@urios.edu.ph",
          badge: "FSUU Official",
          color: const Color(0xFF0284C7),
          bg: const Color(0xFFE0F2FE),
        ),
        const SizedBox(height: 12),
        _buildHotlineCard(
          title: "National Center for Mental Health (NCMH)",
          description: "24/7 National Crisis Hotline (Toll-Free in PH)",
          phone: "1553 / 0917-899-USAP (8727)",
          email: "ncmh.gov.ph",
          badge: "24/7 Emergency",
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEE2E2),
        ),
        const SizedBox(height: 12),
        _buildHotlineCard(
          title: "In Touch Community Services",
          description: "Free and confidential 24/7 crisis support",
          phone: "+63 917 800 1123 / +63 2 8893 7603",
          email: "crisisline@in-touch.org",
          badge: "Confidential",
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
        ),
      ],
    );
  }

  Widget _buildHotlineCard({
    required String title,
    required String description,
    required String phone,
    required String email,
    required String badge,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text(phone, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(email, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF475569))),
            ],
          ),
        ],
      ),
    );
  }
}
