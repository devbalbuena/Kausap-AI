import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../auth/login_screen.dart';
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
  bool _biometricsEnabled = false;
  String _autoLockTimeout = 'Immediately';

  @override
  void initState() {
    super.initState();
    _loadSecurityStates();
  }

  Future<void> _loadSecurityStates() async {
    final pinEnabled = await PinService.isEnabled();
    final bioEnabled = await PinService.isBiometricsEnabled();
    final timeout = await PinService.getAutoLockTimeout();
    if (mounted) {
      setState(() {
        _appLockEnabled = pinEnabled;
        _biometricsEnabled = bioEnabled;
        _autoLockTimeout = timeout;
      });
    }
  }

  Future<void> _selectAutoLockTimeout() async {
    final options = ['Immediately', '1 Minute', '5 Minutes', '15 Minutes'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Auto-Lock Timeout',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    'Lock the app automatically after inactivity to keep your journals confidential.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final isSelected = opt == _autoLockTimeout;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                    onTap: () => Navigator.pop(ctx, opt),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await PinService.setAutoLockTimeout(selected);
      setState(() => _autoLockTimeout = selected);
      HapticService.lightTap();
    }
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to deactivate your account? You will be logged out and your account will be suspended. Contact support to reactivate.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
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
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  slideRoute(const LoginScreen()),
                  (route) => false,
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to deactivate account. Please try again.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account Permanently', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone. All your mood history, journal reflections, and clinical screener assessments will be permanently erased.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
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
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  slideRoute(const LoginScreen()),
                  (route) => false,
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete account. Please try again.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int activeProtections = 1; // Strong Password
    if (_twoFactorEnabled) activeProtections++;
    if (_appLockEnabled) activeProtections++;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security & App Lock',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ── Security Health Status Banner ──────────────────────────────
              _buildSecurityStatusCard(activeProtections),
              const SizedBox(height: 20),

              // ── Account Security ───────────────────────────────────────────
              _sectionLabel('ACCOUNT CREDENTIALS'),
              const SizedBox(height: 8),
              _card([
                _buildNavRow(
                  icon: Icons.key_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Change Password',
                  subtitle: 'Update your account login password',
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const ChangePasswordScreen()));
                  },
                ),
                _divider(),
                _buildToggleRow(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Two-Factor Authentication (2FA)',
                  subtitle: _twoFactorEnabled ? 'Active — extra login layer' : 'Add an extra verification code on login',
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
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ── App Lock & Journal Protection ──────────────────────────────
              _sectionLabel('APP LOCK & JOURNAL PRIVACY'),
              const SizedBox(height: 8),
              _card([
                _buildToggleRow(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'App Lock (4-Digit PIN)',
                  subtitle: _appLockEnabled ? 'Active — PIN required on open' : 'Require 4-digit PIN to open app',
                  value: _appLockEnabled,
                  onChanged: (v) async {
                    HapticService.mediumTap();
                    if (v) {
                      final result = await Navigator.push<bool>(
                        context,
                        slideRoute(const AppLockSetupScreen(mode: AppLockMode.setup)),
                      );
                      if (mounted) setState(() => _appLockEnabled = result ?? false);
                    } else {
                      final verified = await Navigator.push<bool>(
                        context,
                        slideRoute(const AppLockSetupScreen(mode: AppLockMode.verify)),
                      );
                      if (verified == true) {
                        await PinService.disablePin();
                        if (mounted) setState(() => _appLockEnabled = false);
                      }
                    }
                  },
                ),
                if (_appLockEnabled) ...[
                  _divider(),
                  _buildNavRow(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFEA580C),
                    label: 'Auto-Lock Inactivity Timeout',
                    subtitle: 'Locks automatically: $_autoLockTimeout',
                    onTap: _selectAutoLockTimeout,
                  ),
                  _divider(),
                  _buildToggleRow(
                    icon: Icons.fingerprint_rounded,
                    iconColor: const Color(0xFFE11D48),
                    label: 'Biometric Unlock',
                    subtitle: 'Use Fingerprint / Face ID with PIN',
                    value: _biometricsEnabled,
                    onChanged: (v) async {
                      HapticService.mediumTap();
                      await PinService.setBiometrics(v);
                      if (mounted) setState(() => _biometricsEnabled = v);
                    },
                  ),
                  _divider(),
                  _buildNavRow(
                    icon: Icons.password_rounded,
                    iconColor: const Color(0xFF64748B),
                    label: 'Change App Lock PIN',
                    subtitle: 'Update your 4-digit security code',
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.push(
                        context,
                        slideRoute(const AppLockSetupScreen(mode: AppLockMode.change)),
                      );
                    },
                  ),
                ],
              ]),

              const SizedBox(height: 20),

              // ── Logged-in Devices ──────────────────────────────────────────
              _sectionLabel('AUTHORIZED DEVICES'),
              const SizedBox(height: 8),
              _card([
                _buildNavRow(
                  icon: Icons.devices_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Logged-in Devices',
                  subtitle: 'Manage active phones, tablets & browsers',
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const ActiveDevicesScreen()));
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ── Danger Zone / Account Suspension & Deletion ────────────────
              _sectionLabel('DANGER ZONE & ACCOUNT ACTIONS'),
              const SizedBox(height: 8),
              _card([
                _buildNavRow(
                  icon: Icons.person_off_outlined,
                  iconColor: const Color(0xFFEA580C),
                  label: 'Deactivate Account',
                  subtitle: 'Temporarily suspend your student profile',
                  onTap: () {
                    HapticService.heavyTap();
                    _showDeactivateDialog();
                  },
                ),
                _divider(),
                _buildNavRow(
                  icon: Icons.delete_forever_rounded,
                  iconColor: const Color(0xFFDC2626),
                  label: 'Delete Account Permanently',
                  subtitle: 'Irreversibly erase journals, screeners & profile',
                  onTap: () {
                    HapticService.heavyTap();
                    _showDeleteDialog();
                  },
                ),
              ]),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard(int activeCount) {
    final isMax = activeCount >= 3;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMax
              ? const [Color(0xFF15803D), Color(0xFF166534)]
              : const [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x180F172A), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isMax ? Icons.verified_user_rounded : Icons.shield_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMax ? 'Account Protection: Maximum' : 'Account Protection: Strong',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$activeCount of 3 Security Measures Active',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.7,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A))),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value == true,
            activeTrackColor: AppColors.primaryLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 64, color: Color(0x12000000));
  }
}
