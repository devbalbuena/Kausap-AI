import 'package:flutter/material.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import 'change_password_screen.dart';
import 'active_devices_screen.dart';
import 'two_factor_auth_screen.dart';
import 'app_lock_setup_screen.dart';
import '../../services/pin_service.dart';
import '../../utils/haptic_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = false;
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final enabled = await PinService.isEnabled();
    if (mounted) setState(() => _appLockEnabled = enabled);
  }


  void _showDataExportDialog() {
    bool exportChats = true;
    bool exportMood = true;
    bool isRequesting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Export Your Data',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the data you would like to download. A secure link will be sent to your email address.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Chat History', style: TextStyle(fontSize: 14)),
                    value: exportChats,
                    onChanged: (v) => setDialogState(() => exportChats = v ?? true),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Mood Analytics', style: TextStyle(fontSize: 14)),
                    value: exportMood,
                    onChanged: (v) => setDialogState(() => exportMood = v ?? true),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isRequesting
                      ? null
                      : () async {
                          if (!exportChats && !exportMood) return;
                          setDialogState(() => isRequesting = true);
                          // Simulating an API call
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Your data request has been received! The link will be emailed shortly.')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isRequesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Request Data'),
                ),
              ],
            );
          },
        );
      },
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
                          onTap: () {
                            HapticService.lightTap();
                            Navigator.push(context, slideRoute(const ChangePasswordScreen()));
                          }
                        ),
                        _divider(),
                        _buildToggleRow(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFF2E9E6B),
                          label: 'Two-Factor Authentication',
                          subtitle: _twoFactorEnabled ? 'Enabled — tap to manage' : 'Add an extra layer of security',
                          value: _twoFactorEnabled,
                          onChanged: (v) async {
                            if (v) {
                              final result = await Navigator.push<bool>(
                                context,
                                slideRoute(const TwoFactorAuthScreen()),
                              );
                              if (mounted) setState(() => _twoFactorEnabled = result ?? false);
                            } else {
                              setState(() => _twoFactorEnabled = false);
                            }
                          })
                      ]),

                      const SizedBox(height: 20),

                      // ── Device Privacy ───────────────────────────────────
                      _sectionLabel('DEVICE PRIVACY'),
                      _card([
                        _buildToggleRow(
                          icon: Icons.fingerprint_rounded,
                          iconColor: const Color(0xFFE11D48),
                          label: 'App Lock (PIN)',
                          subtitle: _appLockEnabled ? 'Enabled — tap to manage PIN' : 'Require PIN to open app',
                          value: _appLockEnabled,
                          onChanged: (v) async {
                            HapticService.mediumTap();
                            if (v) {
                              // Open setup screen
                              final result = await Navigator.push<bool>(
                                context,
                                slideRoute(const AppLockSetupScreen(mode: AppLockMode.setup)),
                              );
                              if (mounted) setState(() => _appLockEnabled = result ?? false);
                            } else {
                              // Verify current PIN before disabling
                              final verified = await Navigator.push<bool>(
                                context,
                                slideRoute(const AppLockSetupScreen(mode: AppLockMode.verify)),
                              );
                              if (verified == true) {
                                await PinService.disablePin();
                                if (mounted) setState(() => _appLockEnabled = false);
                              }
                            }
                          })
                        _divider(),
                        _buildNavRow(
                          icon: Icons.download_rounded,
                          iconColor: const Color(0xFF0EA5E9),
                          label: 'Export Data',
                          subtitle: 'Request a copy of your personal data',
                          onTap: () {
                            HapticService.lightTap();
                            _showDataExportDialog();
                          },
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
                            HapticService.lightTap();
                            Navigator.push(context, slideRoute(const ActiveDevicesScreen()));
                          }
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

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: (v) {
              HapticService.mediumTap();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0x18000000), margin: const EdgeInsets.symmetric(horizontal: 16));
}
