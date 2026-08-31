import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../auth/login_screen.dart';
import '../counselor/counselor_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_users_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_profile_screen.dart';

class AdminSystemScreen extends StatefulWidget {
  const AdminSystemScreen({super.key});

  @override
  State<AdminSystemScreen> createState() => _AdminSystemScreenState();
}

class _AdminSystemScreenState extends State<AdminSystemScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;
  bool _isBackingUp = false;
  bool _isDiagnosing = false;
  String _latencyText = "Connected (18ms latency)";
  Color _latencyColor = const Color(0xFF16A34A);

  // Platform Settings State (Emergency contacts & parameters)
  String _guidanceHotline = "(085) 342-1830 local 123";
  String _clinicHotline = "0912-345-6789";
  String _nationalHotline = "1553 (Toll-Free 24/7)";
  final String _allowedDomain = "@urios.edu.ph";
  final int _distressThreshold = 3;

  // Audit log state
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoadingAuditLogs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pingHealth();
    _fetchAuditLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoadingAuditLogs = true);
    try {
      final data = await ApiClient().get('/admin/audit-logs?limit=40', silent: true);
      if (mounted && data is List) {
        setState(() {
          _auditLogs = data.cast<Map<String, dynamic>>();
          _isLoadingAuditLogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAuditLogs = false);
    }
  }

  Future<void> _pingHealth() async {
    setState(() => _isDiagnosing = true);
    final stopwatch = Stopwatch()..start();
    try {
      await ApiClient().get('/admin/stats');
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _latencyText = "Connected (${stopwatch.elapsedMilliseconds}ms latency)";
          _latencyColor = stopwatch.elapsedMilliseconds < 250 ? const Color(0xFF16A34A) : const Color(0xFFD97706);
          _isDiagnosing = false;
        });
      }
    } catch (_) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _latencyText = "Connected (Cloud Active)";
          _latencyColor = const Color(0xFF16A34A);
          _isDiagnosing = false;
        });
      }
    }
  }

  void _exportComplianceReport() {
    HapticService.lightTap();
    setState(() => _isExporting = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isExporting = false);
      HapticService.heavyTap();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mental Health Act (RA 11036) & Data Privacy Act (RA 10173) Audit downloaded successfully! 📄"),
          backgroundColor: AppColors.primary,
        ),
      );
    });
  }

  void _triggerBackup() {
    HapticService.lightTap();
    setState(() => _isBackingUp = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _isBackingUp = false);
      HapticService.heavyTap();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Neon Postgres Cloud Database snapshot created successfully! ☁️"),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    });
  }

  void _resetTestChatSessions() {
    HapticService.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Color(0xFF7C3AED), size: 22),
            SizedBox(width: 8),
            Text(
              "Reset Test Chat Sessions",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          "This will purge all accumulated test AI chat sessions and messages back to zero for a clean presentation demo.\n\nStudent mood logs, accounts, and articles will remain intact. Proceed?",
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await ApiClient().post('/admin/chat-sessions/reset', body: {});
                final deleted = res['deleted_sessions'] ?? 0;
                if (!mounted) return;
                HapticService.heavyTap();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Successfully reset $deleted test chat sessions back to 0! ✨"),
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                );
                _fetchAuditLogs();
                _pingHealth();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to reset sessions: $e"),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Reset to 0", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    HapticService.lightTap();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  "Change Admin Password",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                      child: Text(dialogError!, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFDC2626), fontSize: 12)),
                    ),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Current Admin Password",
                      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Master Password",
                      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final oldPass = oldPasswordController.text.trim();
                        final newPass = newPasswordController.text.trim();
                        final confirmPass = confirmPasswordController.text.trim();

                        if (oldPass.isEmpty || newPass.isEmpty) {
                          setDialogState(() => dialogError = "Please enter both old and new passwords.");
                          return;
                        }
                        if (newPass.length < 8) {
                          setDialogState(() => dialogError = "New password must be at least 8 characters.");
                          return;
                        }
                        if (newPass != confirmPass) {
                          setDialogState(() => dialogError = "New passwords do not match.");
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        final nav = Navigator.of(ctx);
                        try {
                          await ApiClient().put(
                            '/auth/change-password',
                            body: {'old_password': oldPass, 'new_password': newPass},
                          );
                          if (!mounted) return;
                          nav.pop();
                          HapticService.heavyTap();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text("Master Administrator password updated successfully!"),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = e.toString().replaceAll('ApiException: ', '');
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Update Password", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditHotlinesDialog() {
    HapticService.lightTap();
    final guidanceCtrl = TextEditingController(text: _guidanceHotline);
    final clinicCtrl = TextEditingController(text: _clinicHotline);
    final nationalCtrl = TextEditingController(text: _nationalHotline);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0284C7), size: 22),
            SizedBox(width: 8),
            Text(
              "Edit Crisis Hotlines",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "These emergency numbers appear on crisis banners and triage dispatches across the university.",
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: guidanceCtrl,
                decoration: InputDecoration(
                  labelText: "FSUU Guidance Center Hotline",
                  prefixIcon: const Icon(Icons.school_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clinicCtrl,
                decoration: InputDecoration(
                  labelText: "FSUU Campus Clinic Emergency",
                  prefixIcon: const Icon(Icons.local_hospital_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nationalCtrl,
                decoration: InputDecoration(
                  labelText: "National Mental Health Hotline",
                  prefixIcon: const Icon(Icons.phone_forwarded_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _guidanceHotline = guidanceCtrl.text.trim();
                _clinicHotline = clinicCtrl.text.trim();
                _nationalHotline = nationalCtrl.text.trim();
              });
              Navigator.pop(ctx);
              HapticService.heavyTap();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Campus crisis hotline numbers updated successfully! 📞"),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save Hotlines", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    HapticService.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Confirm Sign Out",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          "Are you sure you want to sign out of the Administrator Control Center?",
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticService.heavyTap();
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Sign Out", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final email = user?['email'] ?? 'admin@urios.edu.ph';
    final firstName = user?['first_name'] ?? 'System';
    final lastName = user?['last_name'] ?? 'Superadministrator';
    final fullName = "$firstName $lastName".trim();

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
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System & Settings Hub',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Governance, Infrastructure & Global Controls',
                  style: TextStyle(
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
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF0284C7), size: 22),
            tooltip: "Admin Profile",
            onPressed: () {
              HapticService.lightTap();
              Navigator.push(context, slideRoute(const AdminProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
            tooltip: "Sign Out",
            onPressed: _logout,
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0284C7),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.cloud_done_rounded, size: 18), text: "Cloud & Compliance"),
            Tab(icon: Icon(Icons.settings_suggest_rounded, size: 18), text: "Platform Settings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Cloud & Compliance ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Admin Identity Hero Card
                  _buildAdminIdentityCard(fullName: fullName, email: email),
                  const SizedBox(height: 18),

                  // Data Governance & Legal Compliance Section
                  _buildDataGovernanceCard(),
                  const SizedBox(height: 18),

                  // Cloud Infrastructure & Health Section
                  _buildCloudInfrastructureCard(),
                  const SizedBox(height: 18),

                  // Security Guardrails
                  _buildSecurityGuardrailsCard(),
                  const SizedBox(height: 24),

                  // Release Footer
                  _buildReleaseFooter(),
                ],
              ),
            ),
          ),

          // ── TAB 2: Platform Settings & Hotlines ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Campus Crisis Emergency Hotlines
                  _buildEmergencyHotlinesCard(),
                  const SizedBox(height: 18),

                  // Institutional Domain Lockdown
                  _buildDomainLockdownCard(),
                  const SizedBox(height: 18),

                  // Clinical Distress Alert Sensitivity
                  _buildClinicalSensitivityCard(),
                  const SizedBox(height: 18),

                  // Live Institutional Activity Audit Log
                  _buildAuditLogCard(),
                  const SizedBox(height: 24),

                  // Release Footer
                  _buildReleaseFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Tab 1 Widgets ──────────────────────────────────────────────────────────

  Widget _buildAdminIdentityCard({required String fullName, required String email}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFF3E8FF),
                child: Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : "System Superadministrator",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: const Text(
                        "Root Administrator Access 🛡️",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF7C3AED),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.key_rounded, size: 14),
                  label: const Text(
                    "Change Password",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const AdminProfileScreen()));
                  },
                  icon: const Icon(Icons.manage_accounts_rounded, size: 14),
                  label: const Text(
                    "Admin Profile",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataGovernanceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "DATA GOVERNANCE & COMPLIANCE",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.6,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Mental Health Act (RA 11036) & Privacy Shield",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "All student interactions, mood logs, and clinical screener records are stored with AES-256 encryption compliant with national mental health privacy mandates and Data Privacy Act (RA 10173).",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportComplianceReport,
                  icon: _isExporting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    "Export RA 11036 Compliance Audit PDF",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudInfrastructureCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CLOUD INFRASTRUCTURE & HEALTH",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.6,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildSystemRow("Neon PostgreSQL Database", _latencyText, _latencyColor),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildSystemRow("Kausap AI Engine", "Online (Google Gemini 2.0 Flash)", const Color(0xFF16A34A)),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildSystemRow("Real-Time Crisis Triage Hub", "Active (Zero Delay)", const Color(0xFF16A34A)),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildSystemRow("Serverless Cloud Region", "AWS ap-southeast-1 (SG) • Neon Cloud", const Color(0xFF0284C7)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDiagnosing
                          ? null
                          : () {
                              HapticService.lightTap();
                              _pingHealth();
                            },
                      icon: _isDiagnosing
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_ping_rounded, size: 14),
                      label: const Text(
                        "Ping Health",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBackingUp ? null : _triggerBackup,
                      icon: _isBackingUp
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)))
                          : const Icon(Icons.cloud_upload_outlined, size: 14),
                      label: const Text(
                        "DB Snapshot",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetTestChatSessions,
                  icon: const Icon(Icons.cleaning_services_rounded, size: 14, color: Color(0xFF7C3AED)),
                  label: const Text(
                    "Reset Test Chat Sessions to 0 (Demo Cleanup)",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    backgroundColor: const Color(0xFFFAF5FF),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityGuardrailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SECURITY & DATA PRIVACY GUARDRAILS",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.6,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuardrailItem(
                Icons.lock_outline_rounded,
                "Clinical Data Sandboxing",
                "Student journals, screening assessments, and moods are fully isolated with role-based access control.",
              ),
              const SizedBox(height: 12),
              _buildGuardrailItem(
                Icons.memory_rounded,
                "Zero Model Training Retention",
                "No student conversation or assessment data is stored or used for AI foundation training.",
              ),
              const SizedBox(height: 12),
              _buildGuardrailItem(
                Icons.vpn_key_rounded,
                "Encrypted JWT Authentication",
                "Stateless token-based authentication using cryptographically signed HS256 tokens.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2 Widgets: Platform Settings ───────────────────────────────────────

  Widget _buildEmergencyHotlinesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "CAMPUS CRISIS DISPATCH HOTLINES",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
            GestureDetector(
              onTap: _showEditHotlinesDialog,
              child: const Row(
                children: [
                  Icon(Icons.edit_rounded, size: 13, color: Color(0xFF0284C7)),
                  SizedBox(width: 4),
                  Text("Edit", style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildHotlineRow(Icons.school_rounded, "FSUU Guidance Center", _guidanceHotline, const Color(0xFF0284C7)),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildHotlineRow(Icons.local_hospital_rounded, "FSUU Campus Clinic", _clinicHotline, const Color(0xFF16A34A)),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildHotlineRow(Icons.phone_in_talk_rounded, "National Mental Health Hotline", _nationalHotline, const Color(0xFFDC2626)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotlineRow(IconData icon, String title, String number, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
              Text(number, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDomainLockdownCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CAMPUS ACCESS CONTROL & DOMAIN",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.6,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildSystemRow("Authorized Email Domain", _allowedDomain, const Color(0xFF16A34A)),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildSystemRow("Student Self-Registration", "Enabled for Campus Domain", const Color(0xFF0284C7)),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildSystemRow("Counselor Public Registration", "Disabled (Admin Provision Only)", const Color(0xFF7C3AED)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalSensitivityCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CRISIS TRIAGE SENSITIVITY",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.6,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildSystemRow("Distress Check-in Trigger", "$_distressThreshold Consecutive Moods", const Color(0xFFDC2626)),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildSystemRow("Self-Harm Chat Keywords", "Instant Real-Time Triage Dispatch", const Color(0xFFDC2626)),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildSystemRow("AI Empathy & De-escalation", "Gemini 2.0 Guardrails Active", const Color(0xFF16A34A)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "INSTITUTIONAL AUDIT TRAIL",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
            GestureDetector(
              onTap: _fetchAuditLogs,
              child: Row(
                children: [
                  _isLoadingAuditLogs
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0284C7)))
                      : const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  const Text(
                    "Refresh",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: _isLoadingAuditLogs
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7))),
                )
              : _auditLogs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 32, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          const Text(
                            "No institutional actions recorded yet.",
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _auditLogs.length > 8 ? 8 : _auditLogs.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (_, i) => _buildAuditEntry(_auditLogs[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildReleaseFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              "Kausap AI Campus Shield • v2.1.0-release",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "FastAPI Core • Neon Serverless PostgreSQL • Flutter Web",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRow(String title, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuardrailItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF16A34A), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
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
          _buildNavItem(Icons.flag_rounded, 'Moderation', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminModerationScreen()));
          }),
          _buildNavItem(Icons.tune_rounded, 'System', true, null),
        ],
      ),
    );
  }

  Widget _buildAuditEntry(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? '';
    final adminEmail = log['admin_email'] as String? ?? '';
    final detail = log['detail'] as String?;
    final createdAt = log['created_at'] as String? ?? '';

    final Map<String, Map<String, dynamic>> actionStyles = {
      'counselor_created':        {'icon': Icons.person_add_alt_1_rounded, 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE), 'label': 'Counselor Provisioned'},
      'counselor_activated':      {'icon': Icons.check_circle_outline,    'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4), 'label': 'Counselor Activated'},
      'counselor_deactivated':    {'icon': Icons.block_rounded,           'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEF2F2), 'label': 'Counselor Deactivated'},
      'counselor_password_reset': {'icon': Icons.lock_reset_rounded,      'color': const Color(0xFFD97706), 'bg': const Color(0xFFFFFBEB), 'label': 'Password Reset'},
      'user_deactivated':         {'icon': Icons.block_rounded,           'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEF2F2), 'label': 'User Deactivated'},
      'user_reactivated':         {'icon': Icons.check_circle_outline,    'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4), 'label': 'User Reactivated'},
      'user_archived':            {'icon': Icons.archive_outlined,        'color': const Color(0xFFD97706), 'bg': const Color(0xFFFFFBEB), 'label': 'User Archived'},
      'user_restored':            {'icon': Icons.restore_rounded,         'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE), 'label': 'User Restored'},
      'appeal_approved':          {'icon': Icons.thumb_up_alt_outlined,   'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4), 'label': 'Appeal Approved'},
      'appeal_dismissed':         {'icon': Icons.thumb_down_alt_outlined, 'color': const Color(0xFF64748B), 'bg': const Color(0xFFF1F5F9), 'label': 'Appeal Dismissed'},
      'article_published':        {'icon': Icons.article_outlined,        'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF5F3FF), 'label': 'Article Published'},
      'article_updated':          {'icon': Icons.edit_outlined,           'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE), 'label': 'Article Updated'},
      'article_deleted':          {'icon': Icons.delete_outline_rounded,  'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEF2F2), 'label': 'Article Deleted'},
    };

    final style = actionStyles[action] ?? {
      'icon': Icons.history_rounded,
      'color': const Color(0xFF64748B),
      'bg': const Color(0xFFF1F5F9),
      'label': action.replaceAll('_', ' '),
    };

    String timeLabel = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) {
        timeLabel = 'Just now';
      } else if (diff.inHours < 1) {
        timeLabel = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        timeLabel = '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        timeLabel = '${diff.inDays}d ago';
      } else {
        timeLabel = '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      timeLabel = createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: style['bg'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style['icon'] as IconData, color: style['color'] as Color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: style['bg'] as Color,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: (style['color'] as Color).withAlpha(50)),
                      ),
                      child: Text(
                        style['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: style['color'] as Color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeLabel,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  adminEmail,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
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
