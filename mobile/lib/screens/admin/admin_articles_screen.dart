import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/articles_storage_service.dart';
import '../../utils/haptic_service.dart';
import '../articles/articles_data.dart';
import '../articles/article_detail_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_system_screen.dart';
import 'admin_users_screen.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<ArticleModel> _articles = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Load all local and built-in articles enriched with real engagement metrics
    final allArticlesWithEngagement = await ArticlesStorageService.loadAllArticlesWithEngagement();

    // 2. Try syncing from API in background if online
    List<ArticleModel> apiArticles = [];
    try {
      final res = await _api.get('/admin/articles', silent: true);
      if (res is List) {
        apiArticles = res.map((item) => ArticleModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Merge API articles if available, while retaining local engagement metrics
    final Map<String, ArticleModel> mergedMap = {};
    for (final a in allArticlesWithEngagement) {
      mergedMap[a.id] = a;
    }
    for (final a in apiArticles) {
      // If locally stored has higher engagement or is local, keep or overlay
      if (mergedMap.containsKey(a.id)) {
        final local = mergedMap[a.id]!;
        mergedMap[a.id] = a.copyWith(
          viewCount: local.viewCount > a.viewCount ? local.viewCount : a.viewCount,
          shareCount: local.shareCount > a.shareCount ? local.shareCount : a.shareCount,
          aiDiscussionCount: local.aiDiscussionCount > a.aiDiscussionCount ? local.aiDiscussionCount : a.aiDiscussionCount,
          reactionCounts: local.reactionCounts.isNotEmpty ? local.reactionCounts : a.reactionCounts,
        );
      } else {
        mergedMap[a.id] = a;
      }
    }

    if (mounted) {
      setState(() {
        _articles = mergedMap.values.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteArticle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Article?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Are you sure you want to delete this article? This action cannot be undone.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticService.mediumTap();
      // Always remove from local storage first
      await ArticlesStorageService.deleteArticle(id);
      // Try deleting from server (ignore errors if not deployed yet)
      try {
        await _api.delete('/admin/articles/$id');
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article deleted ✓'), backgroundColor: Color(0xFF0F172A)),
        );
        _fetchArticles();
      }
    }
  }

  void _openArticleEditor([ArticleModel? existing]) {
    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArticleEditorSheet(
        existingArticle: existing,
        onSaved: () {
          _fetchArticles();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.title.toLowerCase().contains(q) ||
          a.subtitle.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q) ||
          a.author.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Articles & Psychoeducation CMS',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            Text(
              'Create & publish student wellness articles',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
            onPressed: _fetchArticles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openArticleEditor(),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Article', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search articles by title, category, author...',
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            // Stats summary bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _statChip('${_articles.where((a) => !a.isBuiltIn && a.status == "published").length}', 'Published', const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _statChip('${_articles.where((a) => !a.isBuiltIn && a.status == "draft").length}', 'Drafts', const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _statChip('${_articles.where((a) => !a.isBuiltIn && a.status == "archived").length}', 'Archived', const Color(0xFF94A3B8)),
                  const Spacer(),
                  _statChip('${ArticlesData.all.length}', 'Built-in', const Color(0xFF0284C7)),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                child: const Icon(Icons.article_rounded, size: 36, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No articles found',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "+ New Article" below to post your first article.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final a = filtered[i];
                            return _buildAdminArticleCard(a);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildAdminArticleCard(ArticleModel a) {
    final statusColor = a.isBuiltIn
        ? const Color(0xFF0284C7)
        : a.status == 'published'
            ? const Color(0xFF16A34A)
            : a.status == 'draft'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF94A3B8);
    final statusLabel = a.isBuiltIn ? '🔒 Built-in' : a.status[0].toUpperCase() + a.status.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.isFeatured ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: a.isFeatured ? 2 : 1,
        ),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEngagementDrawer(a),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: a.themeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: a.themeColor.withAlpha(80)),
                  ),
                  child: a.imageUrl != null && a.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: a.imageUrl!.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(a.imageUrl!.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(a.categoryIcon, color: a.themeColor, size: 28),
                                )
                              : Image.network(
                                  a.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(a.categoryIcon, color: a.themeColor, size: 28),
                                ),
                        )
                      : Icon(a.categoryIcon, color: a.themeColor, size: 28),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + Status row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: a.themeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(a.category,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: a.themeColor)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(statusLabel,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w600, color: statusColor)),
                          ),
                          if (a.isFeatured) ...[const SizedBox(width: 4), const Text('📌', style: TextStyle(fontSize: 12))],
                          const Spacer(),
                          Text(a.readTime, style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(a.title,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(a.subtitle,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Reaction count
                          const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFEC4899)),
                          const SizedBox(width: 3),
                          Text(
                            '${a.reactionCounts.values.fold(0, (s, v) => s + v)}',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 10),
                          // Views
                          const Icon(Icons.visibility_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text('${a.viewCount}',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
                          const Spacer(),
                          // Preview Button (available for all articles)
                          GestureDetector(
                            onTap: () {
                              HapticService.lightTap();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a, isPreview: true)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.remove_red_eye_outlined, size: 13, color: Color(0xFF0284C7)),
                                  SizedBox(width: 4),
                                  Text('Preview', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!a.isBuiltIn) ...
                          [
                            // Featured toggle
                            GestureDetector(
                              onTap: () => _toggleFeatured(a),
                              child: Icon(
                                a.isFeatured ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                size: 18,
                                color: a.isFeatured ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _openArticleEditor(a),
                              child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _deleteArticle(a.id),
                              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                            ),
                          ] else ...
                          [
                            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 3),
                            const Text('Built-in', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFeatured(ArticleModel a) async {
    HapticService.lightTap();
    // Unfeature any previously featured article first
    final updated = _articles.map((article) {
      if (article.id == a.id) return article.copyWith(isFeatured: !a.isFeatured);
      if (article.isFeatured && article.id != a.id) return article.copyWith(isFeatured: false);
      return article;
    }).toList();
    setState(() => _articles = updated);

    // Persist to local storage
    final updatedArticle = updated.firstWhere((x) => x.id == a.id);
    await ArticlesStorageService.saveArticle(updatedArticle.toJson());

    // Try to sync with backend
    try {
      await _api.patch('/admin/articles/${a.id}', body: {'is_featured': updatedArticle.isFeatured}, silent: true);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedArticle.isFeatured ? '📌 Article pinned as Featured!' : 'Article unpinned'),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEngagementDrawer(ArticleModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(a.title,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  if (a.isFeatured)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('📌 Featured', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(a.author, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
              const Divider(height: 24),

              // Button to Preview as Student
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a, isPreview: true)),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                  label: const Text('View Full Student Experience 📖',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats grid
              const Text('Engagement Overview', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _engagementStat(Icons.visibility_rounded, '${a.viewCount}', 'Views', const Color(0xFF0284C7)),
                  const SizedBox(width: 12),
                  _engagementStat(Icons.share_rounded, '${a.shareCount}', 'Shares', const Color(0xFF7C3AED)),
                  const SizedBox(width: 12),
                  _engagementStat(Icons.smart_toy_rounded, '${a.aiDiscussionCount}', 'AI Chats', const Color(0xFF059669)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Reactions Breakdown', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              ...[
                ('💡', 'Insightful'), ('❤️', 'Helpful'), ('🌿', 'Calming'), ('👏', 'Inspiring'),
                ('😢', 'Touched'), ('😮', 'Amazing'), ('🤗', 'Comforting'), ('💪', 'Empowering'),
              ].map((e) {
                final count = a.reactionCounts[e.$1] ?? 0;
                final total = a.reactionCounts.values.fold(0, (s, v) => s + v);
                final pct = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(e.$1, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.$2, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF374151))),
                                Text('$count', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 3),
                            LinearProgressIndicator(
                              value: pct,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: const Color(0xFF0284C7),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (a.isBuiltIn) ...
              [
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 16, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a built-in article. Tap "+ New Article" to create your own custom article.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _engagementStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Bar ────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          }),
          _buildNavItem(Icons.article_rounded, 'Articles', true, null),
          _buildNavItem(Icons.people_alt_rounded, 'Users', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          }),
          _buildNavItem(Icons.flag_rounded, 'Moderation', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminModerationScreen()));
          }),
          _buildNavItem(Icons.tune_rounded, 'System', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminSystemScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    final color = isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Article Editor Sheet (Create / Edit with Image Upload) ─────────────────────
class _ArticleEditorSheet extends StatefulWidget {
  final ArticleModel? existingArticle;
  final VoidCallback onSaved;

  const _ArticleEditorSheet({
    this.existingArticle,
    required this.onSaved,
  });

  @override
  State<_ArticleEditorSheet> createState() => _ArticleEditorSheetState();
}

class _ArticleEditorSheetState extends State<_ArticleEditorSheet> {
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _authorController;
  late TextEditingController _authorRoleController;
  late TextEditingController _readTimeController;
  late TextEditingController _sectionHeadingController;
  late TextEditingController _sectionBodyController;
  late TextEditingController _keyPointsController;

  String _selectedCategory = 'Mental Awareness';
  String _selectedStatus = 'published';
  String? _imageUrl;
  bool _isSaving = false;
  bool _showLivePreview = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existingArticle;
    _titleController = TextEditingController(text: a?.title ?? '');
    _subtitleController = TextEditingController(text: a?.subtitle ?? '');
    _authorController = TextEditingController(text: a?.author ?? 'Dr. Kim Vance');
    _authorRoleController = TextEditingController(text: a?.authorRole ?? 'Counselor & Mental Health Specialist');
    _readTimeController = TextEditingController(text: a?.readTime ?? '4 min read');

    _selectedCategory = a?.category ?? 'Mental Awareness';
    _selectedStatus = a?.status ?? 'published';
    _imageUrl = a?.imageUrl;

    final firstSec = a?.sections.isNotEmpty == true ? a!.sections.first : null;
    _sectionHeadingController = TextEditingController(text: firstSec?.heading ?? 'Understanding the Topic');
    _sectionBodyController = TextEditingController(text: firstSec?.content ?? '');
    _keyPointsController = TextEditingController(text: firstSec?.keyPoints?.join('\n') ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _authorRoleController.dispose();
    _readTimeController.dispose();
    _sectionHeadingController.dispose();
    _sectionBodyController.dispose();
    _keyPointsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticService.lightTap();
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _imageUrl = base64String;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveArticle() async {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final heading = _sectionHeadingController.text.trim();
    final body = _sectionBodyController.text.trim();

    if (title.isEmpty || subtitle.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Title, Subtitle, and Content body'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticService.mediumTap();

    final rawPoints = _keyPointsController.text
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final sections = [
      ArticleSection(
        heading: heading.isEmpty ? 'Key Insights' : heading,
        content: body,
        keyPoints: rawPoints.isNotEmpty ? rawPoints : null,
      ),
    ];

    final payload = {
      'title': title,
      'subtitle': subtitle,
      'category': _selectedCategory,
      'status': _selectedStatus,
      'read_time': _readTimeController.text.trim().isEmpty ? '4 min read' : _readTimeController.text.trim(),
      'author': _authorController.text.trim().isEmpty ? 'CSU Guidance Center' : _authorController.text.trim(),
      'author_role': _authorRoleController.text.trim().isEmpty ? 'Counselor' : _authorRoleController.text.trim(),
      'image_url': _imageUrl,
      'theme_color_hex': _selectedCategory == 'Student Burnout'
          ? '#0284C7'
          : _selectedCategory == 'Anxiety & Coping'
              ? '#7C3AED'
              : _selectedCategory == 'Family & Relations'
                  ? '#059669'
                  : '#4F46E5',
      'content_json': jsonEncode(sections.map((s) => s.toJson()).toList()),
      'is_published': _selectedStatus == 'published',
    };

    // ── Save locally FIRST (always works, even offline) ──
    final localJson = {
      ...payload,
      'id': widget.existingArticle?.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      'author_role': _authorRoleController.text.trim().isEmpty ? 'Counselor' : _authorRoleController.text.trim(),
      'sections': sections.map((s) => s.toJson()).toList(),
      'status': _selectedStatus,
      'is_featured': widget.existingArticle?.isFeatured ?? false,
      'reaction_counts': widget.existingArticle?.reactionCounts ?? {},
      'view_count': widget.existingArticle?.viewCount ?? 0,
      'share_count': widget.existingArticle?.shareCount ?? 0,
      'ai_discussion_count': widget.existingArticle?.aiDiscussionCount ?? 0,
    };
    await ArticlesStorageService.saveArticle(localJson);

    // ── Try syncing to backend in background (non-blocking) ──
    _api.post('/admin/articles', body: payload, silent: true).catchError((_) => null);

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingArticle != null ? 'Article updated! ✨' : 'Article published to student feed! 🚀'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Widget _modeChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingArticle != null ? 'Edit Article' : 'Psychoeducation Article',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _modeChip('✏️ Edit', !_showLivePreview, () => setState(() => _showLivePreview = false)),
                              _modeChip('👁️ Preview', _showLivePreview, () => setState(() => _showLivePreview = true)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // View Content: Live Preview or Edit Form
          Expanded(
            child: _showLivePreview ? _buildLivePreview() : _buildEditForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final title = _titleController.text.trim().isEmpty ? 'Article Title Preview' : _titleController.text.trim();
    final subtitle = _subtitleController.text.trim().isEmpty ? 'Subtitle and brief summary hook...' : _subtitleController.text.trim();
    final heading = _sectionHeadingController.text.trim().isEmpty ? 'Understanding the Topic' : _sectionHeadingController.text.trim();
    final body = _sectionBodyController.text.trim().isEmpty ? 'Your psychoeducational guidance, clinically validated advice, and supportive strategies will be displayed here in full detail...' : _sectionBodyController.text.trim();
    final rawPoints = _keyPointsController.text.split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    final themeColor = _selectedCategory == 'Student Burnout'
        ? const Color(0xFF0284C7)
        : _selectedCategory == 'Anxiety & Coping'
            ? const Color(0xFF7C3AED)
            : _selectedCategory == 'Family & Relations'
                ? const Color(0xFF059669)
                : const Color(0xFF4F46E5);

    final categoryIcon = ArticlesStorageService.iconForCategory(_selectedCategory);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        // Status & Mode indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Student Live Preview • Status: ${_selectedStatus.toUpperCase()}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
        ),
        // Banner preview
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [themeColor, themeColor.withAlpha(190)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _imageUrl != null && _imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageUrl!.startsWith('data:image')
                      ? Image.memory(base64Decode(_imageUrl!.split(',').last), fit: BoxFit.cover)
                      : Image.network(_imageUrl!, fit: BoxFit.cover),
                )
              : Center(child: Icon(categoryIcon, size: 60, color: Colors.white.withAlpha(200))),
        ),
        const SizedBox(height: 16),
        // Category & Read time
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_selectedCategory, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: themeColor)),
            ),
            const Spacer(),
            Text(_readTimeController.text.isEmpty ? '4 min read' : _readTimeController.text,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 12),
        // Title
        Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        // Subtitle
        Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Color(0xFF64748B), height: 1.4)),
        const SizedBox(height: 16),
        // Author card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: themeColor.withAlpha(30),
                child: Text(
                  _authorController.text.isNotEmpty ? _authorController.text[0] : 'C',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: themeColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_authorController.text.isEmpty ? 'CSU Guidance Center' : _authorController.text,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    Text(_authorRoleController.text.isEmpty ? 'Counselor & Mental Health Specialist' : _authorRoleController.text,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        // Section Heading
        Text(heading, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        // Section Body
        Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Color(0xFF334155), height: 1.6)),
        if (rawPoints.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Key Takeaways', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          ...rawPoints.map((pt) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontSize: 16, color: themeColor, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(pt, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF334155)))),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 24),
        // Save button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveArticle,
            icon: const Icon(Icons.publish_rounded),
            label: Text(
              widget.existingArticle != null ? 'Update & Publish Article' : 'Publish Article to Student Feed',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Image Picker Banner
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: _imageUrl != null && _imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageUrl!.startsWith('data:image')
                            ? Image.memory(base64Decode(_imageUrl!.split(',').last), fit: BoxFit.cover)
                            : Image.network(_imageUrl!, fit: BoxFit.cover),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.black.withAlpha(180), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Change Cover', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFF0284C7)),
                      SizedBox(height: 6),
                      Text('Upload Cover Image', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                      Text('PNG, JPG from your gallery or desktop', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),

                // Category & Status Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                items: ArticlesData.categories
                                    .where((c) => c != 'All')
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'published', child: Text('🟢 Published', style: TextStyle(fontFamily: 'Inter', fontSize: 12.5))),
                                  DropdownMenuItem(value: 'draft', child: Text('🟡 Draft', style: TextStyle(fontFamily: 'Inter', fontSize: 12.5))),
                                  DropdownMenuItem(value: 'archived', child: Text('⚪ Archived', style: TextStyle(fontFamily: 'Inter', fontSize: 12.5))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title Input
                const Text('Article Title', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Navigating Midterm Stress with Mindfulness',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
                const SizedBox(height: 14),

                // Subtitle Input
                const Text('Subtitle / Hook', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _subtitleController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Brief summary displayed on the card feed',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
                const SizedBox(height: 14),

                // Author & Read Time Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Author Name', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _authorController,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Read Time', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _readTimeController,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Content Section Heading
                const Text('Section Heading', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _sectionHeadingController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Clinical Signs of Cognitive Fatigue',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
                const SizedBox(height: 14),

                // Content Body
                const Text('Article Body Content', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _sectionBodyController,
                  maxLines: 6,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'Write your psychoeducational guidance and mental wellness insights here...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
                const SizedBox(height: 14),

                // Key Takeaways / Bullets
                const Text('Key Takeaways / Bullet Points (One per line)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _keyPointsController,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Practice 4-7-8 breathing\nTake intentional 15-minute breaks\nReach out to CSU counseling',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveArticle,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.publish_rounded),
                    label: Text(
                      _isSaving ? 'Publishing...' : (widget.existingArticle != null ? 'Update Article' : 'Publish Article to Student Feed'),
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            );
  }
}
