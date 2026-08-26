import 'package:flutter/material.dart';
import '../../utils/app_routes.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
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
import '../insights/student_insights_screen.dart';
import '../crisis/crisis_resources_sheet.dart';
import 'edit_profile_screen.dart';
import 'achievements_screen.dart';
import 'assessment_history_screen.dart';
import '../../widgets/cached_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showCrisisModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CrisisResourcesSheet(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to log out? Your journal entries, mood logs, and clinical assessments remain safe and encrypted.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final fullName = user?['full_name'] ?? 'User';
    final email = user?['email'] ?? '';
    final role = user?['role'] ?? 'Student';
    final avatarUrl = user?['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTextStyles.heading1.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                slideRoute(const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // User Details Row
          Row(
            children: [
              Stack(
                children: [
                  CachedAvatar(
                    imageUrl: avatarUrl,
                    fallbackInitial: fullName,
                    radius: 36,
                  ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRoute(const EditProfileScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.toString().toLowerCase() == 'counselor'
                              ? 'Guidance Counselor'
                              : (role.toString().toLowerCase() == 'admin' ? 'Super Admin' : 'Student'),
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QUICK ACCESS (Achievements & Screeners)
            _buildSectionContainer(
              title: 'MY WELLNESS JOURNEY',
              children: [
                _buildListItem(
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements & Milestones',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const AchievementsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.assessment_rounded,
                  title: 'Assessment History (PHQ-9 & GAD-7)',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const AssessmentHistoryScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // WELLNESS & INSIGHTS Section
            _buildSectionContainer(
              title: 'WELLNESS & INSIGHTS',
              children: [
                const MoodTrendsChart(),
                const SizedBox(height: 12),
                _buildListItem(
                  icon: Icons.insights_rounded,
                  title: 'My Mental Health Insights',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const StudentInsightsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SETTINGS Section
            _buildSectionContainer(
              title: 'SETTINGS & CONTROLS',
              children: [
                _buildListItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const NotificationSettingsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Controls & Shield',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const PrivacyCenterScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.gavel_rounded,
                  title: 'Terms & Legal Policies',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const PrivacyScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.security_rounded,
                  title: 'Security & App Lock',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const SecurityScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accessibility & Comfort',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const AccessibilitySettingsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance & Theme',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const AppearanceSettingsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.language_rounded,
                  title: 'Language & Region',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const LanguageSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SUPPORT Section
            _buildSectionContainer(
              title: 'SUPPORT & EMERGENCY',
              children: [
                _buildListItem(
                  icon: Icons.healing_rounded,
                  title: 'Crisis Resources (24/7 Hotlines)',
                  onTap: () => _showCrisisModal(context),
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Frequently Asked Questions (FAQ)',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const HelpFaqScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Kausap AI',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Clean & Safe Logout Button
            SizedBox(
              height: 50,
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
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.7,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF475569)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 40, color: Color(0x12000000));
  }
}
