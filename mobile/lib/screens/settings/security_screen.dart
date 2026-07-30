import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = false;
  bool _appLockEnabled = false;
  final ApiClient _apiClient = ApiClient();

  void _showChangePasswordDialog() {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool oldVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;
    bool isSaving = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildPasswordField('Current Password', oldPasswordCtrl, oldVisible,
                      () => setDialogState(() => oldVisible = !oldVisible)),
                  const SizedBox(height: 12),
                  _buildPasswordField('New Password', newPasswordCtrl, newVisible,
                      () => setDialogState(() => newVisible = !newVisible)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Confirm New Password', confirmPasswordCtrl, confirmVisible,
                      () => setDialogState(() => confirmVisible = !confirmVisible)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final oldPwd = oldPasswordCtrl.text.trim();
                          final newPwd = newPasswordCtrl.text.trim();
                          final confirmPwd = confirmPasswordCtrl.text.trim();

                          if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                            setDialogState(() => error = 'All fields are required.');
                            return;
                          }
                          if (newPwd != confirmPwd) {
                            setDialogState(() => error = 'New passwords do not match.');
                            return;
                          }
                          if (newPwd.length < 8) {
                            setDialogState(() => error = 'Password must be at least 8 characters.');
                            return;
                          }

                          setDialogState(() { isSaving = true; error = null; });
                          try {
                            await _apiClient.put(ApiConfig.changePassword, body: {
                              'old_password': oldPwd,
                              'new_password': newPwd,
                            });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password changed successfully!'),
                                  backgroundColor: Color(0xFF2E9E6B),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              error = e.toString().replaceAll('ApiException: 400 - ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController ctrl, bool visible, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Security',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 8),

                      // ── Account Security ─────────────────────────────────
                      _sectionLabel('ACCOUNT SECURITY'),
                      _card([
                        _buildNavRow(
                          icon: Icons.key_rounded,
                          iconColor: const Color(0xFF6366F1),
                          label: 'Change Password',
                          subtitle: 'Update your login password',
                          onTap: _showChangePasswordDialog,
                        ),
                        _divider(),
                        _buildToggleRow(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFF2E9E6B),
                          label: 'Two-Factor Authentication',
                          subtitle: 'Add an extra layer of security',
                          value: _twoFactorEnabled,
                          onChanged: (v) => setState(() => _twoFactorEnabled = v),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Device Privacy ───────────────────────────────────
                      _sectionLabel('DEVICE PRIVACY'),
                      _card([
                        _buildToggleRow(
                          icon: Icons.fingerprint_rounded,
                          iconColor: const Color(0xFFE11D48),
                          label: 'App Lock / Biometrics',
                          subtitle: 'Require FaceID/PIN to open app',
                          value: _appLockEnabled,
                          onChanged: (v) => setState(() => _appLockEnabled = v),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Devices ──────────────────────────────────────────
                      _sectionLabel('DEVICES'),
                      _card([
                        _buildNavRow(
                          icon: Icons.smartphone_rounded,
                          iconColor: const Color(0xFF0077B6),
                          label: 'Active Sessions',
                          subtitle: 'Manage logged-in devices',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          )),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavRow({required IconData icon, required Color iconColor, required String label, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({required IconData icon, required Color iconColor, required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0x18000000), margin: const EdgeInsets.symmetric(horizontal: 16));
}
