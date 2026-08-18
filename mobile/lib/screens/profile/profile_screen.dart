import 'package:flutter/material.dart';
import '../../utils/app_routes.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/role_selection_screen.dart';
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
import '../../services/api_client.dart';
import '../mood/mood_analytics_screen.dart';
import 'edit_profile_screen.dart';
import 'achievements_screen.dart';
import 'assessment_history_screen.dart';
import '../../widgets/cached_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to deactivate your account? You will be logged out and your account will be suspended. Contact support to reactivate.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final authProvider = context.read<AuthProvider>();
                final userId = authProvider.currentUser?['id'];
                if (userId != null) {
                  await ApiClient().patch('/admin/users/$userId/status', body: {'is_active': false});
                }
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    slideRoute(const RoleSelectionScreen()),
                    (route) => false,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to deactivate account. Please try again.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Deactivate'))
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone. All your data will be erased.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final authProvider = context.read<AuthProvider>();
                final userId = authProvider.currentUser?['id'];
                if (userId != null) {
                  await ApiClient().delete('/admin/users/$userId');
                }
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    slideRoute(const RoleSelectionScreen()),
                    (route) => false,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete account. Please try again.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // Title row with optional back button
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: const Color(0xFF3D405B),
                  ),
                if (Navigator.of(context).canPop())
                  const SizedBox(width: 8),
                Text(
                  'Profile',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 24,
                    letterSpacing: -0.64,
                    color: const Color(0xFF3D405B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser ?? {};
                final firstName = user['first_name'] ?? 'User';
                final lastName = user['last_name'] ?? '';
                final email = user['email'] ?? '';
                final avatarUrl = user['avatar_url'] as String?;
                
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(slideRoute(const EditProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140078D4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CachedAvatar(
                          imageUrl: avatarUrl,
                          radius: 28.5,
                          fallbackInitial: firstName,
                          backgroundColor: Colors.white.withAlpha(40),
                          foregroundColor: Colors.white,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$firstName $lastName'.trim(),
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),

            // ACHIEVEMENTS Section
            _buildSectionContainer(
              title: 'PROGRESS & ACHIEVEMENTS',
              children: [
                _buildListItem(
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements & Badges',
                  onTap: () {
                    Navigator.push(context, slideRoute(const AchievementsScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // MY MENTAL HEALTH Section
            _buildSectionContainer(
              title: 'MY MENTAL HEALTH',
              children: [
                const MoodTrendsChart(),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.show_chart_rounded,
                  title: 'Detailed Mood Analytics',
                  onTap: () {
                    Navigator.push(context, slideRoute(const MoodAnalyticsScreen()),
                    );
                  }),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.history_rounded,
                  title: 'Assessment History',
                  onTap: () {
                    Navigator.push(context, slideRoute(const AssessmentHistoryScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SETTINGS Section
            _buildSectionContainer(
              title: 'SETTINGS',
              children: [
                _buildListItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.push(context, slideRoute(const EditProfileScreen()),
                    );
                  }),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.push(context, slideRoute(const NotificationSettingsScreen()),
                    );
                  }),
                _buildDivider(),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildListItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      onTap: () => themeProvider.toggleTheme(),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (val) => themeProvider.toggleTheme(),
                        activeTrackColor: AppColors.primaryLight,
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy',
                  onTap: () {
                    Navigator.push(context, slideRoute(const PrivacyScreen()),
                    );
                  }),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Center',
                  onTap: () {
                    Navigator.push(context, slideRoute(const PrivacyCenterScreen()),
                    );
                  }),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.security_rounded,
                  title: 'Security',
                  onTap: () {
                    Navigator.push(context, slideRoute(const SecurityScreen()));
                  }),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.text_fields_rounded,
                  title: 'Accessibility',
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRoute(const AccessibilitySettingsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.color_lens_outlined,
                  title: 'Appearance',
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
              title: 'SUPPORT',
              children: [
                _buildListItem(
                  icon: Icons.healing_rounded, // or med_services
                  title: 'Crisis Resources',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.help_outline_rounded,
                  title: 'FAQ',
                  onTap: () {
                    Navigator.push(context, slideRoute(const HelpFaqScreen()),
                    );
                  }),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Kausap AI',
                  onTap: () {
                    Navigator.push(context, slideRoute(const AboutScreen()),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    slideRoute(const RoleSelectionScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Logout',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 14,
                    letterSpacing: 0.14,
                    color: Colors.white)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5858),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Deactivate Account Button
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showDeactivateDialog(context),
                icon: const Icon(Icons.person_off_rounded, size: 18, color: AppColors.error),
                label: const Text(
                  'Deactivate Account',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Delete Account Button
            SizedBox(
              height: 52,
              child: TextButton.icon(
                onPressed: () => _showDeleteDialog(context),
                icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFDC2626)),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFDC2626)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140078D4),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                fontFamily: 'Urbanist',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF707974),
                letterSpacing: 0.4,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem({required IconData icon, required String title, required VoidCallback onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F2FB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: const Color(0xFF3D405B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3D405B),
                ),
              ),
            ),
            if (trailing != null) trailing else const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFC0C9C2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        color: Color(0x4DC0C9C2), // rgba(192,201,194,0.3)
        height: 1,
        thickness: 1,
      ),
    );
  }
}
