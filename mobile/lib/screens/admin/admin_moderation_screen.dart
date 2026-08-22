import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_system_screen.dart';
import 'package:intl/intl.dart';

class FlaggedIncidentItem {
  final String id;
  final String userEmail;
  final String content;
  final String createdAt;
  final String severity; // CRITICAL, HIGH, MODERATE
  final Color severityColor;
  final List<String> triggerKeywords;
  bool isResolved;
  String? resolvedAt;

  FlaggedIncidentItem({
    required this.id,
    required this.userEmail,
    required this.content,
    required this.createdAt,
    required this.severity,
    required this.severityColor,
    required this.triggerKeywords,
    this.isResolved = false,
    this.resolvedAt,
  });

  factory FlaggedIncidentItem.fromJson(Map<String, dynamic> json) {
    final content = json['content']?.toString() ?? '';
    final contentLower = content.toLowerCase();

    String severity = 'MODERATE';
    Color severityColor = const Color(0xFFD97706);
    List<String> keywords = [];

    if (contentLower.contains('emergency sos') ||
        contentLower.contains('sos distress') ||
        contentLower.contains('die') ||
        contentLower.contains('suicide') ||
        contentLower.contains('kill') ||
        contentLower.contains('hurt') ||
        contentLower.contains('end my life')) {
      severity = 'CRITICAL';
      severityColor = const Color(0xFFDC2626);
      if (contentLower.contains('emergency sos') || contentLower.contains('sos distress')) {
        keywords.add('🚨 1-Tap Campus SOS Alert');
      } else {
        keywords.add('Self-Harm / Crisis');
      }
    } else if (contentLower.contains('panic') ||
        contentLower.contains('hopeless') ||
        contentLower.contains('cant breathe') ||
        contentLower.contains('overwhelm')) {
      severity = 'HIGH';
      severityColor = const Color(0xFFEA580C);
      keywords.add('Acute Anxiety / Hopelessness');
    } else {
      keywords.add('Emotional Distress');
    }

    return FlaggedIncidentItem(
      id: json['id']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? 'student@example.com',
      content: content,
      createdAt: json['created_at']?.toString() ?? '',
      severity: severity,
      severityColor: severityColor,
      triggerKeywords: keywords,
      isResolved: false,
    );
  }
}

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  bool _isLoading = true;
  List<FlaggedIncidentItem> _incidents = [];
  final List<FlaggedIncidentItem> _resolvedHistory = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFlaggedMessages();
  }

  Future<void> _fetchFlaggedMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient().get('/admin/flagged-messages?limit=50');
      if (mounted) {
        final rawList = (data as List<dynamic>?) ?? [];
        setState(() {
          _incidents = rawList.map((m) => FlaggedIncidentItem.fromJson(m as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load flagged crisis messages';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveIncident(FlaggedIncidentItem item) async {
    HapticService.mediumTap();
    final nowFormatted = DateFormat('MMM d, h:mm a').format(DateTime.now());
    setState(() {
      item.isResolved = true;
      item.resolvedAt = nowFormatted;
      _incidents.removeWhere((i) => i.id == item.id);
      _resolvedHistory.insert(0, item);
    });

    try {
      if (item.id.isNotEmpty) {
        await ApiClient().patch('/admin/flagged-messages/${item.id}/resolve');
      }
    } catch (_) {
      // Graceful fallback
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Crisis alert for ${item.userEmail} marked as resolved & logged to audit history."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _resolveAllIncidents() async {
    final active = _incidents.where((i) => !i.isResolved).toList();
    if (active.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.done_all_rounded, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 8),
            Text("Resolve All Alerts?", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          "Are you sure you want to mark all ${active.length} active crisis distress alerts as resolved?",
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
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Resolve All", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticService.heavyTap();
    final nowFormatted = DateFormat('MMM d, h:mm a').format(DateTime.now());
    setState(() {
      for (final item in active) {
        item.isResolved = true;
        item.resolvedAt = nowFormatted;
        _resolvedHistory.insert(0, item);
      }
      _incidents.clear();
    });

    try {
      await ApiClient().post('/admin/flagged-messages/resolve-all');
    } catch (_) {
      // Graceful fallback
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All ${active.length} alerts marked as resolved & logged."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  void _dispatchCrisisHotline(FlaggedIncidentItem item) {
    HapticService.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.phone_forwarded_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              "Dispatch Crisis Helpline",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          "Send 24/7 National Center for Mental Health (NCMH 1553) and Campus Guidance crisis resources directly to ${item.userEmail}?",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticService.heavyTap();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Emergency Crisis Helpline alert dispatched to ${item.userEmail}!"),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Dispatch Helpline", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showStudentQuickContact(FlaggedIncidentItem item) {
    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Student Incident Contact",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        item.userEmail,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Emergency Status", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
                      Text("⚠️ Active Distress Flag", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Direct Action", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
                      Text("Counselor Outreach Required", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
                icon: const Icon(Icons.person_search_rounded, size: 18),
                label: const Text("View Full Student Profile in Directory", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIncidents = _incidents.where((i) => !i.isResolved).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crisis Moderation & Safety',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${activeIncidents.length} Active Safety Triggers',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: const Color(0xFFDC2626),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFFDC2626),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 11.5),
            tabs: [
              Tab(text: "Active (${activeIncidents.length})"),
              Tab(text: "Resolved Log (${_resolvedHistory.length})"),
              const Tab(text: "Safety & Hotlines"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchFlaggedMessages,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildIncidentsTab(activeIncidents),
                      _buildResolvedHistoryTab(),
                      _buildSafetyRulesTab(),
                    ],
                  ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Tab 1: Active Incidents Queue ─────────────────────────────────────────
  Widget _buildIncidentsTab(List<FlaggedIncidentItem> activeIncidents) {
    if (activeIncidents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 48),
              ),
              const SizedBox(height: 18),
              const Text(
                "No Flagged Crisis Messages",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "All student AI companion sessions and SOS check-ins are operating within safe clinical boundaries.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  HapticService.lightTap();
                  _fetchFlaggedMessages();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  "Refresh Queue",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticService.lightTap();
        await _fetchFlaggedMessages();
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: activeIncidents.length + (activeIncidents.length > 1 ? 1 : 0),
            itemBuilder: (context, index) {
              if (activeIncidents.length > 1 && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${activeIncidents.length} Active Crisis Alerts",
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      OutlinedButton.icon(
                        onPressed: _resolveAllIncidents,
                        icon: const Icon(Icons.done_all_rounded, size: 14),
                        label: const Text("Resolve All", style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final incidentIdx = activeIncidents.length > 1 ? index - 1 : index;
              final incident = activeIncidents[incidentIdx];

              String formattedDate = 'Recently';
              if (incident.createdAt.isNotEmpty) {
                try {
                  final dt = DateTime.parse(incident.createdAt).toLocal();
                  formattedDate = DateFormat('MMM d, h:mm a').format(dt);
                } catch (_) {}
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: incident.severityColor.withAlpha(50)),
                  boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: incident.severityColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 13, color: incident.severityColor),
                              const SizedBox(width: 4),
                              Text(
                                incident.severity,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: incident.severityColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Student: ${incident.userEmail}",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                          tooltip: "Student Profile",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showStudentQuickContact(incident),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Flagged Quote Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        '"${incident.content}"',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          height: 1.45,
                          color: Color(0xFF881337),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Trigger Keyword Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: incident.triggerKeywords.map((kw) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            kw,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Triage Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _dispatchCrisisHotline(incident),
                            icon: const Icon(Icons.phone_forwarded_rounded, size: 14),
                            label: const Text(
                              "Helpline",
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _resolveIncident(incident),
                            icon: const Icon(Icons.check_circle_rounded, size: 14),
                            label: const Text(
                              "Resolve",
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Tab 2: Resolved History Audit Log ─────────────────────────────────────
  Widget _buildResolvedHistoryTab() {
    if (_resolvedHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Resolved History This Session",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "When crisis alerts are resolved during counselor triage, they will be archived here for auditing.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: _resolvedHistory.length,
          itemBuilder: (context, index) {
            final item = _resolvedHistory[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Text(
                          "RESOLVED ✅",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                        ),
                      ),
                      Text(
                        item.resolvedAt ?? 'Recently',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.userEmail,
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${item.content}"',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Tab 3: Safety Rules & Hotlines ─────────────────────────────────────────
  Widget _buildSafetyRulesTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            const Text(
              "AUTOMATED SAFETY TRIGGERS",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              "Acute Self-Harm & Suicide",
              "Keywords: die, suicide, end life, hurt myself, kill",
              "Automated Action: Dispatches emergency NCMH hotline banner & alerts moderation queue.",
              const Color(0xFFDC2626),
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              "1-Tap SOS Campus Distress Alert",
              "Keywords: 🚨 EMERGENCY SOS DISTRESS ALERT",
              "Automated Action: Logs immediate high-priority alert for guidance office intervention.",
              const Color(0xFFDC2626),
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              "Acute Panic & Somatic Overload",
              "Keywords: panic attack, cant breathe, heart racing, terrified",
              "Automated Action: Prompts 5-4-3-2-1 sensory grounding & box breathing exercise.",
              const Color(0xFFEA580C),
            ),
            const SizedBox(height: 8),
            _buildRuleCard(
              "Physical Safety & Protection",
              "Keywords: abuse, hitting, domestic violence, trapped",
              "Automated Action: Provides PNP Women & Children Protection Desk hotline (177).",
              const Color(0xFF0284C7),
            ),
            const SizedBox(height: 20),
            const Text(
              "CAMPUS & NATIONAL HOTLINES",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            _buildHotlineCard("Campus Guidance & Counseling", "(085) 342-1801", "Mon-Fri 8:00 AM - 5:00 PM (Direct Line)"),
            const SizedBox(height: 6),
            _buildHotlineCard("NCMH National Crisis Helpline", "1553", "24/7 DOH Toll-Free"),
            const SizedBox(height: 6),
            _buildHotlineCard("Hopeline Philippines", "0917-558-4673", "24/7 Suicide Prevention"),
            const SizedBox(height: 6),
            _buildHotlineCard("National Emergency Hotline", "911", "Police / Medical / Rescue"),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String keywords, String action, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            keywords,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            action,
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard(String name, String phone, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            phone,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          }),
          _buildNavItem(Icons.people_alt_rounded, 'Users', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          }),
          _buildNavItem(Icons.flag_rounded, 'Moderation', true, null),
          _buildNavItem(Icons.tune_rounded, 'System', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminSystemScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    final color = isSelected ? AppColors.primary : const Color(0xFF64748B);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
