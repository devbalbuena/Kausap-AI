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
  List<String> _bookmarkedIds = [];
  bool _isLoading = false;

  List<String> get _categories => [
    'All',
    '🔖 Saved',
    ...ArticlesData.categories.where((c) => c != 'All'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveArticles();
    _loadRecentlyRead();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveArticles() async {
    setState(() => _isLoading = true);

    // 1. Load locally stored and built-in articles with real engagement
    final localArticles = await ArticlesStorageService.loadAllArticlesWithEngagement();
    if (localArticles.isNotEmpty && mounted) {
      setState(() {
        _allArticles = localArticles;
        _isLoading = false;
      });
    }

    // 2. Try to sync from API silently
    try {
      final res = await _api.get('/articles', silent: true);
      if (res is List) {
        final live = res.map((e) => ArticleModel.fromJson(e as Map<String, dynamic>)).toList();
        final merged = ArticlesData.mergeWithDefaults([...localArticles, ...live]);
        if (mounted) {
          setState(() {
            _allArticles = merged;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    _loadBookmarks();
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

  Future<void> _loadBookmarks() async {
    try {
      final ids = await ArticlesStorageService.getBookmarkedArticleIds();
      if (mounted) setState(() => _bookmarkedIds = ids);
    } catch (_) {}
  }

  Future<void> _toggleBookmark(String articleId) async {
    HapticService.lightTap();
    final isSaved = await ArticlesStorageService.toggleBookmark(articleId);
    if (mounted) {
      setState(() {
        if (isSaved) {
          if (!_bookmarkedIds.contains(articleId)) _bookmarkedIds.add(articleId);
        } else {
          _bookmarkedIds.remove(articleId);
        }
      });
    }
  }

  Future<void> _openArticle(ArticleModel article) async {
    HapticService.lightTap();
    await Navigator.of(context).push(slideRoute(ArticleDetailScreen(article: article)));
    if (mounted) {
      _fetchLiveArticles();
      _loadRecentlyRead();
      _loadBookmarks();
    }
  }

  List<ArticleModel> get _filteredArticles {
    final isSavedView = _selectedCategoryIndex == 1;
    final category = _categories[_selectedCategoryIndex];

    return _allArticles.where((article) {
      if (isSavedView) {
        if (!_bookmarkedIds.contains(article.id)) return false;
      } else {
        if (article.isFeatured && _selectedCategoryIndex == 0 && _searchQuery.isEmpty) return false;
        final matchesCategory = category == 'All' || article.category == category;
        if (!matchesCategory) return false;
      }
      final matchesQuery = _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.author.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesQuery;
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
      onTap: () => _openArticle(article),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(40), width: 1),
          boxShadow: [
            BoxShadow(
              color: KausapColors.accentShadow(context),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ArticleCoverImage(
                imageUrl: article.imageUrl,
                category: article.category,
                themeColor: article.themeColor,
                categoryIcon: article.categoryIcon,
                height: 180,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(190),
                      Colors.black.withAlpha(90),
                      article.themeColor.withAlpha(160),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(80)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✨', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              'Featured Guide',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(70)),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        article.readTime,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54)),
                      const SizedBox(width: 8),
                      Text(
                        article.author,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 13, color: KausapColors.accent(context)),
                            const SizedBox(width: 5),
                            Text(
                              'Read Now',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: KausapColors.accent(context),
                              ),
                            ),
                          ],
                        ),
                      ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Read',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: KausapColors.textPrimary(context)),
            ),
            Text(
              '${_recentlyRead.length} items',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w500, color: KausapColors.textMuted(context)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentlyRead.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = _recentlyRead[i];
              return GestureDetector(
                onTap: () => _openArticle(a),
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KausapColors.cardBg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KausapColors.border(context), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: KausapColors.accentShadow(context),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: a.themeColor.withAlpha(22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: a.themeColor.withAlpha(50), width: 0.8),
                            ),
                            child: Icon(a.categoryIcon, size: 12, color: a.themeColor),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              a.category.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: a.themeColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: KausapColors.textPrimary(context),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
      backgroundColor: KausapColors.scaffoldBg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    GestureDetector(
                      onTap: () {
                        HapticService.lightTap();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KausapColors.cardBg(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: KausapColors.textPrimary(context)),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: KausapColors.accent(context),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: KausapColors.accentShadow(context),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.article_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mental Wellness Articles',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: KausapColors.textPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Psychoeducation & Student Factsheets',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: KausapColors.textMuted(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: KausapColors.accent(context)),
                      ),
                    ),
                  // Bookmarks action button with badge
                  GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      setState(() {
                        _selectedCategoryIndex = (_selectedCategoryIndex == 1) ? 0 : 1;
                      });
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 1 ? const Color(0xFFFEF3C7) : KausapColors.cardBg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedCategoryIndex == 1 ? const Color(0xFFF59E0B) : KausapColors.border(context),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _selectedCategoryIndex == 1 ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 19,
                            color: _selectedCategoryIndex == 1 ? const Color(0xFFD97706) : KausapColors.textMuted(context),
                          ),
                          if (_bookmarkedIds.isNotEmpty)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                        backgroundColor: KausapColors.accent(context).withAlpha(30),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                            ? Text(
                                initial,
                                style: AppTextStyles.label.copyWith(
                                    color: KausapColors.accent(context), fontWeight: FontWeight.w700, fontSize: 11),
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
                                  backgroundColor: KausapColors.accent(context).withAlpha(20),
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                                      ? Text(initial,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KausapColors.accent(context)))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('View Profile & Settings', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: KausapColors.textMuted(context))),
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
                decoration: BoxDecoration(
                  color: KausapColors.cardBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KausapColors.border(context), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: KausapColors.accentShadow(context),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: KausapColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Search articles, mental health guides...',
                    hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: KausapColors.textHint(context)),
                    prefixIcon: Icon(Icons.search_rounded, color: KausapColors.textHint(context), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: KausapColors.textHint(context)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Category Chips Bar (Consistent with Activity Page)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedCategoryIndex;
                  final categoryName = _categories[index];
                  final isBookmarkChip = index == 1;

                  return Semantics(
                    label: '$categoryName category filter chip${isSelected ? ', currently active' : ''}',
                    button: true,
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () {
                        HapticService.lightTap();
                        setState(() => _selectedCategoryIndex = index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isBookmarkChip ? const Color(0xFFFEF3C7) : KausapColors.pastelSkyBg(context))
                              : KausapColors.cardBg(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isBookmarkChip ? const Color(0xFFF59E0B) : KausapColors.accent(context))
                                : KausapColors.border(context),
                            width: isSelected ? 1.2 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (isBookmarkChip ? const Color(0xFFD97706) : KausapColors.accent(context))
                                    : KausapColors.textMuted(context),
                              ),
                            ),
                            if (isBookmarkChip && _bookmarkedIds.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_bookmarkedIds.length}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                color: KausapColors.accent(context),
                child: filtered.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedCategoryIndex == 1 ? '🔖' : '🔍',
                                    style: const TextStyle(fontSize: 44),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedCategoryIndex == 1
                                        ? 'No saved articles yet'
                                        : 'No articles found',
                                    style: AppTextStyles.heading2.copyWith(fontSize: 16, color: KausapColors.textPrimary(context)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedCategoryIndex == 1
                                        ? 'Tap the bookmark icon 🔖 on any article to save it for offline reading anytime.'
                                        : 'Try a different keyword or category.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(
                                      color: KausapColors.textMuted(context),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (_selectedCategoryIndex == 1) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        HapticService.lightTap();
                                        setState(() => _selectedCategoryIndex = 0);
                                      },
                                      icon: const Icon(Icons.explore_rounded, size: 16),
                                      label: const Text('Explore Articles', style: TextStyle(fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: KausapColors.accent(context),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: filtered.length +
                            (_featuredArticle != null ? 1 : 0) +
                            (_recentlyRead.isNotEmpty && _selectedCategoryIndex == 0 && _searchQuery.isEmpty ? 1 : 0) +
                            1,
                        itemBuilder: (context, index) {
                          final hasFeatured = _featuredArticle != null;
                          final hasRecent = _recentlyRead.isNotEmpty && _selectedCategoryIndex == 0 && _searchQuery.isEmpty;
                          final headerIndex = (hasFeatured ? 1 : 0) + (hasRecent ? 1 : 0);

                          // Featured Hero
                          if (hasFeatured && index == 0) {
                            return Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildFeaturedHeroCard(_featuredArticle!));
                          }

                          // Recently Read
                          final recentIndex = hasFeatured ? 1 : 0;
                          if (hasRecent && index == recentIndex) {
                            return Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildRecentlyReadSection());
                          }

                          // Section Header (Matching Activity screen)
                          if (index == headerIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedCategoryIndex == 1
                                        ? 'Saved Factsheets'
                                        : (_searchQuery.isNotEmpty ? 'Search Results' : 'All Factsheets & Guides'),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: KausapColors.textPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    '${filtered.length} articles',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: KausapColors.textMuted(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final articleIndex = index - (headerIndex + 1);
                          final article = filtered[articleIndex];
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

  Widget _buildNeutralTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: KausapColors.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: KausapColors.isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: KausapColors.isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    final isSaved = _bookmarkedIds.contains(article.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: KausapColors.accentShadow(context),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openArticle(article),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Cover Image with Floating Category & Bookmark Action ──
              Stack(
                children: [
                  ArticleCoverImage(
                    imageUrl: article.imageUrl,
                    category: article.category,
                    themeColor: article.themeColor,
                    categoryIcon: article.categoryIcon,
                    height: 125,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  // Gradient scrim overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withAlpha(75),
                            Colors.transparent,
                            Colors.black.withAlpha(40),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Floating category badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(235),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black.withAlpha(15), width: 0.8),
                        boxShadow: const [
                          BoxShadow(color: Color(0x15000000), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(article.categoryIcon, size: 12, color: article.themeColor),
                          const SizedBox(width: 4),
                          Text(
                            article.category.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: article.themeColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bookmark & Read time on top right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.readTime,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleBookmark(article.id),
                          child: Container(
                            padding: const EdgeInsets.all(4.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(235),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Color(0x15000000), blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: isSaved ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Card Content Body ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: KausapColors.textPrimary(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      article.subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: KausapColors.textMuted(context),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Tag Chips — Unified clean neutral light slate pills (matching Activity screen)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildNeutralTag(context, article.category),
                        _buildNeutralTag(context, article.readTime),
                        if (article.authorRole.isNotEmpty)
                          _buildNeutralTag(context, article.authorRole),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bottom Row: Author + Action Button (matching Activity screen pill)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: article.themeColor.withAlpha(25),
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
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: KausapColors.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: KausapColors.accentSubtle(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: KausapColors.accent(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Read',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: KausapColors.accent(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
