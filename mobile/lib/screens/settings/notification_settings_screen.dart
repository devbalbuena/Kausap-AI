import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_prefs_service.dart';
import '../../services/notification_service.dart';
import '../../services/ambient_audio_service.dart';
import '../../services/api_client.dart';
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
  bool _mindfulnessReminders = true;
  bool _streakAlerts = true;

  // ─── Multi-Slot Mood Check-in Schedule ────────────────────────────────────
  bool _morningCheckin = true;
  String _morningCheckinTime = '08:00';
  bool _afternoonCheckin = false;
  String _afternoonCheckinTime = '14:00';
  bool _eveningCheckin = true;
  String _eveningCheckinTime = '20:00';

  // ─── Delivery Channel Preferences ─────────────────────────────────────────
  bool _channelPush = true;
  bool _channelEmail = false;
  bool _channelInApp = true;

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
  bool _savingEmail = false;

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
    final mindful = await NotificationPrefsService.getMindfulnessReminders();
    final streak = await NotificationPrefsService.getStreakAlerts();

    // Multi-slot check-ins
    final morning = await NotificationPrefsService.getMorningCheckin();
    final morningTime = await NotificationPrefsService.getMorningCheckinTime();
    final afternoon = await NotificationPrefsService.getAfternoonCheckin();
    final afternoonTime = await NotificationPrefsService.getAfternoonCheckinTime();
    final evening = await NotificationPrefsService.getEveningCheckin();
    final eveningTime = await NotificationPrefsService.getEveningCheckinTime();

    // Delivery channels
    final chPush = await NotificationPrefsService.getChannelPush();
    final chEmail = await NotificationPrefsService.getChannelEmail();
    final chInApp = await NotificationPrefsService.getChannelInApp();

    final quietHours = await NotificationPrefsService.getQuietHoursEnabled();
    final quietStart = await NotificationPrefsService.getQuietHoursStart();
    final quietEnd = await NotificationPrefsService.getQuietHoursEnd();

    if (mounted) {
      setState(() {
        _microphoneAccess = mic;
        _photoLibrary = photo;
        _cameraAccess = cam;

        _pushNotifications = push;
        _mindfulnessReminders = mindful;
        _streakAlerts = streak;

        _morningCheckin = morning;
        _morningCheckinTime = morningTime;
        _afternoonCheckin = afternoon;
        _afternoonCheckinTime = afternoonTime;
        _eveningCheckin = evening;
        _eveningCheckinTime = eveningTime;

        _channelPush = chPush;
        _channelEmail = chEmail;
        _channelInApp = chInApp;

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

  Future<void> _selectSlotTime(BuildContext context, String slot) async {
    String current;
    switch (slot) {
      case 'morning':
        current = _morningCheckinTime;
        break;
      case 'afternoon':
        current = _afternoonCheckinTime;
        break;
      default:
        current = _eveningCheckinTime;
    }

    final parts = current.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
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
      switch (slot) {
        case 'morning':
          await NotificationPrefsService.setMorningCheckinTime(timeStr);
          setState(() => _morningCheckinTime = timeStr);
          break;
        case 'afternoon':
          await NotificationPrefsService.setAfternoonCheckinTime(timeStr);
          setState(() => _afternoonCheckinTime = timeStr);
          break;
        default:
          await NotificationPrefsService.setEveningCheckinTime(timeStr);
          setState(() => _eveningCheckinTime = timeStr);
      }
    }
  }

  /// Sends the check-in schedule to backend so it can deliver email notifications.
  Future<void> _syncScheduleToBackend() async {
    if (!_channelEmail) return;
    setState(() => _savingEmail = true);
    try {
      final api = ApiClient();
      await api.post('/notifications/schedule', body: {
        'morning_enabled': _morningCheckin,
        'morning_time': _morningCheckinTime,
        'afternoon_enabled': _afternoonCheckin,
        'afternoon_time': _afternoonCheckinTime,
        'evening_enabled': _eveningCheckin,
        'evening_time': _eveningCheckinTime,
        'channel_push': _channelPush,
        'channel_email': _channelEmail,
        'channel_inapp': _channelInApp,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Email notification schedule saved!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      // Silently fail — local prefs are already saved
    } finally {
      if (mounted) setState(() => _savingEmail = false);
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

                              // ─────────────────────────────────────────────────
                              // 💖 MOOD CHECK-IN SCHEDULE (NEW)
                              // ─────────────────────────────────────────────────
                              _buildSectionLabel('MOOD CHECK-IN SCHEDULE'),
                              _buildInfoBanner(
                                icon: Icons.info_outline_rounded,
                                text: 'Choose when you want Kausap AI to gently remind you to log your mood. You can enable multiple check-ins throughout the day.',
                              ),
                              const SizedBox(height: 10),
                              _buildSettingsCard([
                                // Morning Slot
                                _buildToggleRow(
                                  icon: Icons.wb_sunny_outlined,
                                  iconColor: const Color(0xFFF59E0B),
                                  label: 'Morning Check-in',
                                  subtitle: 'Start your day with intention & awareness',
                                  value: _morningCheckin,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setMorningCheckin(v);
                                    setState(() => _morningCheckin = v);
                                  },
                                ),
                                if (_morningCheckin) ...[
                                  _buildDivider(),
                                  _buildSlotTimePickerRow(
                                    emoji: '🌅',
                                    label: 'Morning Time',
                                    timeStr: _morningCheckinTime,
                                    onTap: () => _selectSlotTime(context, 'morning'),
                                  ),
                                ],
                                _buildDivider(),

                                // Afternoon Slot
                                _buildToggleRow(
                                  icon: Icons.wb_cloudy_outlined,
                                  iconColor: const Color(0xFF0284C7),
                                  label: 'Afternoon Check-in',
                                  subtitle: 'Mid-day pulse check after classes & activities',
                                  value: _afternoonCheckin,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setAfternoonCheckin(v);
                                    setState(() => _afternoonCheckin = v);
                                  },
                                ),
                                if (_afternoonCheckin) ...[
                                  _buildDivider(),
                                  _buildSlotTimePickerRow(
                                    emoji: '☀️',
                                    label: 'Afternoon Time',
                                    timeStr: _afternoonCheckinTime,
                                    onTap: () => _selectSlotTime(context, 'afternoon'),
                                  ),
                                ],
                                _buildDivider(),

                                // Evening Slot
                                _buildToggleRow(
                                  icon: Icons.nights_stay_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  label: 'Evening Reflection',
                                  subtitle: 'Wind down & reflect on your emotional day',
                                  value: _eveningCheckin,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setEveningCheckin(v);
                                    setState(() => _eveningCheckin = v);
                                  },
                                ),
                                if (_eveningCheckin) ...[
                                  _buildDivider(),
                                  _buildSlotTimePickerRow(
                                    emoji: '🌙',
                                    label: 'Evening Time',
                                    timeStr: _eveningCheckinTime,
                                    onTap: () => _selectSlotTime(context, 'evening'),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 24),

                              // ─────────────────────────────────────────────────
                              // 📬 NOTIFICATION DELIVERY CHANNELS (NEW)
                              // ─────────────────────────────────────────────────
                              _buildSectionLabel('NOTIFICATION DELIVERY CHANNELS'),
                              _buildInfoBanner(
                                icon: Icons.send_rounded,
                                text: 'Choose how Kausap AI sends you mood reminders and wellness nudges.',
                              ),
                              const SizedBox(height: 10),
                              _buildSettingsCard([
                                _buildToggleRow(
                                  icon: Icons.smartphone_rounded,
                                  iconColor: const Color(0xFF6366F1),
                                  label: 'Mobile & Browser Push',
                                  subtitle: 'Instant notification on your device & browser',
                                  value: _channelPush,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setChannelPush(v);
                                    setState(() => _channelPush = v);
                                  },
                                ),
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.mark_email_read_outlined,
                                  iconColor: const Color(0xFF059669),
                                  label: 'Email Notifications',
                                  subtitle: 'Receive a gentle email reminder at your registered address',
                                  value: _channelEmail,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setChannelEmail(v);
                                    setState(() => _channelEmail = v);
                                    if (v) await _syncScheduleToBackend();
                                  },
                                ),
                                if (_channelEmail) ...[
                                  _buildDivider(),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 54),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Email reminders will be sent to your registered email address.',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11.5,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: _savingEmail ? null : _syncScheduleToBackend,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (_savingEmail)
                                                        const SizedBox(
                                                          width: 13,
                                                          height: 13,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                        )
                                                      else
                                                        const Icon(Icons.sync_rounded, color: Colors.white, size: 14),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        'Save Email Schedule',
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                _buildDivider(),
                                _buildToggleRow(
                                  icon: Icons.notifications_active_outlined,
                                  iconColor: const Color(0xFFE11D48),
                                  label: 'In-App Notification Bell',
                                  subtitle: 'Show unread badge & reminders inside the app',
                                  value: _channelInApp,
                                  onChanged: (v) async {
                                    HapticService.lightTap();
                                    await NotificationPrefsService.setChannelInApp(v);
                                    setState(() => _channelInApp = v);
                                    await NotificationService().getUnreadCount();
                                  },
                                ),
                              ]),
                              const SizedBox(height: 24),

                              // ─────────────────────────────────────────────────
                              // 🔔 OTHER WELLNESS NOTIFICATIONS
                              // ─────────────────────────────────────────────────
                              _buildSectionLabel('WELLNESS NOTIFICATIONS'),
                              _buildSettingsCard([
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

  Widget _buildInfoBanner({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: Color(0xFF4C1D95),
                height: 1.4,
              ),
            ),
          ),
        ],
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

  Widget _buildSlotTimePickerRow({
    required String emoji,
    required String label,
    required String timeStr,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timeStr),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
