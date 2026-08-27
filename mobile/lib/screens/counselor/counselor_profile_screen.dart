import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../services/articles_storage_service.dart';
import '../../widgets/cached_avatar.dart';
import '../auth/login_screen.dart';
import '../settings/help_faq_screen.dart';
import '../settings/accessibility_settings_screen.dart';
import '../settings/appearance_settings_screen.dart';
import '../settings/language_settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/security_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/privacy_center_screen.dart';
import '../settings/about_screen.dart';
import '../crisis/crisis_resources_sheet.dart';
import '../profile/edit_profile_screen.dart';

class CounselorProfileScreen extends StatefulWidget {
  const CounselorProfileScreen({super.key});

  @override
  State<CounselorProfileScreen> createState() => _CounselorProfileScreenState();
}

class _CounselorProfileScreenState extends State<CounselorProfileScreen> {
  int _activeStudents = 3;
  int _resolvedAlerts = 0;
  int _publishedArticles = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounselorStats();
  }

  Future<void> _fetchCounselorStats() async {
    try {
      // 1. Fetch active students count
      try {
        final usersData = await ApiClient().get(ApiConfig.adminUsers, silent: true);
        if (usersData is List) {
          final students = usersData.where((u) {
            final role = (u['role'] ?? 'client').toString().toLowerCase();
            return role == 'client' || role == 'student';
          }).toList();
          if (mounted) setState(() => _activeStudents = students.length);
        }
      } catch (_) {}

      // 2. Fetch resolved triage alerts count
      try {
        final alerts = await ApiClient().get(ApiConfig.adminFlaggedMessages, silent: true);
        if (alerts is List) {
          final resolved = alerts.where((a) => a['is_resolved'] == true).length;
          if (mounted) setState(() => _resolvedAlerts = resolved);
        }
      } catch (_) {}

      // 3. Fetch published articles count
      try {
        final articles = await ArticlesStorageService.loadAllArticlesWithEngagement();
        if (mounted) setState(() => _publishedArticles = articles.length);
      } catch (_) {}
    } catch (_) {}
  }

  void _showCrisisModal(BuildContext context) {
    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CrisisResourcesSheet(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    HapticService.lightTap();
    final nav = Navigator.of(context);
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of the Counselor Guidance Hub? Student care records and crisis flags remain securely encrypted.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticService.heavyTap();
              await auth.logout();
              nav.pushAndRemoveUntil(
                slideRoute(const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final firstName = user?['first_name'] ?? 'Counselor';
    final lastName = user?['last_name'] ?? '';
    final fullName = "$firstName $lastName".trim().isEmpty ? 'Guidance Counselor' : "$firstName $lastName".trim();
    final email = user?['email'] ?? 'counselor@urios.edu.ph';
    final deptTitle = user?['department_title'] ?? 'Guidance Counselor III';
    final avatarUrl = user?['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Counselor Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // ── 1. Hero Counselor Profile Card ─────────────────────────────
              _buildHeroCounselorCard(
                fullName: fullName,
                email: email,
                deptTitle: deptTitle,
                avatarUrl: avatarUrl,
              ),
              const SizedBox(height: 20),

              // ── 2. Clinical Care & Campus Protocols ────────────────────────
              _buildSectionContainer(
                title: 'CLINICAL CARE & PROTOCOLS',
                children: [
                  _buildListItem(
                    icon: Icons.health_and_safety_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Crisis Triage & Risk Protocols',
                    subtitle: 'Real-time AI distress alerts & student escalations',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.pop(context);
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Student Care Directory',
                    subtitle: 'Emotional mood history & account management',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.pop(context);
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.verified_user_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'RA 11036 Clinical Audit Trail',
                    subtitle: 'Immutable compliance logging of triage actions',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.pop(context);
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.auto_stories_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Psychoeducation CMS Articles',
                    subtitle: 'Publish mental health resources for Urians',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 3. Counselor Settings & Controls ───────────────────────────
              _buildSectionContainer(
                title: 'SETTINGS & CONTROLS',
                children: [
                  _buildListItem(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Triage Alerts & Notifications',
                    subtitle: 'Sound chimes & urgent escalation alerts',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const NotificationSettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'Confidentiality & Privacy Shield',
                    subtitle: 'Data protection & ethical boundaries',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const PrivacyCenterScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Security & App PIN Lock',
                    subtitle: 'Biometrics & passkey protection',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const SecurityScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.palette_outlined,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Appearance & Theme',
                    subtitle: 'High contrast & color schemes',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AppearanceSettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFFF97316),
                    title: 'Language & Region',
                    subtitle: 'English, Cebuano (Bisaya), Tagalog',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const LanguageSettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.accessibility_new_rounded,
                    iconColor: const Color(0xFF14B8A6),
                    title: 'Accessibility & Comfort',
                    subtitle: 'Text size & accessibility tools',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AccessibilitySettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.gavel_rounded,
                    iconColor: const Color(0xFF64748B),
                    title: 'Campus Ethical Policies & RA 11036',
                    subtitle: 'Philippine Mental Health Law compliance',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const PrivacyScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 4. Campus Emergency & Support ──────────────────────────────
              _buildSectionContainer(
                title: 'CAMPUS SUPPORT & DIRECTORY',
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: _buildListItem(
                      icon: Icons.health_and_safety_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'FSUU Crisis Hotlines & Clinic Directory',
                      subtitle: 'Guidance center, clinic, & 911 lines',
                      onTap: () => _showCrisisModal(context),
                    ),
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Counselor Guidelines & Manual (FAQ)',
                    subtitle: 'Procedures for managing student risk alerts',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const HelpFaqScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF475569),
                    title: 'About Kausap AI Portal',
                    subtitle: 'FSUU Guidance Center • Version 1.0.0',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AboutScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 5. Sign Out Button ─────────────────────────────────────────
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Sign Out of Guidance Hub',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Counselor Card Widget ─────────────────────────────────────────────
  Widget _buildHeroCounselorCard({
    required String fullName,
    required String email,
    required String deptTitle,
    required String avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with camera badge
              Stack(
                children: [
                  CachedAvatar(
                    imageUrl: avatarUrl,
                    fallbackInitial: fullName,
                    radius: 34,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        HapticService.lightTap();
                        Navigator.push(context, slideRoute(const EditProfileScreen())).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Name, Email, Department
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$deptTitle • FSUU',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // ── Quick Stats Row ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStatItem(
                emoji: '👥',
                value: '$_activeStudents',
                label: 'Students',
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              _buildQuickStatItem(
                emoji: '🚨',
                value: '$_resolvedAlerts',
                label: 'Resolved',
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              _buildQuickStatItem(
                emoji: '📚',
                value: '$_publishedArticles',
                label: 'Articles',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Edit Profile Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.lightTap();
                Navigator.push(context, slideRoute(const EditProfileScreen())).then((_) {
                  if (mounted) setState(() {});
                });
              },
              icon: const Icon(Icons.edit_note_rounded, size: 17, color: Color(0xFF0284C7)),
              label: const Text(
                'Edit Counselor Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                backgroundColor: const Color(0xFFF0F9FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({required String emoji, required String value, required String label}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ── Section Container ──────────────────────────────────────────────────────
  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8, left: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ── Modern Colored Icon List Item ──────────────────────────────────────────
  Widget _buildListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9));
  }
}
