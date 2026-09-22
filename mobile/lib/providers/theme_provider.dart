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

  ThemeMode _themeMode = ThemeMode.light; // Default to light for first-time users
  double _textScaleFactor = 1.0; // range: 0.8 to 1.6
  bool _highContrast = false;
  Color _accentColor = const Color(0xFF0077B6); // Default Blue
  bool _reduceMotion = false;
  bool _hapticsEnabled = true;
  bool _dyslexiaSpacing = false;

  ThemeProvider() {
    _loadPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast == true;
  Color get accentColor => _accentColor;
  bool get reduceMotion => _reduceMotion == true;
  bool get hapticsEnabled => _hapticsEnabled != false;
  bool get dyslexiaSpacing => _dyslexiaSpacing == true;

  // ── Load All Preferences with Dual-Storage Resilience ─────────────────────

  Future<void> _loadPreferences() async {
    // 1. First try SharedPreferences (instant synchronous memory cache on all platforms)
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      }

      final savedAccent = prefs.getInt(_accentColorKey);
      if (savedAccent != null) {
        _accentColor = Color(savedAccent);
      }

      final savedScale = prefs.getDouble(_textScaleKey);
      if (savedScale != null) {
        _textScaleFactor = savedScale.clamp(0.8, 1.6);
      }

      final savedContrast = prefs.getBool(_highContrastKey);
      if (savedContrast != null) {
        _highContrast = savedContrast;
      }

      final savedMotion = prefs.getBool(_reduceMotionKey);
      if (savedMotion != null) {
        _reduceMotion = savedMotion;
      }

      final savedHaptics = prefs.getBool(_hapticsKey);
      if (savedHaptics != null) {
        _hapticsEnabled = savedHaptics;
        HapticService.enabled = _hapticsEnabled;
      }

      final savedDyslexia = prefs.getBool(_dyslexiaSpacingKey);
      if (savedDyslexia != null) {
        _dyslexiaSpacing = savedDyslexia;
      }

      notifyListeners();
    } catch (_) {}

    // 2. Secondary check on FlutterSecureStorage (for backwards compatibility)
    try {
      const storage = FlutterSecureStorage();
      final secTheme = await storage.read(key: _themeKey);
      if (secTheme != null) {
        if (secTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (secTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      }

      final secAccent = await storage.read(key: _accentColorKey);
      if (secAccent != null) {
        final val = int.tryParse(secAccent);
        if (val != null) {
          _accentColor = Color(val);
        }
      }

      notifyListeners();
    } catch (_) {}
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final modeStr = mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, modeStr);
      const storage = FlutterSecureStorage();
      await storage.write(key: _themeKey, value: modeStr);
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
      await prefs.setDouble(_textScaleKey, _textScaleFactor);
      const storage = FlutterSecureStorage();
      await storage.write(key: _textScaleKey, value: _textScaleFactor.toString());
    } catch (_) {}
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _highContrastKey, value: value.toString());
    } catch (_) {}
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, color.toARGB32());
      const storage = FlutterSecureStorage();
      await storage.write(key: _accentColorKey, value: color.toARGB32().toString());
    } catch (_) {}
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reduceMotionKey, value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _reduceMotionKey, value: value.toString());
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    HapticService.enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsKey, value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _hapticsKey, value: value.toString());
    } catch (_) {}
  }

  Future<void> setDyslexiaSpacing(bool value) async {
    _dyslexiaSpacing = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dyslexiaSpacingKey, value);
      const storage = FlutterSecureStorage();
      await storage.write(key: _dyslexiaSpacingKey, value: value.toString());
    } catch (_) {}
  }
}
