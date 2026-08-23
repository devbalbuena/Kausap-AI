import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/articles_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../profile/profile_screen.dart';
import 'articles_data.dart';
import 'article_detail_screen.dart';

const String _kRecentlyReadKey = 'recently_read_article_ids';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final ApiClient _api = ApiClient();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<ArticleModel> _allArticles = ArticlesData.all;
  List<ArticleModel> _recentlyRead = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveArticles();
    _loadRecentlyRead();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveArticles() async {
    setState(() => _isLoading = true);

    // Load locally stored admin articles first (offline-first)
    final localArticles = await ArticlesStorageService.loadLocalArticles();
    if (localArticles.isNotEmpty && mounted) {
      setState(() {
        _allArticles = ArticlesData.mergeWithDefaults(localArticles);
        _isLoading = false;
      });
    }

    // Then try to sync from API
    try {
      final res = await _api.get('/articles');
      if (res is List) {
        final live = res.map((e) => ArticleModel.fromJson(e as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _allArticles = ArticlesData.mergeWithDefaults([...localArticles, ...live]);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      // Fallback silently to local + built-in ArticlesData.all
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRecentlyRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_kRecentlyReadKey) ?? [];
      final recent = ids
          .map((id) {
            try {
              return _allArticles.firstWhere((a) => a.id == id);
            } catch (_) {
              return null;
            }
          })
          .whereType<ArticleModel>()
          .toList();
      if (mounted) setState(() => _recentlyRead = recent);
    } catch (_) {}
  }

  List<ArticleModel> get _filteredArticles {
    final category = ArticlesData.categories[_selectedCategoryIndex];
    // Exclude featured from regular list to avoid duplication
    return _allArticles.where((article) {
      if (article.isFeatured && _selectedCategoryIndex == 0 && _searchQuery.isEmpty) return false;
      final matchesCategory = category == 'All' || article.category == category;
      final matchesQuery = _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.author.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  ArticleModel? get _featuredArticle {
    if (_selectedCategoryIndex != 0 || _searchQuery.isNotEmpty) return null;
    try {
      return _allArticles.firstWhere((a) => a.isFeatured);
    } catch (_) {
      return null;
    }
  }

  Widget _buildFeaturedHeroCard(ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(slideRoute(ArticleDetailScreen(article: article))),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [article.themeColor, article.themeColor.withAlpha(180)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: article.themeColor.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -20,
              child: Icon(article.categoryIcon, size: 130, color: Colors.white.withAlpha(25)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('📌 FEATURED', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(article.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(article.title,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(article.readTime, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                      const SizedBox(width: 10),
                      Text('By ${article.author}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyReadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🕐 Recently Read',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentlyRead.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = _recentlyRead[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(slideRoute(ArticleDetailScreen(article: a))),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: a.themeColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: a.themeColor.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(a.categoryIcon, size: 16, color: a.themeColor),
                      const SizedBox(height: 4),
                      Text(a.title,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    GestureDetector(
                      onTap: () {
                        HapticService.lightTap();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                      ),
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.article_rounded, size: 20, color: AppColors.primary),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mental Wellness Articles',
                          style: AppTextStyles.heading2.copyWith(fontSize: 17),
                        ),
                        const Text(
                          'Psychoeducation & Student Factsheets',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final user = auth.currentUser ?? {};
                      final name = user['first_name'] ?? 'U';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                      final avatarUrl = user['avatar_url'] as String?;
                      final avatar = CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withAlpha(30),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                            ? Text(
                                initial,
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                              )
                            : null,
                      );
                      return PopupMenuButton<String>(
                        offset: const Offset(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        child: avatar,
                        onSelected: (value) {
                          if (value == 'profile') {
                            HapticService.lightTap();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary.withAlpha(20),
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                                      ? Text(initial,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                                    const Text('View Profile & Settings', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1AC0C9C2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search articles & mental wellness guides...',
                          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Category Chips Bar
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: ArticlesData.categories.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedCategoryIndex;
                  return GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      setState(() => _selectedCategoryIndex = index);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0x33C0C9C2),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        ArticlesData.categories[index],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Articles List with Featured Hero + Recently Read
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchLiveArticles,
                color: AppColors.primary,
                child: filtered.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🔍', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 12),
                                Text(
                                  'No articles found',
                                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try a different keyword or category.',
                                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: filtered.length + (_featuredArticle != null ? 1 : 0) + (_recentlyRead.isNotEmpty && _selectedCategoryIndex == 0 && _searchQuery.isEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          int offset = 0;

                          // Featured Hero
                          if (_featuredArticle != null) {
                            if (index == 0) return Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildFeaturedHeroCard(_featuredArticle!));
                            offset++;
                          }

                          // Recently Read
                          if (_recentlyRead.isNotEmpty && _selectedCategoryIndex == 0 && _searchQuery.isEmpty) {
                            if (index == offset) return Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildRecentlyReadSection());
                            offset++;
                          }

                          final article = filtered[index - offset];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildArticleCard(article),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    final bool hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.of(context).push(slideRoute(ArticleDetailScreen(article: article)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0x1AC0C9C2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Read Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: article.themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(article.categoryIcon, size: 13, color: article.themeColor),
                      const SizedBox(width: 5),
                      Text(
                        article.category,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: article.themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  article.readTime,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Content Row (with image thumbnail if available)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.subtitle,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: article.themeColor.withAlpha(20),
                      child: article.imageUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(article.imageUrl!.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(article.categoryIcon, color: article.themeColor, size: 28),
                            )
                          : Image.network(
                              article.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(article.categoryIcon, color: article.themeColor, size: 28),
                            ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Author & Read Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: article.themeColor.withAlpha(30),
                      child: Text(
                        article.author.isNotEmpty ? article.author[0] : 'K',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: article.themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      article.author,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Read',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
