import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/articles/articles_data.dart';

/// Manages persistent local storage for admin-created articles.
/// Provides instant offline-first behavior so articles published by the
/// Admin appear immediately even when the backend is unreachable.
class ArticlesStorageService {
  static const _storageKey = 'kausap_articles_local_v1';

  /// Load all locally stored admin-created articles.
  static Future<List<ArticleModel>> loadLocalArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save a new or updated article to local storage.
  static Future<void> saveArticle(Map<String, dynamic> articleJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      List<dynamic> list = raw != null ? jsonDecode(raw) as List<dynamic> : [];

      // Replace if id already exists, otherwise add
      final id = articleJson['id'] as String?;
      final idx = list.indexWhere((e) => (e as Map<String, dynamic>)['id'] == id);
      if (idx >= 0) {
        list[idx] = articleJson;
      } else {
        list.insert(0, articleJson);
      }

      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Delete an article from local storage by id.
  static Future<void> deleteArticle(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Build a raw map from form fields suitable for saving / sending to the API.
  static Map<String, dynamic> buildArticlePayload({
    required String title,
    required String subtitle,
    required String author,
    required String authorRole,
    required String category,
    required String themeColorHex,
    required List<Map<String, dynamic>> sections,
    String? imageBase64,
  }) {
    final payload = <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'author': author,
      'author_role': authorRole,
      'category': category,
      'theme_color_hex': themeColorHex,
      'read_time': '${(sections.length * 2 + 2)} min read',
      'is_published': true,
      'sections': sections,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      payload['image_url'] = imageBase64;
    }
    return payload;
  }

  /// Return the icon that matches a category string.
  static IconData iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'stress & anxiety':
        return Icons.self_improvement_rounded;
      case 'depression support':
        return Icons.favorite_rounded;
      case 'mindfulness':
        return Icons.spa_rounded;
      case 'academic wellness':
        return Icons.school_rounded;
      case 'relationships':
        return Icons.people_rounded;
      case 'crisis support':
        return Icons.emergency_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}
