import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import '../counselor/counselor_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_users_screen.dart';
import 'admin_system_screen.dart';
import 'widgets/admin_header_actions.dart';

class FlaggedIncidentItem {
  final String id;
  final String userEmail;
  final String userName;
  final String content;
  final String createdAt;
  final String severity; // CRITICAL, HIGH, MODERATE
  final Color severityColor;
  final List<String> triggerKeywords;
  bool isResolved;
  String? resolvedAt;
  String? resolutionNote;

  FlaggedIncidentItem({
    required this.id,
    required this.userEmail,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.severity,
    required this.severityColor,
    required this.triggerKeywords,
    this.isResolved = false,
    this.resolvedAt,
    this.resolutionNote,
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

    final bool isResolved = json['is_resolved'] == true;
    final String? rawResolvedAt = json['resolved_at']?.toString();
    String? formattedResolvedAt;
    if (rawResolvedAt != null && rawResolvedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawResolvedAt).toLocal();
        formattedResolvedAt = DateFormat('MMM d, h:mm a').format(dt);
      } catch (_) {
        formattedResolvedAt = rawResolvedAt;
      }
    }

    final String? resolutionNote = json['resolution_note']?.toString();
    final String userEmail = json['user_email']?.toString() ?? 'student@urios.edu.ph';
    final String userName = json['user_name']?.toString() ?? (userEmail.contains('@') ? userEmail.split('@')[0] : 'Student');

    return FlaggedIncidentItem(
      id: json['id']?.toString() ?? '',
      userEmail: userEmail,
      userName: userName,
      content: content,
      createdAt: json['created_at']?.toString() ?? '',
      severity: severity,
      severityColor: severityColor,
      triggerKeywords: keywords,
      isResolved: isResolved,
      resolvedAt: formattedResolvedAt,
      resolutionNote: resolutionNote,
    );
  }
}

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  List<FlaggedIncidentItem> _incidents = [];
  List<FlaggedIncidentItem> _resolvedHistory = [];
  String? _error;
  String _resolvedSearch = '';
  final TextEditingController _resolvedSearchCtrl = TextEditingController();

  // Dynamic Hotlines state
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

  Future<void> _fetchFlaggedMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.get('/admin/flagged-messages?limit=100');
      if (mounted) {
        final rawList = (data as List<dynamic>?) ?? [];
        final parsed = rawList.map((m) => FlaggedIncidentItem.fromJson(m as Map<String, dynamic>)).toList();
        setState(() {
          _incidents = parsed.where((i) => !i.isResolved).toList();
          _resolvedHistory = parsed.where((i) => i.isResolved).toList();
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

  Future<void> _fetchHotlines() async {
    setState(() => _isLoadingHotlines = true);
    try {
      final res = await _api.get('/crisis/hotlines');
      if (mounted && res is List && res.isNotEmpty) {
        setState(() {
          _hotlinesList = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoadingHotlines = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHotlines = false);
  }

  Future<void> _resolveIncident(FlaggedIncidentItem item) async {
    String selectedPreset = _clinicalActionPresets[0];
    final noteCtrl = TextEditingController(text: selectedPreset);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Resolve Crisis Triage",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
                ),
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
                  Text(
                    "Resolving incident for ${item.userName} (${item.userEmail}). This will sync across counselor and administration dashboards.",
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Text("Select Clinical Action:", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _clinicalActionPresets.map((preset) {
                      final isSelected = selectedPreset == preset;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedPreset = preset;
                            noteCtrl.text = preset;
                          });
                        },
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Resolution & Compliance Note *",
                      hintText: "Enter specific guidance action taken...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Confirm Resolution", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    HapticService.mediumTap();
    final note = noteCtrl.text.trim();
    final nowFormatted = DateFormat('MMM d, h:mm a').format(DateTime.now());

    setState(() {
      item.isResolved = true;
      item.resolvedAt = nowFormatted;
      item.resolutionNote = note;
      _incidents.removeWhere((i) => i.id == item.id);
      _resolvedHistory.insert(0, item);
    });

    try {
      if (item.id.isNotEmpty) {
        await _api.patch(
          '/admin/flagged-messages/${item.id}/resolve',
          body: {'resolution_note': note},
          silent: true,
        );
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Crisis alert for ${item.userEmail} marked as resolved & synced."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _fetchFlaggedMessages();
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
          "Are you sure you want to mark all ${active.length} active crisis distress alerts as resolved? This will sync to counselor triage.",
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
        item.resolutionNote = "Batch crisis resolution processed by administrator.";
        _resolvedHistory.insert(0, item);
      }
      _incidents.clear();
    });

    try {
      await _api.post('/admin/flagged-messages/resolve-all');
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All ${active.length} alerts marked as resolved & synced."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _fetchFlaggedMessages();
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
            Icon(Icons.phone_in_talk_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              "Dispatch Crisis Hotlines",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Primary emergency contacts for student outreach for ${item.userEmail}:",
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            _buildHotlineCard("FSUU Guidance Center", "(085) 342-1830", "Main Campus Emergency Line"),
            const SizedBox(height: 8),
            _buildHotlineCard("National Crisis Helpline (NCMH)", "1553", "24/7 DOH Toll-Free"),
            const SizedBox(height: 8),
            _buildHotlineCard("Hopeline Philippines", "0917-558-4673", "24/7 Suicide Prevention Line"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Close", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showStudentQuickContact(FlaggedIncidentItem item) {
    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    item.userName.isNotEmpty ? item.userName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Emergency Status", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
                      Text(item.isResolved ? "✅ Resolved" : "⚠️ Active Distress Flag", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: item.isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                    ],
                  ),
                  if (item.resolutionNote != null && item.resolutionNote!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Resolution Note", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.resolutionNote!,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  // ── Hotlines Management CRUD ──
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
                    'This contact will immediately sync to Student SOS, Profile & Counselor triage in real time.',
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

  @override
  Widget build(BuildContext context) {
    final activeIncidents = _incidents.where((i) => !i.isResolved).toList();

    return Scaffold(
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
        actions: [
          AdminHeaderActions(
            onRefresh: () async {
              await _fetchFlaggedMessages();
              await _fetchHotlines();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
                  controller: _tabController,
                  children: [
                    _buildIncidentsTab(activeIncidents),
                    _buildResolvedHistoryTab(),
                    _buildSafetyRulesTab(),
                  ],
                ),
      bottomNavigationBar: _buildBottomNav(),
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
          constraints: const BoxConstraints(maxWidth: 520),
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
                            "${incident.userName} (${incident.userEmail})",
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
                              "Helplines",
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
    final filtered = _resolvedHistory.where((item) {
      if (_resolvedSearch.isEmpty) return true;
      final q = _resolvedSearch.toLowerCase();
      final name = item.userName.toLowerCase();
      final email = item.userEmail.toLowerCase();
      final note = (item.resolutionNote ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || note.contains(q);
    }).toList();

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
                "No Resolved Crisis Logs",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "When crisis alerts are resolved during counselor or administrator triage, they are archived here for clinical compliance.",
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _resolvedSearchCtrl,
                onChanged: (val) => setState(() => _resolvedSearch = val),
                decoration: InputDecoration(
                  hintText: "Search resolved logs by student, email, or note...",
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchFlaggedMessages,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                          const SizedBox(height: 8),
                          Text(
                            "${item.userName} • ${item.userEmail}",
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${item.content}"',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.resolutionNote != null && item.resolutionNote!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.resolutionNote!,
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Dynamic Live Emergency Hotlines & Safety Rules ─────────────────
  Widget _buildSafetyRulesTab() {
    final filteredHotlines = _hotlinesList.where((h) {
      if (_selectedHotlineCategory == 'all') return true;
      return (h['category'] ?? '').toString().toLowerCase() == _selectedHotlineCategory;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: [
            // Top Section: Hotline Management Bar
            Container(
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Crisis Hotlines Directory',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Shared with Counselor Triage & Student SOS',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showHotlineDialog(),
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text('+ Add'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHotlineFilterChip('All', 'all'),
                        const SizedBox(width: 6),
                        _buildHotlineFilterChip('🏫 Campus', 'campus'),
                        const SizedBox(width: 6),
                        _buildHotlineFilterChip('🇵🇭 National', 'national'),
                        const SizedBox(width: 6),
                        _buildHotlineFilterChip('🚑 911 Emergency', 'emergency'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hotlines Cards
            if (_isLoadingHotlines)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (filteredHotlines.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: Text('No hotlines found in this category.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
                ),
              )
            else
              ...filteredHotlines.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDynamicHotlineCard(h),
                  )),

            const SizedBox(height: 20),
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
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
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
      badgeLabel = 'Campus';
    } else if (category == 'emergency') {
      themeColor = const Color(0xFFDC2626);
      icon = Icons.emergency_rounded;
      badgeLabel = '911 Emergency';
    } else {
      themeColor = const Color(0xFF16A34A);
      icon = type == 'sms' ? Icons.sms_rounded : Icons.health_and_safety_rounded;
      badgeLabel = 'National 24/7';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: themeColor, size: 20),
          ),
          const SizedBox(width: 10),
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
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 9.5, color: themeColor),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(type == 'sms' ? Icons.sms_outlined : Icons.phone_rounded, size: 13, color: themeColor),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11, color: themeColor),
                    ),
                  ],
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        email,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              IconButton(
                tooltip: 'Edit Hotline',
                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                onPressed: () => _showHotlineDialog(hotline),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              IconButton(
                tooltip: 'Archive Hotline',
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
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
            final role = context.read<AuthProvider>().currentUser?['role'];
            if (role == 'counselor') {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CounselorDashboardScreen()));
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            }
          }),
          _buildNavItem(Icons.article_rounded, 'Articles', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminArticlesScreen()));
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
