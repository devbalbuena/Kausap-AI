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
}

/// Cache keys used across the app
class CacheKeys {
  static const String professionals = 'professionals';
  static const String homeData = 'home_data';
  static const String notifications = 'notifications';
}
