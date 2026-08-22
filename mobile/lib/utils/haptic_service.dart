import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// Uses Flutter's built-in HapticFeedback with support for global enable/disable,
/// safe on web and all target platforms.
class HapticService {
  HapticService._();

  static bool enabled = true;

  /// Light tap — for button presses, tile selections
  static Future<void> lightTap() async {
    if (!enabled || kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact — for toggle switches, navigation
  static Future<void> mediumTap() async {
    if (!enabled || kIsWeb) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact — for destructive actions (logout, delete, errors)
  static Future<void> heavyTap() async {
    if (!enabled || kIsWeb) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Success feedback — for confirmations
  static Future<void> success() async {
    if (!enabled || kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      if (!enabled || kIsWeb) return;
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Error feedback — for validation failures
  static Future<void> error() async {
    if (!enabled || kIsWeb) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      if (!enabled || kIsWeb) return;
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection changed — for rating stars, mood selection etc.
  static Future<void> selectionChanged() async {
    if (!enabled || kIsWeb) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
