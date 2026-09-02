import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../services/offline_mood_queue.dart';
import '../auth/login_screen.dart';
import '../settings/help_faq_screen.dart';
import '../settings/accessibility_settings_screen.dart';
import '../settings/appearance_settings_screen.dart';
import '../settings/language_settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/security_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/privacy_center_screen.dart';
import '../../widgets/mood_trends_chart.dart';
import '../settings/about_screen.dart';
import '../crisis/crisis_resources_sheet.dart';
import 'edit_profile_screen.dart';
import 'achievements_screen.dart';
import 'assessment_history_screen.dart';
import '../../widgets/cached_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _streak = 0;
  int _totalMoodLogs = 0;
  int _screenersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  DateTime? _parseDateLocal(dynamic created) {
    if (created == null) return null;
    try {
      final str = created.toString();
      final dt = DateTime.parse(str);
      return dt.isUtc ? dt.toLocal() : (str.endsWith('Z') || str.contains('+') ? dt.toLocal() : DateTime.parse('${str}Z').toLocal());
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchUserStats() async {
    // 1. Fetch Streak & Total Mood Logs from /mood
    try {
      final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
      if (moodData is List) {
        final Set<String> daysWithMood = {};
        for (final entry in moodData) {
          final dt = _parseDateLocal(entry['created_at']);
          if (dt != null) {
            daysWithMood.add(DateFormat('yyyy-MM-dd').format(dt));
          }
        }

        // Check today's offline mood if any
        final offlineMood = await OfflineMoodQueue().getTodayOfflineMood();
        if (offlineMood != null) {
          daysWithMood.add(DateFormat('yyyy-MM-dd').format(DateTime.now()));
        }

        int streak = 0;
        final today = DateTime.now();
        for (int i = 0; i < 365; i++) {
          final checkDay = today.subtract(Duration(days: i));
          final dayStr = DateFormat('yyyy-MM-dd').format(checkDay);
          if (daysWithMood.contains(dayStr)) {
            streak++;
          } else {
            break;
          }
        }

        if (mounted) {
          setState(() {
            _streak = streak;
            _totalMoodLogs = moodData.length + (offlineMood != null && moodData.isEmpty ? 1 : 0);
          });
        }
      }
    } catch (_) {}

    // 2. Fetch Screeners Count from 'assessment_history' in FlutterSecureStorage
    try {
      const storage = FlutterSecureStorage();
      final assessRaw = await storage.read(key: 'assessment_history');
      if (assessRaw != null) {
        final dynamic decoded = jsonDecode(assessRaw);
        if (decoded is List && mounted) {
          setState(() => _screenersCount = decoded.length);
        }
      } else if (mounted) {
        setState(() => _screenersCount = 0);
      }
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Log Out',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to log out? Your journal entries, mood logs, and clinical assessments remain safe and encrypted.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
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
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final firstName = user?['first_name']?.toString() ?? '';
    final lastName = user?['last_name']?.toString() ?? '';
    final composedName = '$firstName $lastName'.trim();
    final fullNameRaw = user?['full_name']?.toString() ?? '';
    final displayName = composedName.isNotEmpty
        ? composedName
        : (fullNameRaw.isNotEmpty ? fullNameRaw : 'Student');
    final email = user?['email'] ?? '';
    final role = user?['role'] ?? 'Student';
    final avatarUrl = user?['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // ── 1. Hero Profile Card with Quick Stats ──────────────────────
              _buildHeroProfileCard(
                fullName: displayName,
                email: email,
                role: role,
                avatarUrl: avatarUrl,
              ),
              const SizedBox(height: 20),

              // ── 2. My Wellness Journey ─────────────────────────────────────
              _buildSectionContainer(
                title: 'MY WELLNESS JOURNEY',
                children: [
                  _buildListItem(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Achievements & Milestones',
                    subtitle: 'Badges, streak levels & wellness milestones',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AchievementsScreen())).then((_) {
                        if (mounted) _fetchUserStats();
                      });
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Self-Assessments & Screeners',
                    subtitle: 'PHQ-9, GAD-7 & campus burnout records',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AssessmentHistoryScreen())).then((_) {
                        if (mounted) _fetchUserStats();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 3. Wellness & Mood Trends Chart ───────────────────────────
              _buildSectionContainer(
                title: 'WEEKLY MOOD OVERVIEW',
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: MoodTrendsChart(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 4. Settings & Controls ─────────────────────────────────────
              _buildSectionContainer(
                title: 'SETTINGS & CONTROLS',
                children: [
                  _buildListItem(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Notifications & Reminders',
                    subtitle: 'Quiet hours & daily check-in nudges',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const NotificationSettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'Privacy Controls & Shield',
                    subtitle: 'Confidentiality & quick escape settings',
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
                    subtitle: 'Color schemes & dark mode',
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
                    subtitle: 'Text size & high contrast modes',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AccessibilitySettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.gavel_rounded,
                    iconColor: const Color(0xFF64748B),
                    title: 'Terms & Legal Policies',
                    subtitle: 'Student privacy & campus ethical policies',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const PrivacyScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 5. Support & Emergency ─────────────────────────────────────
              _buildSectionContainer(
                title: 'CAMPUS SUPPORT & EMERGENCY',
                children: [
                  // Highlighted Crisis Hotlines row
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
                      title: '24/7 Crisis Resources & Hotlines',
                      subtitle: 'FSUU Guidance Office & emergency lines',
                      onTap: () => _showCrisisModal(context),
                    ),
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Frequently Asked Questions (FAQ)',
                    subtitle: 'How Kausap AI helps your mental health',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const HelpFaqScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF475569),
                    title: 'About Kausap AI',
                    subtitle: 'FSUU Campus Wellness Shield • v1.0.0',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(context, slideRoute(const AboutScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 6. Log Out Button ──────────────────────────────────────────
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Log Out',
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

  // ── Hero Profile Card Widget ───────────────────────────────────────────────
  Widget _buildHeroProfileCard({
    required String fullName,
    required String email,
    required String role,
    required String avatarUrl,
  }) {
    final roleLabel = role.toString().toLowerCase() == 'counselor'
        ? 'Guidance Counselor'
        : (role.toString().toLowerCase() == 'admin' ? 'Super Admin' : 'Student');

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
              // Avatar with camera/edit badge
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
                          color: AppColors.primary,
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
              // Name, Email, Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '$roleLabel • FSUU',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
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
                emoji: '🔥',
                value: '$_streak Day',
                label: 'Streak',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.push(context, slideRoute(const AchievementsScreen())).then((_) {
                    if (mounted) _fetchUserStats();
                  });
                },
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              _buildQuickStatItem(
                emoji: '🌿',
                value: '$_totalMoodLogs',
                label: 'Check-ins',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.push(context, slideRoute(const AchievementsScreen())).then((_) {
                    if (mounted) _fetchUserStats();
                  });
                },
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
              _buildQuickStatItem(
                emoji: '📋',
                value: '$_screenersCount',
                label: 'Screeners',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.push(context, slideRoute(const AssessmentHistoryScreen())).then((_) {
                    if (mounted) _fetchUserStats();
                  });
                },
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
                  if (mounted) {
                    setState(() {});
                    _fetchUserStats();
                  }
                });
              },
              icon: const Icon(Icons.edit_note_rounded, size: 17, color: AppColors.primary),
              label: const Text(
                'Edit Profile Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withAlpha(90)),
                backgroundColor: AppColors.primary.withAlpha(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String emoji,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
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
        ),
      ),
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
