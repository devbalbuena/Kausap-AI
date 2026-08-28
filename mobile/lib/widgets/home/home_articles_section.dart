import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../screens/articles/articles_data.dart';
import '../../screens/articles/article_detail_screen.dart';

class HomeArticlesSection extends StatelessWidget {
  final List<ArticleModel> homeArticles;
  final int? todayMoodLevel;
  final VoidCallback onSeeAllTap;

  const HomeArticlesSection({
    super.key,
    required this.homeArticles,
    required this.todayMoodLevel,
    required this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter only published articles
    final published = homeArticles.where((a) => a.isPublished && a.status == 'published').toList();

    // Mood-based recommendation categories
    List<String> targetCategories = [];
    String subtitleText = 'Curated reads for your mental wellness';
    if (todayMoodLevel != null) {
      if (todayMoodLevel! <= 1) {
        targetCategories = ['Crisis Prevention', 'Anxiety & Coping'];
        subtitleText = '🌿 Recommended reads for caring support today';
      } else if (todayMoodLevel! == 2) {
        targetCategories = ['Anxiety & Coping', 'Student Burnout', 'Mental Awareness'];
        subtitleText = '🌿 Recommended reads to help you unwind';
      } else if (todayMoodLevel! == 3) {
        targetCategories = ['Campus Wellness', 'Mental Awareness', 'Family & Relations'];
        subtitleText = '🌱 Insightful reads for reflection & growth';
      } else {
        subtitleText = '✨ Inspiring reads to sustain your positive mindset';
      }
    }

    // Sort: Featured first, then matching mood categories, then others
    final sorted = List<ArticleModel>.from(published)..sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      if (targetCategories.isNotEmpty) {
        final aMatch = targetCategories.contains(a.category);
        final bMatch = targetCategories.contains(b.category);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
      }
      return 0;
    });

    final previewArticles = sorted.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Articles & Insights', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
              ],
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: const Text(
                'See All',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitleText, style: AppTextStyles.subheading),
        const SizedBox(height: 12),
        SizedBox(
          height: 222,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewArticles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final article = previewArticles[index];
              final isMoodRec = targetCategories.contains(article.category);
              return GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).push(slideRoute(ArticleDetailScreen(article: article)));
                },
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: article.isFeatured
                          ? const Color(0xFFF59E0B)
                          : isMoodRec
                              ? article.themeColor.withAlpha(80)
                              : const Color(0x1AC0C9C2),
                      width: article.isFeatured ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Cover Image Banner with Overlays
                      Stack(
                        children: [
                          ArticleCoverImage(
                            imageUrl: article.imageUrl,
                            category: article.category,
                            themeColor: article.themeColor,
                            categoryIcon: article.categoryIcon,
                            height: 98,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          // Dark gradient overlay for readable tags
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0x55000000),
                                    Colors.transparent,
                                    Color(0x33000000),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Category Chip on top left
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(235),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(article.categoryIcon, size: 10.5, color: article.themeColor),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    article.category,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: article.themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Badge on top right (Featured / For You / Read time)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: article.isFeatured
                                    ? const Color(0xFFF59E0B)
                                    : Colors.black.withAlpha(150),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                article.isFeatured
                                    ? '📌 Featured'
                                    : isMoodRec
                                        ? '🌿 For You'
                                        : article.readTime,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Body & Title
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: article.themeColor.withAlpha(30),
                                    child: Text(
                                      article.author.isNotEmpty ? article.author[0] : 'C',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: article.themeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      article.author,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Color(0xFF4B5563),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ],
                          ),
                        ),
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
}
