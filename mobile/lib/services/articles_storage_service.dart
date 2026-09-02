import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/articles/articles_data.dart';

/// Manages persistent local storage for admin-created articles and engagement metrics.
/// Provides instant offline-first behavior so articles published and student interactions
/// (views, reactions, shares, AI chats) appear immediately across admin and student screens.
class ArticlesStorageService {
  static const _storageKey = 'kausap_articles_local_v1';
  static const _deletedKey = 'kausap_articles_deleted_ids_v1';
  static const _engagementPrefix = 'kausap_article_engagement_';

  /// Load all locally stored admin-created articles.
  static Future<List<ArticleModel>> loadLocalArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<ArticleModel> list = [];
      for (final e in decoded) {
        final rawArticle = ArticleModel.fromJson(e as Map<String, dynamic>);
        list.add(await attachEngagement(rawArticle));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Load all articles (both dynamic and default) enriched with real persistent engagement metrics.
  static Future<List<ArticleModel>> loadAllArticlesWithEngagement() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedList = prefs.getStringList(_deletedKey) ?? [];
    final deletedIds = deletedList.toSet();

    final local = await loadLocalArticles();
    final localIds = local.map((a) => a.id).toSet();
    final List<ArticleModel> fullList = [];

    // Add local (customized/created/archived) articles unless deleted
    for (final a in local) {
      if (!deletedIds.contains(a.id)) {
        fullList.add(a);
      }
    }

    // Add institutional guidance articles unless overridden locally or deleted
    for (final b in ArticlesData.all) {
      if (!localIds.contains(b.id) && !deletedIds.contains(b.id)) {
        fullList.add(await attachEngagement(b));
      }
    }
    return fullList;
  }

  /// Attach stored engagement metrics (views, shares, reactions, AI chats) to any article.
  static Future<ArticleModel> attachEngagement(ArticleModel a) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_engagementPrefix${a.id}');
      if (raw == null) return a;
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;

      final int views = (data['views'] as num?)?.toInt() ?? a.viewCount;
      final int shares = (data['shares'] as num?)?.toInt() ?? a.shareCount;
      final int aiChats = (data['ai_chats'] as num?)?.toInt() ?? a.aiDiscussionCount;

      final Map<String, int> reactions = {};
      if (data['reactions'] is Map) {
        (data['reactions'] as Map).forEach((k, v) {
          reactions[k.toString()] = (v as num?)?.toInt() ?? 0;
        });
      }

      return a.copyWith(
        viewCount: views,
        shareCount: shares,
        aiDiscussionCount: aiChats,
        reactionCounts: reactions.isNotEmpty ? reactions : a.reactionCounts,
      );
    } catch (_) {
      return a;
    }
  }

  /// Record a view (+1) for an article.
  static Future<void> recordView(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_engagementPrefix$articleId';
      final raw = prefs.getString(key);
      Map<String, dynamic> data = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
      final current = (data['views'] as num?)?.toInt() ?? 0;
      data['views'] = current + 1;
      await prefs.setString(key, jsonEncode(data));

      // Also update in admin articles list if dynamic
      await _updateDynamicArticleFields(articleId, (m) {
        m['view_count'] = (m['view_count'] as num? ?? 0).toInt() + 1;
      });
    } catch (_) {}
  }

  /// Record a share (+1) for an article.
  static Future<void> recordShare(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_engagementPrefix$articleId';
      final raw = prefs.getString(key);
      Map<String, dynamic> data = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
      final current = (data['shares'] as num?)?.toInt() ?? 0;
      data['shares'] = current + 1;
      await prefs.setString(key, jsonEncode(data));

      // Also update in admin articles list if dynamic
      await _updateDynamicArticleFields(articleId, (m) {
        m['share_count'] = (m['share_count'] as num? ?? 0).toInt() + 1;
      });
    } catch (_) {}
  }

  /// Record an AI discussion started (+1) from an article.
  static Future<void> recordAiDiscussion(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_engagementPrefix$articleId';
      final raw = prefs.getString(key);
      Map<String, dynamic> data = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
      final current = (data['ai_chats'] as num?)?.toInt() ?? 0;
      data['ai_chats'] = current + 1;
      await prefs.setString(key, jsonEncode(data));

      // Also update in admin articles list if dynamic
      await _updateDynamicArticleFields(articleId, (m) {
        m['ai_discussion_count'] = (m['ai_discussion_count'] as num? ?? 0).toInt() + 1;
      });
    } catch (_) {}
  }

  /// Record or remove an emoji reaction on an article.
  static Future<void> recordReaction(String articleId, String emoji, bool isAdding, [String? previousEmoji]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_engagementPrefix$articleId';
      final raw = prefs.getString(key);
      Map<String, dynamic> data = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
      Map<String, dynamic> reactions = (data['reactions'] is Map) ? Map<String, dynamic>.from(data['reactions'] as Map) : {};

      // Decrement previous emoji if user switched reaction
      if (previousEmoji != null && previousEmoji != emoji && reactions.containsKey(previousEmoji)) {
        final prevCount = (reactions[previousEmoji] as num?)?.toInt() ?? 1;
        if (prevCount <= 1) {
          reactions.remove(previousEmoji);
        } else {
          reactions[previousEmoji] = prevCount - 1;
        }
      }

      if (isAdding) {
        final cur = (reactions[emoji] as num?)?.toInt() ?? 0;
        reactions[emoji] = cur + 1;
      } else {
        final cur = (reactions[emoji] as num?)?.toInt() ?? 1;
        if (cur <= 1) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = cur - 1;
        }
      }

      data['reactions'] = reactions;
      await prefs.setString(key, jsonEncode(data));

      // Also update in admin articles list if dynamic
      await _updateDynamicArticleFields(articleId, (m) {
        m['reaction_counts'] = reactions;
      });
    } catch (_) {}
  }

  static Future<void> _updateDynamicArticleFields(String articleId, void Function(Map<String, dynamic>) updater) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final idx = list.indexWhere((e) => (e as Map<String, dynamic>)['id'] == articleId);
      if (idx >= 0) {
        final map = Map<String, dynamic>.from(list[idx] as Map<String, dynamic>);
        updater(map);
        list[idx] = map;
        await prefs.setString(_storageKey, jsonEncode(list));
      }
    } catch (_) {}
  }

  /// Save a new or updated article to local storage.
  static Future<void> saveArticle(Map<String, dynamic> articleJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // If re-saving an article, remove from deleted IDs list if present
      final id = articleJson['id'] as String?;
      if (id != null) {
        final deletedList = prefs.getStringList(_deletedKey) ?? [];
        if (deletedList.contains(id)) {
          deletedList.remove(id);
          await prefs.setStringList(_deletedKey, deletedList);
        }
      }

      final raw = prefs.getString(_storageKey);
      List<dynamic> list = raw != null ? jsonDecode(raw) as List<dynamic> : [];

      // Replace if id already exists, otherwise add
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
      if (raw != null) {
        List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
        await prefs.setString(_storageKey, jsonEncode(list));
      }

      // Record in deletedIds so default institutional articles won't reappear
      final deletedList = prefs.getStringList(_deletedKey) ?? [];
      if (!deletedList.contains(id)) {
        deletedList.add(id);
        await prefs.setStringList(_deletedKey, deletedList);
      }
    } catch (_) {}
  }

  /// Archive or unarchive an article.
  static Future<void> archiveArticle(String id, bool archive) async {
    try {
      final all = await loadAllArticlesWithEngagement();
      final idx = all.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        final article = all[idx];
        final updated = article.copyWith(status: archive ? 'archived' : 'published');
        await saveArticle(updated.toJson());
      }
    } catch (_) {}
  }

  static const _bookmarkKey = 'kausap_article_bookmarks_v1';

  /// Check if an article is bookmarked.
  static Future<bool> isBookmarked(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarkKey) ?? [];
      return list.contains(articleId);
    } catch (_) {
      return false;
    }
  }

  /// Toggle bookmark status for an article. Returns true if now bookmarked, false if removed.
  static Future<bool> toggleBookmark(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarkKey) ?? [];
      final bool nowBookmarked;
      if (list.contains(articleId)) {
        list.remove(articleId);
        nowBookmarked = false;
      } else {
        list.insert(0, articleId);
        nowBookmarked = true;
      }
      await prefs.setStringList(_bookmarkKey, list);
      return nowBookmarked;
    } catch (_) {
      return false;
    }
  }

  /// Get list of all bookmarked article IDs.
  static Future<List<String>> getBookmarkedArticleIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_bookmarkKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Return the icon that matches a category string.
  static IconData iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'saved':
      case 'bookmarks':
        return Icons.bookmark_rounded;
      case 'student burnout':
        return Icons.school_rounded;
      case 'anxiety & coping':
        return Icons.psychology_rounded;
      case 'family & relations':
        return Icons.diversity_3_rounded;
      case 'crisis prevention':
        return Icons.emergency_rounded;
      case 'mental awareness':
        return Icons.bedtime_rounded;
      case 'stress & anxiety':
        return Icons.self_improvement_rounded;
      case 'depression support':
        return Icons.favorite_rounded;
      case 'mindfulness':
        return Icons.spa_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}
