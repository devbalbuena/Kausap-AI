import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/haptic_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _textScaleKey = 'text_scale_factor';
  static const String _highContrastKey = 'high_contrast';
  static const String _accentColorKey = 'accent_color';
  static const String _reduceMotionKey = 'reduce_motion';
  static const String _hapticsKey = 'haptics_enabled';
  static const String _dyslexiaSpacingKey = 'dyslexia_spacing';

  static const Color defaultAccentColor = Color(0xFF0077B6); // Ocean Calm Blue

  String? _currentUserId;

  ThemeMode _themeMode = ThemeMode.light; // Default to light for public/fresh states
  double _textScaleFactor = 1.0; // range: 0.8 to 1.6
  bool _highContrast = false;
  Color _accentColor = defaultAccentColor;
  bool _reduceMotion = false;
  bool _hapticsEnabled = true;
  bool _dyslexiaSpacing = false;

  ThemeProvider() {
    // Initial state is clean default; user-specific settings load when user logs in.
  }

  String? get currentUserId => _currentUserId;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast == true;
  Color get accentColor => _accentColor;
  bool get reduceMotion => _reduceMotion == true;
  bool get hapticsEnabled => _hapticsEnabled != false;
  bool get dyslexiaSpacing => _dyslexiaSpacing == true;

  String _userKey(String baseKey) {
    if (_currentUserId != null && _currentUserId!.trim().isNotEmpty) {
      return '${baseKey}_${_currentUserId!.trim()}';
    }
    return baseKey;
  }

  // ── Load User-Specific Preferences ────────────────────────────────────────

  Future<void> loadUserPreferences(String? userId) async {
    final cleanId = userId?.trim();
    _currentUserId = cleanId;

    if (cleanId == null || cleanId.isEmpty) {
      resetToDefaults();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();

      // 1. Theme Mode
      final savedTheme = prefs.getString(_userKey(_themeKey)) ??
          await storage.read(key: _userKey(_themeKey));
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      } else {
        _themeMode = ThemeMode.light;
      }

      // 2. Accent Color
      final savedAccentInt = prefs.getInt(_userKey(_accentColorKey));
      if (savedAccentInt != null) {
        _accentColor = Color(savedAccentInt);
      } else {
        final secAccent = await storage.read(key: _userKey(_accentColorKey));
        if (secAccent != null) {
          final val = int.tryParse(secAccent);
          _accentColor = val != null ? Color(val) : defaultAccentColor;
        } else {
          _accentColor = defaultAccentColor;
        }
      }

      // 3. Text Scale
      final savedScale = prefs.getDouble(_userKey(_textScaleKey));
      if (savedScale != null) {
        _textScaleFactor = savedScale.clamp(0.8, 1.6);
      } else {
        _textScaleFactor = 1.0;
      }

      // 4. High Contrast
      _highContrast = prefs.getBool(_userKey(_highContrastKey)) ?? false;

      // 5. Reduce Motion
      _reduceMotion = prefs.getBool(_userKey(_reduceMotionKey)) ?? false;

      // 6. Haptics
      _hapticsEnabled = prefs.getBool(_userKey(_hapticsKey)) ?? true;
      HapticService.enabled = _hapticsEnabled;

      // 7. Dyslexia Spacing
      _dyslexiaSpacing = prefs.getBool(_userKey(_dyslexiaSpacingKey)) ?? false;

      notifyListeners();
    } catch (_) {}
  }

  // ── Reset to Global Default (Used on logout & pre-auth screens) ───────────

  void resetToDefaults() {
    _currentUserId = null;
    _themeMode = ThemeMode.light;
    _accentColor = defaultAccentColor;
    _textScaleFactor = 1.0;
    _highContrast = false;
    _reduceMotion = false;
    _hapticsEnabled = true;
    _dyslexiaSpacing = false;
    HapticService.enabled = true;
    notifyListeners();
  }

  // ── Setters (Persisted with user-scoped storage keys) ─────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final modeStr = mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey(_themeKey), modeStr);
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_themeKey), value: modeStr);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light || _themeMode == ThemeMode.system) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> setTextScaleFactor(double value) async {
    _textScaleFactor = value.clamp(0.8, 1.6);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_userKey(_textScaleKey), _textScaleFactor);
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_textScaleKey), value: _textScaleFactor.toString());
    } catch (_) {}
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_highContrastKey), value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_highContrastKey), value: value.toString());
    } catch (_) {}
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userKey(_accentColorKey), color.toARGB32());
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_accentColorKey), value: color.toARGB32().toString());
    } catch (_) {}
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_reduceMotionKey), value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_reduceMotionKey), value: value.toString());
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    HapticService.enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_hapticsKey), value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_hapticsKey), value: value.toString());
    } catch (_) {}
  }

  Future<void> setDyslexiaSpacing(bool value) async {
    _dyslexiaSpacing = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey(_dyslexiaSpacingKey), value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _userKey(_dyslexiaSpacingKey), value: value.toString());
    } catch (_) {}
  }
}
