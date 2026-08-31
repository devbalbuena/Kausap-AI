import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../widgets/cached_avatar.dart';
import '../auth/login_screen.dart';
import '../settings/help_faq_screen.dart';
import '../settings/accessibility_settings_screen.dart';
import '../settings/appearance_settings_screen.dart';
import '../settings/language_settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/security_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/about_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'admin_telemetry_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  int _totalStudents = 2;
  int _totalCounselors = 1;
  bool _neonHealthy = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminStats();
  }

  Future<void> _fetchAdminStats() async {
    try {
      final usersData = await ApiClient().get(ApiConfig.adminUsers, silent: true);
      if (usersData is List) {
        final students = usersData.where((u) {
          final role = (u['role'] ?? 'client').toString().toLowerCase();
          return role == 'client' || role == 'student';
        }).length;
        final counselors = usersData.where((u) {
          final role = (u['role'] ?? '').toString().toLowerCase();
          return role == 'counselor';
        }).length;
        if (mounted) {
          setState(() {
            _totalStudents = students;
            _totalCounselors = counselors > 0 ? counselors : 1;
          });
        }
      }
    } catch (_) {}
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
          'Are you sure you want to sign out of the Administrator Control Center? Active system guardrails and student privacy shields remain securely active in the cloud.',
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
    final firstName = user?['first_name'] ?? 'Super';
    final lastName = user?['last_name'] ?? 'Admin';
    final fullName = "$firstName $lastName".trim().isEmpty ? 'Administrator' : "$firstName $lastName".trim();
    final email = user?['email'] ?? 'admin@urios.edu.ph';
    final deptTitle = user?['department_title'] ?? 'FSUU Super Admin • IT Oversight';
    final avatarUrl = user?['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Administrator Profile',
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
              // ── 1. Hero Administrator Profile Card ─────────────────────────
              _buildHeroAdminCard(
                fullName: fullName,
                email: email,
                deptTitle: deptTitle,
                avatarUrl: avatarUrl,
              ),
              const SizedBox(height: 20),

              // ── 2. System & Security Controls ──────────────────────────────
              _buildSectionContainer(
                title: 'SYSTEM & SECURITY CONTROLS',
                children: [
                  _buildListItem(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Security & App PIN Lock',
                    subtitle: 'Biometrics, passkey, & session control',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const SecurityScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title: 'System Alerts & Telemetry Notifications',
                    subtitle: 'Crisis flags & server incident chimes',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const NotificationSettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.palette_outlined,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Appearance & Console Theme',
                    subtitle: 'Dark, light, & high contrast modes',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AppearanceSettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFFF97316),
                    title: 'Language & Regional Localization',
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
                    title: 'Accessibility & Display Comfort',
                    subtitle: 'Text size scaling & motion preferences',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AccessibilitySettingsScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 3. Institutional Governance & Cloud Infrastructure ─────────
              _buildSectionContainer(
                title: 'GOVERNANCE & CLOUD INFRASTRUCTURE',
                children: [
                  _buildListItem(
                    icon: Icons.insights_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Neon Serverless DB & AI Telemetry',
                    subtitle: 'Compute hours, pool health, & token meters',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AdminTelemetryScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.gavel_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Institutional Compliance & Privacy',
                    subtitle: 'Data Privacy Act (RA 10173) audit logs',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const PrivacyScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Admin Operations Manual (FAQ)',
                    subtitle: 'User provisioning, crisis moderation SOP',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const HelpFaqScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF475569),
                    title: 'About Kausap AI Platform',
                    subtitle: 'FSUU Guidance Center • Version 1.0.0',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AboutScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 4. Sign Out Button ─────────────────────────────────────────
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Sign Out of Admin Console',
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

  // ── Hero Admin Card Widget ─────────────────────────────────────────────────
  Widget _buildHeroAdminCard({
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
                          const Icon(Icons.admin_panel_settings_rounded, size: 12, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              deptTitle,
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

          // ── Quick Telemetry Row ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStatItem(
                emoji: '👥',
                value: '$_totalStudents',
                label: 'Students',
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              _buildQuickStatItem(
                emoji: '👩‍💼',
                value: '$_totalCounselors',
                label: 'Counselors',
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              _buildQuickStatItem(
                emoji: '⚡',
                value: _neonHealthy ? 'Healthy' : 'Syncing',
                label: 'Neon DB',
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
                'Edit Administrator Credentials',
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
                fontSize: 13.5,
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

  // ── List Item ──────────────────────────────────────────────────────────────
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
