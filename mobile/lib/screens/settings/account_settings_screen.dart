import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../services/api_client.dart';
import '../auth/role_selection_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'two_factor_auth_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'help_faq_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Account Settings',
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final user = auth.currentUser ?? {};
                      final firstName = user['first_name'] ?? 'User';
                      final lastName = user['last_name'] ?? '';
                      final email = user['email'] ?? '';
                      final role = (user['role'] ?? 'client').toString().toUpperCase();
                      final avatarUrl = user['avatar_url'] as String?;
                      final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          // Profile Summary Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.primary.withAlpha(30),
                                  backgroundImage: (avatarUrl != null &&
                                          avatarUrl.isNotEmpty &&
                                          !avatarUrl.startsWith('data:'))
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null ||
                                          avatarUrl.isEmpty ||
                                          avatarUrl.startsWith('data:'))
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$firstName $lastName'.trim(),
                                        style: AppTextStyles.heading2.copyWith(fontSize: 17),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          role,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Personal Info Section
                          _buildSectionTitle('Personal Information'),
                          _buildCard([
                            _buildTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Edit Profile',
                              subtitle: 'Update name, avatar, and personal details',
                              onTap: () => Navigator.of(context).push(slideRoute(const EditProfileScreen())),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // Security & Login Section
                          _buildSectionTitle('Security & Authentication'),
                          _buildCard([
                            _buildTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Change Password',
                              subtitle: 'Update your account password',
                              onTap: () => Navigator.of(context).push(slideRoute(const ChangePasswordScreen())),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildTile(
                              icon: Icons.security_rounded,
                              title: 'Two-Factor Authentication',
                              subtitle: 'Add an extra layer of security',
                              onTap: () => Navigator.of(context).push(slideRoute(const TwoFactorAuthScreen())),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // Preferences Section
                          _buildSectionTitle('Preferences & Privacy'),
                          _buildCard([
                            _buildTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notification Settings',
                              subtitle: 'Manage push and session reminders',
                              onTap: () => Navigator.of(context).push(slideRoute(const NotificationSettingsScreen())),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy & Data Protection',
                              subtitle: 'Control data sharing and visibility',
                              onTap: () => Navigator.of(context).push(slideRoute(const PrivacyScreen())),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & FAQ',
                              subtitle: 'Learn more about Kausap AI',
                              onTap: () => Navigator.of(context).push(slideRoute(const HelpFaqScreen())),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // Danger Zone Section
                          _buildSectionTitle('Account Management', isDanger: true),
                          _buildCard([
                            _buildTile(
                              icon: Icons.pause_circle_outline_rounded,
                              title: 'Deactivate Account',
                              subtitle: 'Temporarily disable your account',
                              iconColor: AppColors.error,
                              titleColor: AppColors.error,
                              onTap: () => _showDeactivateDialog(context),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildTile(
                              icon: Icons.delete_forever_rounded,
                              title: 'Delete Account Permanently',
                              subtitle: 'Erase all personal data and conversation history',
                              iconColor: AppColors.error,
                              titleColor: AppColors.error,
                              onTap: () => _showDeleteDialog(context),
                            ),
                          ]),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDanger ? AppColors.error : AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    Color titleColor = const Color(0xFF191C21),
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
