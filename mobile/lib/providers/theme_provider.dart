import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    _loadTheme();
    _loadTextScale();
    _loadHighContrast();
    _loadAccentColor();
    _loadAccessibilityPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast == true;
  Color get accentColor => _accentColor;
  bool get reduceMotion => _reduceMotion == true;
  bool get hapticsEnabled => _hapticsEnabled != false;
  bool get dyslexiaSpacing => _dyslexiaSpacing == true;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadTheme() async {
    const storage = FlutterSecureStorage();
    final savedTheme = await storage.read(key: _themeKey);
    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> _loadTextScale() async {
    const storage = FlutterSecureStorage();
    final saved = await storage.read(key: _textScaleKey);
    if (saved != null) {
      final parsed = double.tryParse(saved);
      if (parsed != null) {
        _textScaleFactor = parsed.clamp(0.8, 1.6);
        notifyListeners();
      }
    }
  }

  Future<void> _loadHighContrast() async {
    const storage = FlutterSecureStorage();
    final saved = await storage.read(key: _highContrastKey);
    if (saved == 'true') {
      _highContrast = true;
      notifyListeners();
    }
  }

  Future<void> _loadAccentColor() async {
    const storage = FlutterSecureStorage();
    final saved = await storage.read(key: _accentColorKey);
    if (saved != null) {
      final val = int.tryParse(saved);
      if (val != null) {
        _accentColor = Color(val);
        notifyListeners();
      }
    }
  }

  Future<void> _loadAccessibilityPrefs() async {
    const storage = FlutterSecureStorage();
    final motion = await storage.read(key: _reduceMotionKey);
    final haptics = await storage.read(key: _hapticsKey);
    final dyslexia = await storage.read(key: _dyslexiaSpacingKey);

    if (motion == 'true') _reduceMotion = true;
    if (haptics != null) {
      _hapticsEnabled = haptics == 'true';
      HapticService.enabled = _hapticsEnabled;
    }
    if (dyslexia == 'true') _dyslexiaSpacing = true;

    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    const storage = FlutterSecureStorage();
    if (mode == ThemeMode.dark) {
      await storage.write(key: _themeKey, value: 'dark');
    } else if (mode == ThemeMode.light) {
      await storage.write(key: _themeKey, value: 'light');
    } else {
      await storage.write(key: _themeKey, value: 'system');
    }
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
    const storage = FlutterSecureStorage();
    await storage.write(key: _textScaleKey, value: _textScaleFactor.toString());
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    const storage = FlutterSecureStorage();
    await storage.write(key: _highContrastKey, value: value.toString());
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    const storage = FlutterSecureStorage();
    await storage.write(key: _accentColorKey, value: color.toARGB32().toString());
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    const storage = FlutterSecureStorage();
    await storage.write(key: _reduceMotionKey, value: value.toString());
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    HapticService.enabled = value;
    notifyListeners();
    const storage = FlutterSecureStorage();
    await storage.write(key: _hapticsKey, value: value.toString());
  }

  Future<void> setDyslexiaSpacing(bool value) async {
    _dyslexiaSpacing = value;
    notifyListeners();
    const storage = FlutterSecureStorage();
    await storage.write(key: _dyslexiaSpacingKey, value: value.toString());
  }
}
