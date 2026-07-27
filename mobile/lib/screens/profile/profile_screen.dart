import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_selection_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/security_screen.dart';
import '../settings/privacy_screen.dart';
import '../settings/about_screen.dart';
import '../../services/api_client.dart';
import '../mood/mood_analytics_screen.dart';
import 'edit_profile_screen.dart';

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
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
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
            child: const Text('Deactivate'),
          ),
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
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
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
            child: const Text('Delete'),
          ),
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
            // Title
            Text(
              'Profile',
              style: AppTextStyles.heading1.copyWith(
                fontSize: 24,
                letterSpacing: -0.64,
                color: const Color(0xFF3D405B),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Card (Blue)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
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
                  Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kausap AI',
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kausap.ai@gmail.com',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MY MENTAL HEALTH Section
            _buildSectionContainer(
              title: 'MY MENTAL HEALTH',
              children: [
                _buildListItem(
                  icon: Icons.show_chart_rounded,
                  title: 'Mood Trends',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodAnalyticsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.history_rounded,
                  title: 'Assessment History',
                  onTap: () {},
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.security_rounded,
                  title: 'Security',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SecurityScreen()),
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
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Kausap AI',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
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
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Logout',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 14,
                    letterSpacing: 0.14,
                    color: Colors.white,
                  ),
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

  Widget _buildListItem({required IconData icon, required String title, required VoidCallback onTap}) {
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
            const Icon(
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
