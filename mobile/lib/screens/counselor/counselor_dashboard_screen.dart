import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import '../auth/login_screen.dart';
import 'counselor_triage_tab.dart';
import 'counselor_students_tab.dart';
import 'counselor_articles_tab.dart';
import 'counselor_audit_tab.dart';

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({super.key});

  @override
  State<CounselorDashboardScreen> createState() => _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState extends State<CounselorDashboardScreen> {
  int _selectedTabIndex = 0; // 0: Overview, 1: Triage, 2: Students, 3: Articles, 4: Audit
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient().get('/admin/stats');
      if (mounted) {
        setState(() {
          _stats = data as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load clinical statistics';
          _isLoading = false;
        });
      }
    }
  }

  void _logout() {
    HapticService.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFC62828), size: 22),
            SizedBox(width: 10),
            Text(
              "Sign Out",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to sign out of the Counselor Guidance Hub?",
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
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Sign Out", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (_selectedTabIndex) {
      case 1:
        return 'Crisis Triage & Intercepts';
      case 2:
        return 'Student Care Directory';
      case 3:
        return 'Psychoeducation CMS';
      case 4:
        return 'Clinical Audit & Compliance';
      case 0:
      default:
        return 'FSUU Guidance Hub';
    }
  }

  String get _appBarSubtitle {
    final user = context.read<AuthProvider>().currentUser;
    final counselorName = user != null ? "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim() : 'Counselor';
    final deptTitle = user?['department_title'] ?? 'Guidance Counselor';

    switch (_selectedTabIndex) {
      case 1:
        return 'Review & resolve risk-flagged student distress cases';
      case 2:
        return 'Student mood histories & reactivation appeals';
      case 3:
        return 'Publish mental health articles for Urian students';
      case 4:
        return 'RA 11036 compliance logs of counselor actions';
      case 0:
      default:
        return counselorName.isNotEmpty ? '$counselorName • $deptTitle' : deptTitle;
    }
  }

  IconData get _appBarIcon {
    switch (_selectedTabIndex) {
      case 1:
        return Icons.health_and_safety_rounded;
      case 2:
        return Icons.people_alt_rounded;
      case 3:
        return Icons.auto_stories_rounded;
      case 4:
        return Icons.verified_user_rounded;
      case 0:
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Icon(_appBarIcon, color: const Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _appBarTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _appBarSubtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedTabIndex == 0)
            IconButton(
              tooltip: 'Refresh Stats',
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
              onPressed: () {
                HapticService.lightTap();
                _fetchStats();
              },
            ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildCurrentTabBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentTabBody() {
    switch (_selectedTabIndex) {
      case 1:
        return const CounselorTriageTab();
      case 2:
        return const CounselorStudentsTab();
      case 3:
        return const CounselorArticlesTab();
      case 4:
        return const CounselorAuditTab();
      case 0:
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchStats,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final flagged = _stats?['total_flagged_messages'] ?? 0;
    final totalStudents = _stats?['total_users'] ?? 0;
    final activeStudents = _stats?['total_active_users'] ?? 0;
    final totalSessions = _stats?['total_chat_sessions'] ?? 0;
    final totalMoods = _stats?['total_mood_entries'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Urgent Crisis Banner (if any) ──
            if (flagged > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$flagged Unresolved Crisis Alert${flagged > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const Text(
                            'Students require immediate psychological triage review.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticService.lightTap();
                        setState(() => _selectedTabIndex = 1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Triage', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            // ── University Guidance Center Intro Banner ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x400284C7),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Father Saturnino Urios University",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Student Wellness & Guidance Hub",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Monitor student emotional health, review AI crisis escalations, and publish psychoeducation resources in compliance with RA 11036.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFE0F2FE),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Clinical Metrics Grid ──
            const Text(
              "Clinical Overview",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Active Students",
                    value: "$activeStudents / $totalStudents",
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF0284C7),
                    bg: const Color(0xFFE0F2FE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: "Crisis Alerts",
                    value: "$flagged",
                    icon: Icons.emergency_rounded,
                    color: flagged > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    bg: flagged > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Chat Sessions",
                    value: "$totalSessions",
                    icon: Icons.forum_rounded,
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFEDE9FE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: "Mood Logs",
                    value: "$totalMoods",
                    icon: Icons.mood_rounded,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Clinical Guidance Workflows ──
            const Text(
              "Guidance Workflows",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.health_and_safety_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBg: const Color(0xFFFEE2E2),
              title: "Crisis Triage & Risk Intercepts",
              subtitle: "Review flagged suicide/self-harm messages and initiate student outreach",
              badge: flagged > 0 ? "$flagged pending" : null,
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedTabIndex = 1);
              },
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.badge_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFE0F2FE),
              title: "Student Care Directory",
              subtitle: "View student mood histories, manage deactivations, and review appeals",
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedTabIndex = 2);
              },
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.auto_stories_rounded,
              iconColor: const Color(0xFF0D9488),
              iconBg: const Color(0xFFCCFBF1),
              title: "Psychoeducation CMS Suite",
              subtitle: "Author and publish evidence-based mental wellness articles for Urian students",
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedTabIndex = 3);
              },
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.verified_user_rounded,
              iconColor: const Color(0xFF6366F1),
              iconBg: const Color(0xFFEEF2FF),
              title: "Clinical Audit Trail",
              subtitle: "Review immutable logs of counselor actions for RA 11036 compliance",
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedTabIndex = 4);
              },
            ),

            const SizedBox(height: 24),

            // ── Emergency Hotline Reference ──
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
                  const Row(
                    children: [
                      Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        "FSUU Emergency Clinical Directory",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildHotlineRow("FSUU Guidance Center", "(085) 342-1830", "guidance@urios.edu.ph"),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildHotlineRow("National Center for Mental Health", "1553 / 0917-899-USAP", "ncmh.gov.ph"),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildHotlineRow("In Touch Community Services", "+63 917 800 1123", "crisisline@in-touch.org"),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            badge,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildHotlineRow(String title, String phone, String email) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
              Text(
                email,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Text(
          phone,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', _selectedTabIndex == 0, () {
            HapticService.lightTap();
            setState(() => _selectedTabIndex = 0);
          }),
          _buildNavItem(Icons.health_and_safety_rounded, 'Triage', _selectedTabIndex == 1, () {
            HapticService.lightTap();
            setState(() => _selectedTabIndex = 1);
          }),
          _buildNavItem(Icons.people_alt_rounded, 'Students', _selectedTabIndex == 2, () {
            HapticService.lightTap();
            setState(() => _selectedTabIndex = 2);
          }),
          _buildNavItem(Icons.auto_stories_rounded, 'Articles', _selectedTabIndex == 3, () {
            HapticService.lightTap();
            setState(() => _selectedTabIndex = 3);
          }),
          _buildNavItem(Icons.verified_user_rounded, 'Audit', _selectedTabIndex == 4, () {
            HapticService.lightTap();
            setState(() => _selectedTabIndex = 4);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
