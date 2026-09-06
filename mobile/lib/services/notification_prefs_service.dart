import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPrefsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // App Permissions
  static const String _keyMicrophone = 'pref_perm_microphone';
  static const String _keyPhotoLibrary = 'pref_perm_photo_library';
  static const String _keyCamera = 'pref_perm_camera';

  // Notification Preferences (Student Mental Wellness)
  static const String _keyPush = 'pref_push_notifications';
  static const String _keyDailyCheckins = 'pref_daily_checkins';
  static const String _keyDailyCheckinsTime = 'pref_daily_checkins_time'; // legacy single-time
  static const String _keyMindfulnessReminders = 'pref_mindfulness_reminders';
  static const String _keyStreakAlerts = 'pref_streak_alerts';

  // ─── NEW: Multi-Slot Mood Check-in Schedule ───────────────────────────────
  // Morning slot
  static const String _keyMorningCheckin = 'pref_mood_morning_enabled';
  static const String _keyMorningCheckinTime = 'pref_mood_morning_time';
  // Afternoon slot
  static const String _keyAfternoonCheckin = 'pref_mood_afternoon_enabled';
  static const String _keyAfternoonCheckinTime = 'pref_mood_afternoon_time';
  // Evening slot
  static const String _keyEveningCheckin = 'pref_mood_evening_enabled';
  static const String _keyEveningCheckinTime = 'pref_mood_evening_time';

  // ─── NEW: Delivery Channel Preferences ────────────────────────────────────
  static const String _keyChannelPush = 'pref_channel_push';
  static const String _keyChannelEmail = 'pref_channel_email';
  static const String _keyChannelInApp = 'pref_channel_inapp';

  // Quiet Hours
  static const String _keyQuietHoursEnabled = 'pref_quiet_hours_enabled';
  static const String _keyQuietHoursStart = 'pref_quiet_hours_start';
  static const String _keyQuietHoursEnd = 'pref_quiet_hours_end';

  static Future<bool> _getBool(String key, {bool defaultValue = true}) async {
    final val = await _storage.read(key: key);
    if (val == null) return defaultValue;
    return val == 'true';
  }

  static Future<void> _setBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  // App Permissions Methods
  static Future<bool> getMicrophoneEnabled() => _getBool(_keyMicrophone, defaultValue: true);
  static Future<void> setMicrophoneEnabled(bool val) => _setBool(_keyMicrophone, val);

  static Future<bool> getPhotoLibraryEnabled() => _getBool(_keyPhotoLibrary, defaultValue: true);
  static Future<void> setPhotoLibraryEnabled(bool val) => _setBool(_keyPhotoLibrary, val);

  static Future<bool> getCameraEnabled() => _getBool(_keyCamera, defaultValue: true);
  static Future<void> setCameraEnabled(bool val) => _setBool(_keyCamera, val);

  // Notification Preferences Methods
  static Future<bool> getPushEnabled() => _getBool(_keyPush, defaultValue: true);
  static Future<void> setPushEnabled(bool val) => _setBool(_keyPush, val);

  static Future<bool> getDailyCheckins() => _getBool(_keyDailyCheckins, defaultValue: true);
  static Future<void> setDailyCheckins(bool val) => _setBool(_keyDailyCheckins, val);

  static Future<String> getDailyCheckinsTime() async {
    return await _storage.read(key: _keyDailyCheckinsTime) ?? "20:00";
  }
  static Future<void> setDailyCheckinsTime(String val) async {
    await _storage.write(key: _keyDailyCheckinsTime, value: val);
  }

  static Future<bool> getMindfulnessReminders() => _getBool(_keyMindfulnessReminders, defaultValue: true);
  static Future<void> setMindfulnessReminders(bool val) => _setBool(_keyMindfulnessReminders, val);

  static Future<bool> getStreakAlerts() => _getBool(_keyStreakAlerts, defaultValue: true);
  static Future<void> setStreakAlerts(bool val) => _setBool(_keyStreakAlerts, val);

  // ─── Multi-Slot Mood Check-in Methods ─────────────────────────────────────
  static Future<bool> getMorningCheckin() => _getBool(_keyMorningCheckin, defaultValue: true);
  static Future<void> setMorningCheckin(bool val) => _setBool(_keyMorningCheckin, val);

  static Future<String> getMorningCheckinTime() async {
    return await _storage.read(key: _keyMorningCheckinTime) ?? "08:00";
  }
  static Future<void> setMorningCheckinTime(String val) async {
    await _storage.write(key: _keyMorningCheckinTime, value: val);
  }

  static Future<bool> getAfternoonCheckin() => _getBool(_keyAfternoonCheckin, defaultValue: false);
  static Future<void> setAfternoonCheckin(bool val) => _setBool(_keyAfternoonCheckin, val);

  static Future<String> getAfternoonCheckinTime() async {
    return await _storage.read(key: _keyAfternoonCheckinTime) ?? "14:00";
  }
  static Future<void> setAfternoonCheckinTime(String val) async {
    await _storage.write(key: _keyAfternoonCheckinTime, value: val);
  }

  static Future<bool> getEveningCheckin() => _getBool(_keyEveningCheckin, defaultValue: true);
  static Future<void> setEveningCheckin(bool val) => _setBool(_keyEveningCheckin, val);

  static Future<String> getEveningCheckinTime() async {
    return await _storage.read(key: _keyEveningCheckinTime) ?? "20:00";
  }
  static Future<void> setEveningCheckinTime(String val) async {
    await _storage.write(key: _keyEveningCheckinTime, value: val);
  }

  // ─── Delivery Channel Methods ──────────────────────────────────────────────
  static Future<bool> getChannelPush() => _getBool(_keyChannelPush, defaultValue: true);
  static Future<void> setChannelPush(bool val) => _setBool(_keyChannelPush, val);

  static Future<bool> getChannelEmail() => _getBool(_keyChannelEmail, defaultValue: false);
  static Future<void> setChannelEmail(bool val) => _setBool(_keyChannelEmail, val);

  static Future<bool> getChannelInApp() => _getBool(_keyChannelInApp, defaultValue: true);
  static Future<void> setChannelInApp(bool val) => _setBool(_keyChannelInApp, val);

  // Quiet Hours Methods
  static Future<bool> getQuietHoursEnabled() => _getBool(_keyQuietHoursEnabled, defaultValue: false);
  static Future<void> setQuietHoursEnabled(bool val) => _setBool(_keyQuietHoursEnabled, val);

  static Future<String> getQuietHoursStart() async {
    return await _storage.read(key: _keyQuietHoursStart) ?? "22:00";
  }
  static Future<void> setQuietHoursStart(String val) async {
    await _storage.write(key: _keyQuietHoursStart, value: val);
  }

  static Future<String> getQuietHoursEnd() async {
    return await _storage.read(key: _keyQuietHoursEnd) ?? "07:00";
  }
  static Future<void> setQuietHoursEnd(String val) async {
    await _storage.write(key: _keyQuietHoursEnd, value: val);
  }
}
