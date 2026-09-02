import 'package:intl/intl.dart';

/// Centralized Date & Timezone Helper for Kausap AI
/// 
/// Ensures all timestamps stored in UTC (e.g. in PostgreSQL / Neon) are accurately
/// converted to the user's local timezone (Philippine Time UTC+8, etc.) across
/// all student, counselor, and admin screens.
class DateHelper {
  /// Safely parses an ISO date string (with or without 'Z' or offset) into a local [DateTime].
  static DateTime? parseLocal(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    final str = raw.toString().trim();
    if (str.isEmpty) return null;

    try {
      final dt = DateTime.parse(str);
      if (dt.isUtc) return dt.toLocal();
      if (str.endsWith('Z') || str.contains('+') || RegExp(r'-\d{2}:\d{2}$').hasMatch(str)) {
        return dt.toLocal();
      }
      // If naive string with no timezone suffix, treat as UTC and convert to local
      return DateTime.parse('${str}Z').toLocal();
    } catch (_) {
      try {
        return DateTime.parse(str).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  /// Formats date into standard format: e.g. "Sep 2, 2026 • 4:30 PM"
  static String formatDateTime(dynamic raw, {String fallback = 'Recent'}) {
    final dt = parseLocal(raw);
    if (dt == null) return fallback;
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  /// Formats date with relative day: e.g. "Today, 4:30 PM" or "Sep 2, 2026 • 4:30 PM"
  static String formatRelative(dynamic raw, {String fallback = 'Recent'}) {
    final dt = parseLocal(raw);
    if (dt == null) return fallback;

    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    if (isToday) {
      return "Today, ${DateFormat('h:mm a').format(dt)}";
    } else if (isYesterday) {
      return "Yesterday, ${DateFormat('h:mm a').format(dt)}";
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    }
  }

  /// Formats time only: e.g. "4:30 PM"
  static String formatTime(dynamic raw, {String fallback = ''}) {
    final dt = parseLocal(raw);
    if (dt == null) return fallback;
    return DateFormat('h:mm a').format(dt);
  }

  /// Formats date only: e.g. "September 2, 2026"
  static String formatDate(dynamic raw, {String fallback = ''}) {
    final dt = parseLocal(raw);
    if (dt == null) return fallback;
    return DateFormat('MMMM d, yyyy').format(dt);
  }
}
