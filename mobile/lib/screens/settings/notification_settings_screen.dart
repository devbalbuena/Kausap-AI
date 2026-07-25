import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Permissions
  bool _pushNotifications = true;
  bool _microphoneAccess = false;
  bool _photoLibrary = true;
  bool _cameraAccess = false;

  // Preferences
  bool _sessionReminders = true;
  bool _newMessages = true;
  bool _weeklyProgress = false;

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
                          'Notifications',
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

                      // ── App Permissions ──────────────────────────────────
                      _buildSectionLabel('APP PERMISSIONS'),
                      _buildSettingsCard([
                        _buildToggleRow(
                          icon: Icons.notifications_outlined,
                          iconColor: const Color(0xFF6366F1),
                          label: 'Push Notifications',
                          subtitle: 'Receive alerts and reminders',
                          value: _pushNotifications,
                          onChanged: (v) => setState(() => _pushNotifications = v),
                        ),
                        _buildDivider(),
                        _buildToggleRow(
                          icon: Icons.mic_outlined,
                          iconColor: const Color(0xFF0077B6),
                          label: 'Microphone Access',
                          subtitle: 'Allow voice messages',
                          value: _microphoneAccess,
                          onChanged: (v) => setState(() => _microphoneAccess = v),
                        ),
                        _buildDivider(),
                        _buildToggleRow(
                          icon: Icons.photo_library_outlined,
                          iconColor: const Color(0xFF2E9E6B),
                          label: 'Photo Library',
                          subtitle: 'Access photos for sharing',
                          value: _photoLibrary,
                          onChanged: (v) => setState(() => _photoLibrary = v),
                        ),
                        _buildDivider(),
                        _buildToggleRow(
                          icon: Icons.camera_alt_outlined,
                          iconColor: const Color(0xFFE07B39),
                          label: 'Camera',
                          subtitle: 'Take photos during sessions',
                          value: _cameraAccess,
                          onChanged: (v) => setState(() => _cameraAccess = v),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Notification Preferences ─────────────────────────
                      _buildSectionLabel('PREFERENCES'),
                      _buildSettingsCard([
                        _buildToggleRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF9B5DE5),
                          label: 'Session Reminders',
                          subtitle: 'Get notified before sessions',
                          value: _sessionReminders,
                          onChanged: (v) => setState(() => _sessionReminders = v),
                        ),
                        _buildDivider(),
                        _buildToggleRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: const Color(0xFF0077B6),
                          label: 'New Messages',
                          subtitle: 'Direct messages from professionals',
                          value: _newMessages,
                          onChanged: (v) => setState(() => _newMessages = v),
                        ),
                        _buildDivider(),
                        _buildToggleRow(
                          icon: Icons.bar_chart_rounded,
                          iconColor: const Color(0xFF2E9E6B),
                          label: 'Weekly Progress',
                          subtitle: 'Your weekly mental wellness summary',
                          value: _weeklyProgress,
                          onChanged: (v) => setState(() => _weeklyProgress = v),
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.8,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0x18000000), margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}
