import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// Uses Flutter's built-in HapticFeedback so no external package is needed,
/// but the methods are named semantically for clarity.
class HapticService {
  HapticService._();

  /// Light tap — for button presses, tile selections
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — for toggle switches, navigation
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — for destructive actions (logout, delete, errors)
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  /// Success feedback — for confirmations (booking, password change)
  static Future<void> success() async {
    // Double light + medium to simulate a "success" pattern
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Error feedback — for validation failures
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed — for rating stars, mood selection etc.
  static Future<void> selectionChanged() async {
    await HapticFeedback.selectionClick();
  }
}
