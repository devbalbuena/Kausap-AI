import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages Privacy Screen & Quick Escape settings
class PrivacySettingsService {
  static const String _privacyScreenKey = 'privacy_screen_enabled';
  static const String _quickEscapeKey = 'quick_escape_on_home_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Returns whether the Privacy Screen (blur on background) is enabled.
  /// Defaults to true for security by default.
  static Future<bool> isPrivacyScreenEnabled() async {
    final val = await _storage.read(key: _privacyScreenKey);
    return val != 'false';
  }

  /// Enable or disable the Privacy Screen.
  static Future<void> setPrivacyScreen(bool enabled) async {
    await _storage.write(key: _privacyScreenKey, value: enabled.toString());
  }

  /// Returns whether the Quick Escape panic button is shown on the Home Screen header.
  /// Defaults to false (clean by default).
  static Future<bool> isQuickEscapeEnabled() async {
    final val = await _storage.read(key: _quickEscapeKey);
    return val == 'true';
  }

  /// Enable or disable showing the Quick Escape button on the Home Screen.
  static Future<void> setQuickEscape(bool enabled) async {
    await _storage.write(key: _quickEscapeKey, value: enabled.toString());
  }
}
