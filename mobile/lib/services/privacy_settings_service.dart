import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the Privacy Screen setting (blur app when backgrounded).
class PrivacySettingsService {
  static const String _privacyScreenKey = 'privacy_screen_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Returns whether the Privacy Screen (blur on background) is enabled.
  /// Defaults to true for security by default.
  static Future<bool> isPrivacyScreenEnabled() async {
    final val = await _storage.read(key: _privacyScreenKey);
    // Default to true (secure by default)
    return val != 'false';
  }

  /// Enable or disable the Privacy Screen.
  static Future<void> setPrivacyScreen(bool enabled) async {
    await _storage.write(key: _privacyScreenKey, value: enabled.toString());
  }
}
