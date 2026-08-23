import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'connectivity_service.dart';

/// Offline Mood Queue Service (NFR — Graceful Offline Degradation & Silent Sync)
///
/// Ensures mood check-ins logged while disconnected from the university network
/// are never lost. Moods are stored in local persistent storage and silently
/// synchronized in the background once internet reachability is restored.
class OfflineMoodQueue {
  static const String _queueKey = 'kausap_offline_mood_queue_v1';
  static const String _lastOfflineMoodDateKey = 'kausap_offline_last_mood_date';

  static final OfflineMoodQueue _instance = OfflineMoodQueue._internal();
  factory OfflineMoodQueue() => _instance;

  OfflineMoodQueue._internal() {
    _initListener();
  }

  bool _isSyncing = false;
  StreamSubscription<void>? _connSub;

  void _initListener() {
    // Listen for connectivity changes to trigger automatic silent background sync
    ConnectivityService().addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (ConnectivityService().isOnline) {
      syncPendingMoods();
    }
  }

  /// Save a mood entry to the local queue when offline or if API post fails.
  Future<void> enqueueMood({
    required int moodLevel,
    String? emotions,
    required int intensity,
    String? note,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawQueue = prefs.getStringList(_queueKey) ?? [];

      final entry = {
        'mood_level': moodLevel,
        'emotions': emotions,
        'intensity': intensity,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      };

      rawQueue.add(jsonEncode(entry));
      await prefs.setStringList(_queueKey, rawQueue);

      // Record today's date so UI recognizes today's check-in immediately
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString(_lastOfflineMoodDateKey, todayStr);
      await prefs.setInt('kausap_today_offline_mood_level', moodLevel);

      debugPrint('OfflineMoodQueue: Enqueued mood level $moodLevel. Total in queue: ${rawQueue.length}');
    } catch (e) {
      debugPrint('OfflineMoodQueue error enqueuing: $e');
    }
  }

  /// Check if there are any queued mood entries waiting to be synced.
  Future<bool> hasQueuedMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawQueue = prefs.getStringList(_queueKey) ?? [];
      return rawQueue.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the number of items waiting in the offline queue.
  Future<int> getQueuedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawQueue = prefs.getStringList(_queueKey) ?? [];
      return rawQueue.length;
    } catch (_) {
      return 0;
    }
  }

  /// Check if a mood was logged today while offline.
  Future<int?> getTodayOfflineMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_lastOfflineMoodDateKey);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      if (lastDate == todayStr) {
        return prefs.getInt('kausap_today_offline_mood_level');
      }
    } catch (_) {}
    return null;
  }

  /// Silently post all queued entries to the backend API without disrupting the student.
  Future<void> syncPendingMoods() async {
    if (_isSyncing) return;
    if (!ConnectivityService().isOnline) return;

    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawQueue = prefs.getStringList(_queueKey) ?? [];

      if (rawQueue.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('OfflineMoodQueue: Syncing ${rawQueue.length} offline mood entries silently...');

      final List<String> remainingQueue = [];

      for (final raw in rawQueue) {
        try {
          final Map<String, dynamic> entry = jsonDecode(raw) as Map<String, dynamic>;
          final payload = {
            'mood_level': entry['mood_level'],
            'emotions': entry['emotions'],
            'intensity': entry['intensity'],
            if (entry['note'] != null && (entry['note'] as String).isNotEmpty)
              'note': entry['note'],
          };

          // Send silently so no retry banners pop up
          await ApiClient().post(ApiConfig.mood, body: payload, silent: true);
        } catch (e) {
          // If a single item fails with network error, retain it in remaining queue
          remainingQueue.add(raw);
        }
      }

      await prefs.setStringList(_queueKey, remainingQueue);
      debugPrint('OfflineMoodQueue: Sync complete. ${rawQueue.length - remainingQueue.length} synced, ${remainingQueue.length} remaining.');
    } catch (e) {
      debugPrint('OfflineMoodQueue sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connSub?.cancel();
    ConnectivityService().removeListener(_onConnectivityChanged);
  }
}
