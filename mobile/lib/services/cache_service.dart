import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache service using shared_preferences.
/// Stores JSON-serializable data with an optional TTL (time-to-live).
class CacheService {
  static const String _prefix = 'kausap_cache_';
  static const String _tsSuffix = '_ts';

  /// Save a list of maps to cache under [key].
  /// [ttlMinutes] defaults to 60 minutes.
  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> data, {
    int ttlMinutes = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
    await prefs.setInt(
      '$_prefix$key$_tsSuffix',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Save a single map to cache under [key].
  static Future<void> saveMap(
    String key,
    Map<String, dynamic> data, {
    int ttlMinutes = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
    await prefs.setInt(
      '$_prefix$key$_tsSuffix',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Read a cached list. Returns null if expired or missing.
  static Future<List<Map<String, dynamic>>?> readList(
    String key, {
    int ttlMinutes = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_prefix$key$_tsSuffix');
    if (ts == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttlMinutes * 60 * 1000) return null; // Expired

    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  /// Read a cached map. Returns null if expired or missing.
  static Future<Map<String, dynamic>?> readMap(
    String key, {
    int ttlMinutes = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_prefix$key$_tsSuffix');
    if (ts == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttlMinutes * 60 * 1000) return null;

    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Check if a cache entry exists and is still fresh.
  static Future<bool> isFresh(String key, {int ttlMinutes = 60}) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_prefix$key$_tsSuffix');
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age <= ttlMinutes * 60 * 1000;
  }

  /// Delete a specific cache entry.
  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
    await prefs.remove('$_prefix$key$_tsSuffix');
  }

  /// Clear all Kausap cache entries.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Save a raw string to cache.
  static Future<void> saveString(
    String key,
    String value, {
    int ttlMinutes = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', value);
    await prefs.setInt(
      '$_prefix$key$_tsSuffix',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Read a cached raw string. Returns null if expired or missing.
  static Future<String?> readString(
    String key, {
    int ttlMinutes = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_prefix$key$_tsSuffix');
    if (ts == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttlMinutes * 60 * 1000) return null;
    return prefs.getString('$_prefix$key');
  }

  /// Generic cached API fetch for List responses.
  ///
  /// Usage:
  /// ```dart
  /// final sessions = await CacheService.cachedFetchList(
  ///   key: CacheKeys.sessions,
  ///   ttlMinutes: 5,
  ///   fetch: () => apiClient.getSessions(),
  /// );
  /// ```
  static Future<List<Map<String, dynamic>>?> cachedFetchList({
    required String key,
    required Future<List<Map<String, dynamic>>> Function() fetch,
    int ttlMinutes = 10,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readList(key, ttlMinutes: ttlMinutes);
      if (cached != null) return cached;
    }
    try {
      final fresh = await fetch();
      await saveList(key, fresh, ttlMinutes: ttlMinutes);
      return fresh;
    } catch (_) {
      // On error, return stale cache if available (any TTL)
      return await readList(key, ttlMinutes: 999999);
    }
  }

  /// Generic cached API fetch for Map responses.
  static Future<Map<String, dynamic>?> cachedFetchMap({
    required String key,
    required Future<Map<String, dynamic>> Function() fetch,
    int ttlMinutes = 10,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readMap(key, ttlMinutes: ttlMinutes);
      if (cached != null) return cached;
    }
    try {
      final fresh = await fetch();
      await saveMap(key, fresh, ttlMinutes: ttlMinutes);
      return fresh;
    } catch (_) {
      return await readMap(key, ttlMinutes: 999999);
    }
  }
}

/// Cache keys used across the app — centralized for scalability.
class CacheKeys {
  // Home
  static const String professionals = 'professionals';
  static const String homeData = 'home_data';
  static const String notifications = 'notifications';

  // Sessions
  static const String sessions = 'sessions';
  static const String upcomingSessions = 'upcoming_sessions';
  static const String pastSessions = 'past_sessions';

  // Profile
  static const String userProfile = 'user_profile';
  static const String moodTrends = 'mood_trends';

  // Streak & Quests
  static const String wellnessStreak = 'wellness_streak';
  static const String dailyQuests = 'daily_quests';

  // Messages
  static const String messagesList = 'messages_list';

  // Discover
  static const String discoverProfessionals = 'discover_professionals';

  // Emergency
  static const String emergencyContacts = 'emergency_contacts';
}
