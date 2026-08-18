import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
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

  FlaggedIncidentItem({
    required this.id,
    required this.userEmail,
    required this.content,
    required this.createdAt,
    required this.severity,
    required this.severityColor,
    required this.triggerKeywords,
    this.isResolved = false,
  });

  factory FlaggedIncidentItem.fromJson(Map<String, dynamic> json) {
    final content = json['content']?.toString() ?? '';
    final contentLower = content.toLowerCase();

    String severity = 'MODERATE';
    Color severityColor = const Color(0xFFE65100);
    List<String> keywords = [];

    if (contentLower.contains('die') ||
        contentLower.contains('suicide') ||
        contentLower.contains('kill') ||
        contentLower.contains('hurt') ||
        contentLower.contains('end my life')) {
      severity = 'CRITICAL';
      severityColor = const Color(0xFFC62828);
      keywords.add('Self-Harm / Crisis');
    } else if (contentLower.contains('panic') ||
        contentLower.contains('hopeless') ||
        contentLower.contains('cant breathe') ||
        contentLower.contains('overwhelm')) {
      severity = 'HIGH';
      severityColor = const Color(0xFFD97706);
      keywords.add('Acute Anxiety');
    } else {
      keywords.add('Emotional Distress');
    }

    return FlaggedIncidentItem(
      id: json['id']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? 'client@example.com',
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

class _AdminModerationScreenState extends State<AdminModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<FlaggedIncidentItem> _incidents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFlaggedMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFlaggedMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient().get('/admin/flagged-messages?limit=50');
      if (mounted) {
        final rawList = data as List<dynamic>;
        setState(() {
          _incidents = rawList.map((m) => FlaggedIncidentItem.fromJson(m as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load flagged messages';
          _isLoading = false;
        });
      }
    }
  }

  void _simulateTestIncident() {
    setState(() {
      _incidents.insert(
        0,
        FlaggedIncidentItem(
          id: 'sim-${DateTime.now().millisecondsSinceEpoch}',
          userEmail: 'balbuenadexter2@gmail.com',
          content: 'I feel completely overwhelmed by anxiety and hopelessness tonight, I do not know how to cope anymore.',
          createdAt: DateTime.now().toIso8601String(),
          severity: 'CRITICAL',
          severityColor: const Color(0xFFC62828),
          triggerKeywords: ['Hopelessness', 'Acute Overwhelm', 'Self-Harm Risk'],
          isResolved: false,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Simulated Crisis Alert flagged into emergency moderation triage queue!"),
        backgroundColor: Color(0xFFC62828),
      ),
    );
  }

  void _resolveIncident(int index) {
    final item = _incidents[index];
    setState(() {
      item.isResolved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Crisis alert for ${item.userEmail} marked as resolved & logged."),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _assignToDoctor(FlaggedIncidentItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Assign Patient to Clinical Therapist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
              const SizedBox(height: 6),
              Text("Dispatch emergency clinical case to an approved specialist:", style: const TextStyle(fontSize: 13, color: Color(0xFF707974))),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFD6F1FC), child: Text("M", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                title: const Text("Dr. Mark Perez, MD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Clinical Psychologist • Active Now", style: TextStyle(fontSize: 12)),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Emergency case dispatched to Dr. Mark Perez for ${item.userEmail}!"), backgroundColor: AppColors.primary),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text("Assign"),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Text("J", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
                title: const Text("Dr. Jane Smith", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("CBT Specialist • Verified", style: TextStyle(fontSize: 12)),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Emergency case dispatched to Dr. Jane Smith for ${item.userEmail}!"), backgroundColor: AppColors.primary),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text("Assign"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIncidents = _incidents.where((i) => !i.isResolved).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFC62828), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Crisis Moderation & Safety', style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
                Text('${activeIncidents.length} Active Safety Triggers', style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFC62828),
          unselectedLabelColor: const Color(0xFF707974),
          indicatorColor: const Color(0xFFC62828),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: "Incidents Queue (${activeIncidents.length})"),
            const Tab(text: "Safety Rules & Hotlines"),
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
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchFlaggedMessages, child: const Text('Retry')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncidentsTab(activeIncidents),
                    _buildSafetyRulesTab(),
                  ],
                ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Tab 1: Incidents Queue ────────────────────────────────────────────────
  Widget _buildIncidentsTab(List<FlaggedIncidentItem> activeIncidents) {
    if (activeIncidents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Flagged Crisis Messages",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 6),
              const Text(
                "All patient AI chat sessions are operating within safe clinical boundaries.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF707974)),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _simulateTestIncident,
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text("Simulate Test Crisis Alert"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFlaggedMessages,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: activeIncidents.length,
        itemBuilder: (context, index) {
          final incident = activeIncidents[index];
          final rawIdx = _incidents.indexOf(incident);

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
              border: Border.all(color: incident.severityColor.withValues(alpha: 0.3)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
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
                        color: incident.severityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 13, color: incident.severityColor),
                          const SizedBox(width: 4),
                          Text(
                            incident.severity,
                            style: TextStyle(color: incident.severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(formattedDate, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Patient Account: ${incident.userEmail}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 8),

                // Flagged Quote Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEBEE)),
                  ),
                  child: Text(
                    '"${incident.content}"',
                    style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF881337), fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 10),

                // Trigger Keyword Badges
                Wrap(
                  spacing: 6,
                  children: incident.triggerKeywords.map((kw) {
                    return Chip(
                      label: Text(kw, style: const TextStyle(fontSize: 10, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFFFEBEE),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide.none),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Triage Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _assignToDoctor(incident),
                        icon: const Icon(Icons.person_add_rounded, size: 14),
                        label: const Text("Assign Doctor", style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: Color(0xFFD6F1FC)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resolveIncident(rawIdx),
                        icon: const Icon(Icons.check_circle_rounded, size: 14),
                        label: const Text("Resolve", style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  // ── Tab 2: Safety Rules & Hotlines ─────────────────────────────────────────
  Widget _buildSafetyRulesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const Text("Automated Trigger Keywords", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        _buildRuleCard(
          "Acute Self-Harm & Suicide",
          "Keywords: die, suicide, end life, hurt myself, kill",
          "Automated Action: Dispatches emergency NCMH hotline banner & alerts moderation queue.",
          const Color(0xFFC62828),
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          "Acute Panic & Somatic Overload",
          "Keywords: panic attack, cant breathe, heart racing, terrified",
          "Automated Action: Prompts 5-4-3-2-1 sensory grounding & box breathing exercise.",
          const Color(0xFFD97706),
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          "Physical Abuse & Crisis",
          "Keywords: abuse, hitting, domestic violence, trapped",
          "Automated Action: Provides PNP Women & Children Protection Desk hotline (177).",
          const Color(0xFF1565C0),
        ),
        const SizedBox(height: 20),
        const Text("Configured Emergency Hotlines", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        _buildHotlineCard("NCMH National Crisis Helpline", "1553", "24/7 DOH Toll-Free"),
        const SizedBox(height: 6),
        _buildHotlineCard("Hopeline Philippines", "0917-558-4673", "Suicide Prevention"),
      ],
    );
  }

  Widget _buildRuleCard(String title, String keywords, String action, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
            ],
          ),
          const SizedBox(height: 6),
          Text(keywords, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(action, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
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
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C3E50))),
              Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
            ],
          ),
          Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFC62828))),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', false, () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          }),
          _buildNavItem(Icons.people_alt_rounded, 'Users', false, () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          }),
          _buildNavItem(Icons.flag_rounded, 'Moderation', true, null),
          _buildNavItem(Icons.tune_rounded, 'System', false, () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminSystemScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    final color = isSelected ? AppColors.primary : const Color(0xFF707974);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
