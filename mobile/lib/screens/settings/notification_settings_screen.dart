import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_prefs_service.dart';
import '../../utils/haptic_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Permissions (persisted)
  bool _microphoneAccess = false;
  bool _photoLibrary = true;
  bool _cameraAccess = false;

  // Preferences (persisted)
  bool _pushNotifications = true;
  bool _sessionReminders = true;
  bool _newMessages = true;
  bool _dailyCheckins = true;
  String _dailyCheckinsTime = '20:00';

  // Quiet Hours (persisted)
  bool _quietHoursEnabled = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final mic = await NotificationPrefsService.getMicrophoneEnabled();
    final photo = await NotificationPrefsService.getPhotoLibraryEnabled();
    final cam = await NotificationPrefsService.getCameraEnabled();

    final push = await NotificationPrefsService.getPushEnabled();
    final session = await NotificationPrefsService.getSessionReminders();
    final messages = await NotificationPrefsService.getNewMessages();
    final daily = await NotificationPrefsService.getDailyCheckins();
    final dailyTime = await NotificationPrefsService.getDailyCheckinsTime();
    final quietHours = await NotificationPrefsService.getQuietHoursEnabled();
    final quietStart = await NotificationPrefsService.getQuietHoursStart();
    final quietEnd = await NotificationPrefsService.getQuietHoursEnd();

    if (mounted) {
      setState(() {
        _microphoneAccess = mic;
        _photoLibrary = photo;
        _cameraAccess = cam;

        _pushNotifications = push;
        _sessionReminders = session;
        _newMessages = messages;
        _dailyCheckins = daily;
        _dailyCheckinsTime = dailyTime;
        _quietHoursEnabled = quietHours;
        _quietHoursStart = quietStart;
        _quietHoursEnd = quietEnd;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialStr = isStart ? _quietHoursStart : _quietHoursEnd;
    final parts = initialStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        await NotificationPrefsService.setQuietHoursStart(timeStr);
        setState(() => _quietHoursStart = timeStr);
      } else {
        await NotificationPrefsService.setQuietHoursEnd(timeStr);
        setState(() => _quietHoursEnd = timeStr);
      }
    }
  }

  Future<void> _selectCheckinTime(BuildContext context) async {
    final parts = _dailyCheckinsTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await NotificationPrefsService.setDailyCheckinsTime(timeStr);
      setState(() => _dailyCheckinsTime = timeStr);
    }
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: hour, minute: minute);
    final period = tod.hour >= 12 ? 'PM' : 'AM';
    final formattedHour = tod.hour == 0 ? 12 : (tod.hour > 12 ? tod.hour - 12 : tod.hour);
    final formattedMinute = tod.minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                        'Notifications',
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          children: [
                            // ── App Permissions ──────────────────────────────
                            _buildSectionLabel('APP PERMISSIONS'),
                            _buildSettingsCard([
                              _buildToggleRow(
                                icon: Icons.notifications_outlined,
                                iconColor: const Color(0xFF6366F1),
                                label: 'Push Notifications',
                                subtitle: 'Receive alerts, reminders, and updates',
                                value: _pushNotifications,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setPushEnabled(v);
                                  setState(() => _pushNotifications = v);
                                },
                              ),
                              _buildDivider(),
                              _buildToggleRow(
                                icon: Icons.mic_outlined,
                                iconColor: const Color(0xFF0077B6),
                                label: 'Microphone Access',
                                subtitle: 'Allow voice messages and audio notes',
                                value: _microphoneAccess,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setMicrophoneEnabled(v);
                                  setState(() => _microphoneAccess = v);
                                },
                              ),
                              _buildDivider(),
                              _buildToggleRow(
                                icon: Icons.photo_library_outlined,
                                iconColor: const Color(0xFF2E9E6B),
                                label: 'Photo Library',
                                subtitle: 'Access photos for avatar and journaling',
                                value: _photoLibrary,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setPhotoLibraryEnabled(v);
                                  setState(() => _photoLibrary = v);
                                },
                              ),
                              _buildDivider(),
                              _buildToggleRow(
                                icon: Icons.camera_alt_outlined,
                                iconColor: const Color(0xFFE07B39),
                                label: 'Camera',
                                subtitle: 'Take profile photos and document uploads',
                                value: _cameraAccess,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setCameraEnabled(v);
                                  setState(() => _cameraAccess = v);
                                },
                              ),
                            ]),

                            const SizedBox(height: 24),

                            // ── Notification Preferences ─────────────────────
                            _buildSectionLabel('NOTIFICATION PREFERENCES'),
                            _buildSettingsCard([
                              _buildToggleRow(
                                icon: Icons.calendar_today_rounded,
                                iconColor: const Color(0xFF9B5DE5),
                                label: 'Session Reminders',
                                subtitle: 'Get notified 30 mins before sessions',
                                value: _sessionReminders,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setSessionReminders(v);
                                  setState(() => _sessionReminders = v);
                                },
                              ),
                              _buildDivider(),
                              _buildToggleRow(
                                icon: Icons.chat_bubble_outline_rounded,
                                iconColor: const Color(0xFF0077B6),
                                label: 'New Messages',
                                subtitle: 'Direct messages from therapists & care team',
                                value: _newMessages,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setNewMessages(v);
                                  setState(() => _newMessages = v);
                                },
                              ),
                              _buildDivider(),
                              _buildToggleRow(
                                icon: Icons.favorite_border_rounded,
                                iconColor: const Color(0xFFE11D48),
                                label: 'Daily Mood Check-ins',
                                subtitle: 'Friendly nudge to record how you feel',
                                value: _dailyCheckins,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setDailyCheckins(v);
                                  setState(() => _dailyCheckins = v);
                                },
                              ),
                              if (_dailyCheckins) ...[
                                _buildDivider(),
                                _buildTimePickerRow(
                                  label: 'Daily Reminder Time',
                                  timeStr: _dailyCheckinsTime,
                                  onTap: () => _selectCheckinTime(context),
                                ),
                              ],
                            ]),

                            const SizedBox(height: 24),

                            // ── Quiet Hours ──────────────────────────────────
                            _buildSectionLabel('QUIET HOURS (DO NOT DISTURB)'),
                            _buildSettingsCard([
                              _buildToggleRow(
                                icon: Icons.do_not_disturb_on_rounded,
                                iconColor: const Color(0xFF6B7280),
                                label: 'Quiet Hours',
                                subtitle: 'Mute non-urgent notifications while sleeping',
                                value: _quietHoursEnabled,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setQuietHoursEnabled(v);
                                  setState(() => _quietHoursEnabled = v);
                                },
                              ),
                              if (_quietHoursEnabled) ...[
                                _buildDivider(),
                                _buildTimePickerRow(
                                  label: 'From (Start Time)',
                                  timeStr: _quietHoursStart,
                                  onTap: () => _selectTime(context, true),
                                ),
                                _buildDivider(),
                                _buildTimePickerRow(
                                  label: 'To (End Time)',
                                  timeStr: _quietHoursEnd,
                                  onTap: () => _selectTime(context, false),
                                ),
                              ],
                            ]),
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
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
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
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
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
    return Container(
      height: 1,
      color: const Color(0x12000000),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTimePickerRow({
    required String label,
    required String timeStr,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const SizedBox(width: 54), // align with toggles
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(timeStr),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
