import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_prefs_service.dart';
import '../../services/notification_service.dart';
import '../../services/ambient_audio_service.dart';
import '../../utils/haptic_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // General Permissions
  bool _microphoneAccess = true;
  bool _photoLibrary = true;
  bool _cameraAccess = true;
  bool _pushNotifications = true;

  // Student Preferences
  bool _dailyCheckins = true;
  String _dailyCheckinsTime = '20:00';
  bool _mindfulnessReminders = true;
  bool _streakAlerts = true;

  // Admin Specific Preferences
  bool _crisisDistressAlerts = true;
  bool _selfHarmAlerts = true;
  bool _aiBudgetCapAlerts = true;
  bool _cloudLatencyAlerts = true;
  bool _staffProvisionAlerts = true;
  bool _studentAppealAlerts = true;
  bool _entryChimeEnabled = true;
  bool _hapticsEnabled = true;

  // Quiet Hours
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
    final daily = await NotificationPrefsService.getDailyCheckins();
    final dailyTime = await NotificationPrefsService.getDailyCheckinsTime();
    final mindful = await NotificationPrefsService.getMindfulnessReminders();
    final streak = await NotificationPrefsService.getStreakAlerts();

    final quietHours = await NotificationPrefsService.getQuietHoursEnabled();
    final quietStart = await NotificationPrefsService.getQuietHoursStart();
    final quietEnd = await NotificationPrefsService.getQuietHoursEnd();

    if (mounted) {
      setState(() {
        _microphoneAccess = mic;
        _photoLibrary = photo;
        _cameraAccess = cam;

        _pushNotifications = push;
        _dailyCheckins = daily;
        _dailyCheckinsTime = dailyTime;
        _mindfulnessReminders = mindful;
        _streakAlerts = streak;

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
      hour: int.tryParse(parts[0]) ?? (isStart ? 22 : 7),
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
    final user = context.watch<AuthProvider>().currentUser;
    final role = (user?['role'] ?? 'client').toString().toLowerCase();
    final bool isAdmin = role == 'admin' || role == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                                color: Colors.black.withAlpha(15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin ? 'System & Alert Notifications' : 'Notifications',
                            style: AppTextStyles.heading2.copyWith(fontSize: 17),
                          ),
                          if (isAdmin)
                            const Text(
                              'Master governance & cloud incident alerts',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                            ),
                        ],
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
                            if (isAdmin) ...[
                              // ── 1. CRISIS & DISTRESS ESCALATIONS ───────────
                              _buildSectionLabel('CRISIS & DISTRESS ESCALATIONS'),
                              _buildSettingsCard([
                                _buildToggleRow(
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: const Color(0xFFDC2626),
                                  label: 'Crisis Distress Flags',
                                  subtitle: 'Audio chimes & instant push when student distress is detected',
                                  value: _crisisDistressAlerts,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _crisisDistressAlerts = v);
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.emergency_rounded,
                                  iconColor: const Color(0xFFE11D48),
                                  label: 'High-Risk Self-Harm Triggers',
                                  subtitle: 'Immediate alert for self-harm or urgent counseling needs',
                                  value: _selfHarmAlerts,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _selfHarmAlerts = v);
                                  },
                                ),
                              ]),
                              const SizedBox(height: 20),

                              // ── 2. AI & CLOUD TELEMETRY ALERTS ─────────────
                              _buildSectionLabel('AI & CLOUD TELEMETRY ALERTS'),
                              _buildSettingsCard([
                                _buildToggleRow(
                                  icon: Icons.toll_rounded,
                                  iconColor: const Color(0xFF0284C7),
                                  label: 'AI Monthly Budget Alerts',
                                  subtitle: 'Notify when Gemini 2.0 spend approaches 80% of budget cap',
                                  value: _aiBudgetCapAlerts,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _aiBudgetCapAlerts = v);
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.cloud_sync_rounded,
                                  iconColor: const Color(0xFF16A34A),
                                  label: 'Neon Cloud Latency & Health',
                                  subtitle: 'Incident alert if database latency exceeds 1,000ms',
                                  value: _cloudLatencyAlerts,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _cloudLatencyAlerts = v);
                                  },
                                ),
                              ]),
                              const SizedBox(height: 20),

                              // ── 3. WORKFORCE & GOVERNANCE ──────────────────
                              _buildSectionLabel('WORKFORCE & SECURITY GOVERNANCE'),
                              _buildSettingsCard([
                                _buildToggleRow(
                                  icon: Icons.badge_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  label: 'Staff Provisioning & Verification',
                                  subtitle: 'Alerts for counselor onboarding & verification codes',
                                  value: _staffProvisionAlerts,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _staffProvisionAlerts = v);
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.mark_email_unread_outlined,
                                  iconColor: const Color(0xFFD97706),
                                  label: 'Student Reactivation Appeals',
                                  subtitle: 'Notifications when deactivated students submit review requests',
                                  value: _studentAppealAlerts,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _studentAppealAlerts = v);
                                  },
                                ),
                              ]),
                              const SizedBox(height: 20),

                              // ── 4. AUDIO & HAPTIC PREFERENCES ───────────────
                              _buildSectionLabel('CONSOLE AUDIO & HAPTIC PREFERENCES'),
                              _buildSettingsCard([
                                _buildToggleRow(
                                  icon: Icons.volume_up_outlined,
                                  iconColor: const Color(0xFF2563EB),
                                  label: 'Console Entry Audio Chime',
                                  subtitle: 'Play audio chime upon opening console when alerts are active',
                                  value: _entryChimeEnabled,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _entryChimeEnabled = v);
                                    if (v) AmbientAudioService.playNotificationChimeIfAllowed();
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.vibration_rounded,
                                  iconColor: const Color(0xFF475569),
                                  label: 'Haptic Feedback',
                                  subtitle: 'Tactile vibration response on administrative button actions',
                                  value: _hapticsEnabled,
                                  onChanged: (v) {
                                    HapticService.lightTap();
                                    setState(() => _hapticsEnabled = v);
                                  },
                                ),
                              ]),
                              const SizedBox(height: 20),
                            ] else ...[
                              // ── Client / Student Permissions & Wellness ─────
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
                                    await NotificationService().getUnreadCount();
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.mic_outlined,
                                  iconColor: const Color(0xFF0077B6),
                                  label: 'Microphone Access',
                                  subtitle: 'Allow voice dictation, audio notes & calls',
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
                                  subtitle: 'Take profile photos and video sessions',
                                  value: _cameraAccess,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setCameraEnabled(v);
                                    setState(() => _cameraAccess = v);
                                  },
                                ),
                              ]),
                              const SizedBox(height: 24),

                              _buildSectionLabel('WELLNESS NOTIFICATIONS'),
                              _buildSettingsCard([
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
                                    await NotificationService().getUnreadCount();
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
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.spa_outlined,
                                  iconColor: const Color(0xFF2E9E6B),
                                  label: 'Mindfulness & Reflection',
                                  subtitle: 'Reminders for daily journaling & breathing',
                                  value: _mindfulnessReminders,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setMindfulnessReminders(v);
                                    setState(() => _mindfulnessReminders = v);
                                    await NotificationService().getUnreadCount();
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.local_fire_department_outlined,
                                  iconColor: const Color(0xFFF59E0B),
                                  label: 'Streak & Milestones',
                                  subtitle: 'Celebrate consecutive wellness habits',
                                  value: _streakAlerts,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setStreakAlerts(v);
                                    setState(() => _streakAlerts = v);
                                    await NotificationService().getUnreadCount();
                                  },
                                ),
                              ]),
                              const SizedBox(height: 24),
                            ],

                            // ── Quiet Hours (Do Not Disturb) ─────────────────
                            _buildSectionLabel(isAdmin ? 'QUIET HOURS (CRITICAL CRISIS ALERTS REMAIN ACTIVE)' : 'QUIET HOURS (DO NOT DISTURB)'),
                            _buildSettingsCard([
                              _buildToggleRow(
                                icon: Icons.do_not_disturb_on_rounded,
                                iconColor: const Color(0xFF6B7280),
                                label: 'Quiet Hours',
                                subtitle: isAdmin
                                    ? 'Mute routine telemetry notices during off-hours'
                                    : 'Mute non-urgent notifications while sleeping',
                                value: _quietHoursEnabled,
                                onChanged: (v) async {
                                  HapticService.lightTap();
                                  await NotificationPrefsService.setQuietHoursEnabled(v);
                                  setState(() => _quietHoursEnabled = v);
                                  await NotificationService().getUnreadCount();
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
            color: Colors.black.withAlpha(8),
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
            activeTrackColor: AppColors.primaryLight,
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
            const SizedBox(width: 54),
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
