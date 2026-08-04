import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPrefsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyPush = 'pref_push_notifications';
  static const String _keySessionReminders = 'pref_session_reminders';
  static const String _keyNewMessages = 'pref_new_messages';
  static const String _keyDailyCheckins = 'pref_daily_checkins';

  static Future<bool> _getBool(String key, {bool defaultValue = true}) async {
    final val = await _storage.read(key: key);
    if (val == null) return defaultValue;
    return val == 'true';
  }

  static Future<void> _setBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<bool> getPushEnabled() => _getBool(_keyPush, defaultValue: true);
  static Future<void> setPushEnabled(bool val) => _setBool(_keyPush, val);

  static Future<bool> getSessionReminders() => _getBool(_keySessionReminders, defaultValue: true);
  static Future<void> setSessionReminders(bool val) => _setBool(_keySessionReminders, val);

  static Future<bool> getNewMessages() => _getBool(_keyNewMessages, defaultValue: true);
  static Future<void> setNewMessages(bool val) => _setBool(_keyNewMessages, val);

  static Future<bool> getDailyCheckins() => _getBool(_keyDailyCheckins, defaultValue: true);
  static Future<void> setDailyCheckins(bool val) => _setBool(_keyDailyCheckins, val);
}
