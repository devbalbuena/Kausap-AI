import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'notification_prefs_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _readIdsKey = 'notif_read_ids_v1';
  static const String _allReadTimestampKey = 'notif_all_read_ts_v1';

  Future<Set<String>> _getReadIds() async {
    try {
      final raw = await _storage.read(key: _readIdsKey);
      if (raw != null && raw.isNotEmpty) {
        return Set<String>.from(jsonDecode(raw) as List);
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    try {
      await _storage.write(key: _readIdsKey, value: jsonEncode(ids.toList()));
    } catch (_) {}
  }

  Future<DateTime?> _getAllReadTimestamp() async {
    try {
      final raw = await _storage.read(key: _allReadTimestampKey);
      if (raw != null && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Fetch all notifications for current user, filtered dynamically by active Notification Settings.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    List<Map<String, dynamic>> rawList = [];

    try {
      final response = await _apiClient.get(ApiConfig.notifications, silent: true);
      if (response is List) {
        rawList = List<Map<String, dynamic>>.from(
          response.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } catch (_) {}

    // Apply locally persisted read state (for fallback & offline resilience)
    final readIds = await _getReadIds();
    final allReadAt = await _getAllReadTimestamp();

    for (final item in rawList) {
      final id = item['id']?.toString() ?? '';
      if (readIds.contains(id)) {
        item['is_read'] = true;
      } else if (allReadAt != null) {
        final createdAtStr = item['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null && !createdAt.isAfter(allReadAt)) {
            item['is_read'] = true;
          }
        }
      }
    }

    // Filter notifications based on user's active Notification Settings
    final filtered = await _filterBySettings(rawList);

    // Update global unread badge count notifier
    final unread = filtered.where((n) => n['is_read'] != true).length;
    unreadCountNotifier.value = unread;

    return filtered;
  }

  /// Get count of unread notifications, synced with settings.
  Future<int> getUnreadCount() async {
    final list = await getNotifications();
    final count = list.where((n) => n['is_read'] != true).length;
    unreadCountNotifier.value = count;
    return count;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    final readIds = await _getReadIds();
    readIds.add(notificationId);
    await _saveReadIds(readIds);

    try {
      await _apiClient.put(
        '${ApiConfig.notifications}/$notificationId/read',
        body: {},
        silent: true,
      );
    } catch (_) {}

    final current = unreadCountNotifier.value;
    if (current > 0) {
      unreadCountNotifier.value = current - 1;
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    await _storage.write(key: _allReadTimestampKey, value: now.toIso8601String());

    // Also persist all current IDs
    try {
      final currentList = await _generateDynamicFallback();
      final readIds = await _getReadIds();
      for (final n in currentList) {
        final id = n['id']?.toString();
        if (id != null) readIds.add(id);
      }
      await _saveReadIds(readIds);
    } catch (_) {}

    try {
      await _apiClient.put(
        ApiConfig.notificationsReadAll,
        body: {},
        silent: true,
      );
    } catch (_) {}

    unreadCountNotifier.value = 0;
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete(
        '${ApiConfig.notifications}/$notificationId',
        silent: true,
      );
    } catch (_) {}
  }

  /// Clear all notifications.
  Future<void> clearAllNotifications() async {
    try {
      await _apiClient.delete(
        '${ApiConfig.notifications}/clear-all',
        silent: true,
      );
    } catch (_) {}
    unreadCountNotifier.value = 0;
  }

  /// Filters notifications list against user's preferences in NotificationSettingsScreen.
  Future<List<Map<String, dynamic>>> _filterBySettings(List<Map<String, dynamic>> list) async {
    final pushEnabled = await NotificationPrefsService.getPushEnabled();
    if (!pushEnabled) return [];

    final dailyMoodEnabled = await NotificationPrefsService.getDailyCheckins();
    final mindfulnessEnabled = await NotificationPrefsService.getMindfulnessReminders();
    final streakAlertsEnabled = await NotificationPrefsService.getStreakAlerts();

    return list.where((item) {
      final type = (item['type'] ?? '').toString().toLowerCase();
      final title = (item['title'] ?? '').toString().toLowerCase();

      // Daily Mood check-in filter
      if (type == 'mood' || title.contains('mood') || title.contains('daily wellness')) {
        if (!dailyMoodEnabled) return false;
      }

      // Mindfulness / Journal reflection filter
      if (type == 'journal' || type == 'system' || title.contains('reflection') || title.contains('journal')) {
        if (!mindfulnessEnabled) return false;
      }

      // Streak & Milestones filter
      if (type == 'alert' || title.contains('streak') || title.contains('milestone')) {
        if (!streakAlertsEnabled) return false;
      }

      return true;
    }).toList();
  }

  /// Generates dynamic contextual notifications based on real student activity
  Future<List<Map<String, dynamic>>> _generateDynamicFallback() async {
    final list = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 1. Check if mood logged today
    bool moodLogged = false;
    int moodCount = 0;
    try {
      final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
      if (moodData is List) {
        moodCount = moodData.length;
        moodLogged = moodData.any((e) => (e['created_at'] as String?)?.startsWith(todayStr) ?? false);
      }
    } catch (_) {}

    if (!moodLogged) {
      list.add({
        'id': 'notif_daily_mood',
        'type': 'mood',
        'title': '🌿 Daily Wellness Check-in',
        'body': 'How are you feeling today? Tap to record your mood in 1 tap.',
        'is_read': false,
        'created_at': now.subtract(const Duration(minutes: 3)).toIso8601String(),
      });
    } else {
      list.add({
        'id': 'notif_mood_done',
        'type': 'mood',
        'title': '✨ Daily Mood Logged',
        'body': 'Great job tracking your emotional wellness today! Check out your trends.',
        'is_read': true,
        'created_at': now.subtract(const Duration(minutes: 20)).toIso8601String(),
      });
    }

    // 2. Streak alert
    if (moodCount >= 1) {
      list.add({
        'id': 'notif_streak',
        'type': 'alert',
        'title': '🔥 Streak Milestone!',
        'body': 'You are maintaining your consistency! Keep up your daily check-in habits.',
        'is_read': false,
        'created_at': now.subtract(const Duration(minutes: 35)).toIso8601String(),
      });
    }

    // 3. Clinical screener check-in invitation
    list.add({
      'id': 'notif_screener',
      'type': 'assessment',
      'title': '📋 Clinical Self-Assessment Ready',
      'body': 'Take a quick 2-minute PHQ-9 or GAD-7 screener to gain deep emotional insights.',
      'is_read': false,
      'created_at': now.subtract(const Duration(hours: 1, minutes: 15)).toIso8601String(),
    });

    // 4. Daily journal reminder
    list.add({
      'id': 'notif_journal',
      'type': 'journal',
      'title': '📖 Evening Reflection',
      'body': 'Take a few minutes to write or voice record your thoughts in your Daily Journal.',
      'is_read': true,
      'created_at': now.subtract(const Duration(hours: 3, minutes: 30)).toIso8601String(),
    });

    return list;
  }
}
