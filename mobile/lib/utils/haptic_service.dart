import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// Uses Flutter's built-in HapticFeedback so no external package is needed,
/// with support for global enable/disable via accessibility settings.
class HapticService {
  HapticService._();

  static bool enabled = true;

  /// Light tap — for button presses, tile selections
  static Future<void> lightTap() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — for toggle switches, navigation
  static Future<void> mediumTap() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — for destructive actions (logout, delete, errors)
  static Future<void> heavyTap() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Success feedback — for confirmations (booking, password change)
  static Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Error feedback — for validation failures
  static Future<void> error() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed — for rating stars, mood selection etc.
  static Future<void> selectionChanged() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }
}
