import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPrefsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // App Permissions
  static const String _keyMicrophone = 'pref_perm_microphone';
  static const String _keyPhotoLibrary = 'pref_perm_photo_library';
  static const String _keyCamera = 'pref_perm_camera';

  // Notification Preferences
  static const String _keyPush = 'pref_push_notifications';
  static const String _keySessionReminders = 'pref_session_reminders';
  static const String _keyNewMessages = 'pref_new_messages';
  static const String _keyDailyCheckins = 'pref_daily_checkins';
  static const String _keyDailyCheckinsTime = 'pref_daily_checkins_time'; // e.g. "20:00"
  
  // Quiet Hours
  static const String _keyQuietHoursEnabled = 'pref_quiet_hours_enabled';
  static const String _keyQuietHoursStart = 'pref_quiet_hours_start'; // e.g. "22:00"
  static const String _keyQuietHoursEnd = 'pref_quiet_hours_end'; // e.g. "07:00"

  static Future<bool> _getBool(String key, {bool defaultValue = true}) async {
    final val = await _storage.read(key: key);
    if (val == null) return defaultValue;
    return val == 'true';
  }

  static Future<void> _setBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  // App Permissions Methods
  static Future<bool> getMicrophoneEnabled() => _getBool(_keyMicrophone, defaultValue: false);
  static Future<void> setMicrophoneEnabled(bool val) => _setBool(_keyMicrophone, val);

  static Future<bool> getPhotoLibraryEnabled() => _getBool(_keyPhotoLibrary, defaultValue: true);
  static Future<void> setPhotoLibraryEnabled(bool val) => _setBool(_keyPhotoLibrary, val);

  static Future<bool> getCameraEnabled() => _getBool(_keyCamera, defaultValue: false);
  static Future<void> setCameraEnabled(bool val) => _setBool(_keyCamera, val);

  // Notification Preferences Methods
  static Future<bool> getPushEnabled() => _getBool(_keyPush, defaultValue: true);
  static Future<void> setPushEnabled(bool val) => _setBool(_keyPush, val);

  static Future<bool> getSessionReminders() => _getBool(_keySessionReminders, defaultValue: true);
  static Future<void> setSessionReminders(bool val) => _setBool(_keySessionReminders, val);

  static Future<bool> getNewMessages() => _getBool(_keyNewMessages, defaultValue: true);
  static Future<void> setNewMessages(bool val) => _setBool(_keyNewMessages, val);

  static Future<bool> getDailyCheckins() => _getBool(_keyDailyCheckins, defaultValue: true);
  static Future<void> setDailyCheckins(bool val) => _setBool(_keyDailyCheckins, val);

  static Future<String> getDailyCheckinsTime() async {
    return await _storage.read(key: _keyDailyCheckinsTime) ?? "20:00";
  }
  static Future<void> setDailyCheckinsTime(String val) async {
    await _storage.write(key: _keyDailyCheckinsTime, value: val);
  }

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
