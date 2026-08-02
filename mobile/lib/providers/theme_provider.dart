import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _textScaleKey = 'text_scale_factor';
  static const String _highContrastKey = 'high_contrast';

  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0; // range: 0.8 to 1.6
  bool _highContrast = false;

  ThemeProvider() {
    _loadTheme();
    _loadTextScale();
    _loadHighContrast();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;

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
}
