import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/articles_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import '../chat/chatbot_screen.dart';
import 'articles_data.dart';

// ─ Recently-read key
const String _kRecentlyReadKey = 'recently_read_article_ids';

// ── Reaction model ──────────────────────────────────────────────────────────
class _Reaction {
  final String emoji;
  final String label;
  final Color color;
  const _Reaction(this.emoji, this.label, this.color);
}

const List<_Reaction> _reactions = [
  _Reaction('💡', 'Insightful', Color(0xFFD97706)),
  _Reaction('❤️', 'Helpful', Color(0xFFE11D48)),
  _Reaction('🌿', 'Calming', Color(0xFF059669)),
  _Reaction('👏', 'Inspiring', Color(0xFF7C3AED)),
  _Reaction('😢', 'Touched', Color(0xFF0284C7)),
  _Reaction('😮', 'Amazing', Color(0xFFEA580C)),
  _Reaction('🤗', 'Comforting', Color(0xFFF59E0B)),
  _Reaction('💪', 'Empowering', Color(0xFF0D9488)),
];

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;
  final bool isPreview;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    this.isPreview = false,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> with TickerProviderStateMixin {
  bool _isBookmarked = false;
  double _readProgress = 0.0;
  final ScrollController _scrollCtrl = ScrollController();

  /// Map of reaction index -> count
  Map<int, int> _reactionCounts = {};

  /// Index of user's chosen reaction (null = none)
  int? _myReaction;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
    _loadReactions();
    if (!widget.isPreview) {
      _saveRecentlyRead();
      _recordView();
    }
    _scrollCtrl.addListener(_onScroll);
  }

  Future<void> _recordView() async {
    // Record view in local persistent storage
    await ArticlesStorageService.recordView(widget.article.id);
    // Sync with backend silently in background
    ApiClient().get('/articles/${widget.article.id}', silent: true).catchError((_) => null);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() > 0.01) {
      setState(() => _readProgress = progress);
    }
  }

  Future<void> _saveRecentlyRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kRecentlyReadKey) ?? [];
      final updated = [widget.article.id, ...raw.where((id) => id != widget.article.id)].take(5).toList();
      await prefs.setStringList(_kRecentlyReadKey, updated);
    } catch (_) {}
  }

  String get _myReactionKey => 'article_my_reaction_${widget.article.id}';

  Future<void> _loadReactions() async {
    // 1. Fetch latest article with engagement from storage
    final enriched = await ArticlesStorageService.attachEngagement(widget.article);
    final prefs = await SharedPreferences.getInstance();
    final myR = prefs.getInt(_myReactionKey);

    final Map<int, int> countsByIndex = {};
    for (int i = 0; i < _reactions.length; i++) {
      final emoji = _reactions[i].emoji;
      final count = enriched.reactionCounts[emoji] ?? 0;
      if (count > 0) {
        countsByIndex[i] = count;
      }
    }

    if (mounted) {
      setState(() {
        _reactionCounts = countsByIndex;
        _myReaction = myR;
      });
    }
  }

  void _toggleReaction(int index) async {
    HapticService.lightTap();

    // ── Preview Mode Check ──
    if (widget.isPreview) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👁️ Reactions are disabled in Preview mode.'),
          backgroundColor: Color(0xFF0F172A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final emoji = _reactions[index].emoji;
    final String? previousEmoji = _myReaction != null ? _reactions[_myReaction!].emoji : null;

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (_myReaction == index) {
        // Remove my reaction
        _reactionCounts[index] = (_reactionCounts[index] ?? 1) - 1;
        if (_reactionCounts[index]! <= 0) _reactionCounts.remove(index);
        _myReaction = null;
        prefs.remove(_myReactionKey);

        // Record to local storage
        ArticlesStorageService.recordReaction(widget.article.id, emoji, false);
      } else {
        // Remove old reaction if any
        if (_myReaction != null) {
          _reactionCounts[_myReaction!] = (_reactionCounts[_myReaction!] ?? 1) - 1;
          if (_reactionCounts[_myReaction!]! <= 0) _reactionCounts.remove(_myReaction!);
        }
        // Add new reaction
        _reactionCounts[index] = (_reactionCounts[index] ?? 0) + 1;
        _myReaction = index;
        prefs.setInt(_myReactionKey, index);
        _bounceController.forward(from: 0);

        // Record to local persistent storage
        ArticlesStorageService.recordReaction(widget.article.id, emoji, true, previousEmoji);

        // Sync with backend API silently in background
        ApiClient().post('/articles/${widget.article.id}/react', body: {
          'emoji': emoji,
          'label': _reactions[index].label,
        }, silent: true).catchError((_) => null);
      }
    });
  }

  void _showShareSheet() {
    HapticService.lightTap();
    final article = widget.article;
    final shareUrl = 'https://kausap-ai.web.app/articles?id=${article.id}';
    final shareText = '${article.title}\n${article.subtitle}\n\nRead on Kausap AI Mental Wellness App:\n$shareUrl';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Share this Article',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                if (widget.isPreview) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Preview', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '"${article.title}"',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption('📋', 'Copy Link', const Color(0xFF0F172A), () async {
                  Navigator.pop(ctx);
                  if (!widget.isPreview) {
                    await ArticlesStorageService.recordShare(article.id);
                  }
                  Clipboard.setData(ClipboardData(text: shareText));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isPreview ? '🔗 Article link copied to clipboard! (Preview mode)' : '🔗 Article link copied to clipboard! Share recorded ✓'),
                        backgroundColor: const Color(0xFF0F172A),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }),
                _shareOption('📘', 'Facebook', const Color(0xFF1877F2), () async {
                  Navigator.pop(ctx);
                  if (!widget.isPreview) {
                    await ArticlesStorageService.recordShare(article.id);
                  }
                  final encoded = Uri.encodeComponent(shareText);
                  final url = 'https://www.facebook.com/sharer/sharer.php?quote=$encoded';
                  Clipboard.setData(ClipboardData(text: url));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isPreview ? '📘 Facebook share link copied! (Preview mode)' : '📘 Facebook share link copied! Share recorded ✓'),
                        backgroundColor: const Color(0xFF1877F2),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }),
                _shareOption('💬', 'Messenger', const Color(0xFF00B2FF), () async {
                  Navigator.pop(ctx);
                  if (!widget.isPreview) {
                    await ArticlesStorageService.recordShare(article.id);
                  }
                  Clipboard.setData(ClipboardData(text: shareText));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isPreview ? '💬 Messenger text copied! (Preview mode)' : '💬 Messenger text copied! Share recorded ✓'),
                        backgroundColor: const Color(0xFF00B2FF),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(String emoji, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
          // Header App Bar with Hero Image / Gradient Banner
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: article.themeColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            actions: [
              // Share button
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: _showShareSheet,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
              // Bookmark button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    setState(() => _isBookmarked = !_isBookmarked);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isBookmarked ? 'Article bookmarked! 🔖' : 'Bookmark removed'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: article.themeColor,
                      ),
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ArticleCoverImage(
                    imageUrl: article.imageUrl,
                    category: article.category,
                    themeColor: article.themeColor,
                    categoryIcon: article.categoryIcon,
                    height: 230,
                  ),
                  // Dark Vignette Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(article.categoryIcon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  article.category,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.readTime,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Article Body
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                Text(
                  article.title,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  article.subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Author card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x1AC0C9C2)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: article.themeColor.withValues(alpha: 0.15),
                        child: Text(
                          article.author.isNotEmpty ? article.author[0] : 'K',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: article.themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.author,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              article.authorRole,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sections
                ...article.sections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.heading,
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.content,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.65,
                          ),
                        ),
                        if (section.keyPoints != null && section.keyPoints!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: article.themeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: article.themeColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: section.keyPoints!.map((point) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '•  ',
                                        style: TextStyle(
                                          color: article.themeColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            color: Color(0xFF1F2937),
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 4),

                // ── Emoji Reactions Bar ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'How did this article make you feel?',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ),
                          if (widget.isPreview)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 11, color: Color(0xFF64748B)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Preview Mode',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_reactions.length, (i) {
                          final r = _reactions[i];
                          final isSelected = _myReaction == i;
                          final count = _reactionCounts[i] ?? 0;
                          return AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (ctx, child) {
                              final scale = (isSelected && _bounceController.isAnimating)
                                  ? _bounceAnimation.value
                                  : 1.0;
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: Semantics(
                              label: 'React with ${r.label} emoji ${r.emoji}.${count > 0 ? ' $count students reacted.' : ''}${isSelected ? ' Currently selected.' : ''}',
                              button: true,
                              selected: isSelected,
                              child: GestureDetector(
                                onTap: () => _toggleReaction(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? r.color.withAlpha(25) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? r.color : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(r.emoji, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Text(
                                        r.label,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? r.color : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (count > 0) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected ? r.color : const Color(0xFFCBD5E1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$count',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? Colors.white : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Discuss with Kausap AI ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A0077B6), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        'Want to explore this with Kausap AI?',
                        style: AppTextStyles.heading2.copyWith(fontSize: 15, color: const Color(0xFF0F172A)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Our confidential CBT companion can guide you through tailored exercises and personal coping strategies.',
                        style: TextStyle(fontFamily: 'Inter', color: Color(0xFF475569), fontSize: 12, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  HapticService.mediumTap();
                                  if (widget.isPreview) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Row(
                                          children: [
                                            Icon(Icons.remove_red_eye_rounded, color: Color(0xFF0284C7)),
                                            SizedBox(width: 8),
                                            Text('Preview Mode', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                        content: Text(
                                          'In the student app, tapping this button connects the student with Kausap AI to discuss "${article.title}" and generate personalized coping strategies.\n\nWould you like to test the chatbot discussion flow?',
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Close Preview', style: TextStyle(color: Color(0xFF64748B))),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => ChatbotScreen(
                                                    initialMessage:
                                                        "I just read an article titled \"${article.title}\". ${article.subtitle} Can we discuss how to apply these techniques in my daily life?",
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                                            child: const Text('Test AI Chat'),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  await ArticlesStorageService.recordAiDiscussion(article.id);
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatbotScreen(
                                          initialMessage:
                                              "I just read an article titled \"${article.title}\". ${article.subtitle} Can we discuss how to apply these techniques in my daily life?",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                                label: const Text(
                                  'Discuss with Kausap AI 💬',
                                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 44,
                            width: 44,
                            child: ElevatedButton(
                              onPressed: _showShareSheet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0284C7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Icon(Icons.share_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      // Reading progress bar pinned at top
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: LinearProgressIndicator(
            value: _readProgress,
            backgroundColor: Colors.transparent,
            color: widget.article.themeColor.withAlpha(180),
            minHeight: 3,
          ),
        ),
      ),
      // Preview Floating Banner
      if (widget.isPreview)
        Positioned(
          bottom: 16,
          left: 20,
          right: 20,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Preview Mode (Read-Only)',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Exit Preview', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  ),
);
}
}

