import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/articles_storage_service.dart';
import '../../services/clinical_audit_service.dart';
import '../../utils/haptic_service.dart';
import '../articles/articles_data.dart';
import '../articles/article_detail_screen.dart';

class CounselorArticlesTab extends StatefulWidget {
  const CounselorArticlesTab({super.key});

  @override
  State<CounselorArticlesTab> createState() => _CounselorArticlesTabState();
}

class _CounselorArticlesTabState extends State<CounselorArticlesTab> {
  final ApiClient _api = ApiClient();
  List<ArticleModel> _articles = ArticlesData.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchArticles() async {
    try {
      final allArticles = await ArticlesStorageService.loadAllArticlesWithEngagement();
      if (mounted) {
        setState(() {
          _articles = allArticles.isNotEmpty ? allArticles : ArticlesData.all;
        });
      }

      final res = await _api.get('/admin/articles', silent: true);
      if (res is List) {
        final apiArticles = res.map((item) => ArticleModel.fromJson(item as Map<String, dynamic>)).toList();
        final ids = apiArticles.map((a) => a.id).toSet();
        final merged = [...apiArticles, ..._articles.where((a) => !ids.contains(a.id))];
        if (mounted) {
          setState(() {
            _articles = merged;
          });
        }
      }
    } catch (_) {
      if (mounted && _articles.isEmpty) {
        setState(() {
          _articles = ArticlesData.all;
        });
      }
    }
  }

  Future<void> _toggleFeatured(ArticleModel a) async {
    HapticService.lightTap();
    final updated = a.copyWith(isFeatured: !a.isFeatured);
    await ArticlesStorageService.saveArticle(updated.toJson());
    try {
      await _api.put('/admin/articles/${a.id}', body: {'is_featured': updated.isFeatured}, silent: true);
    } catch (_) {}
    _fetchArticles();
  }

  Future<void> _deleteArticle(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Delete Article",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          "Are you sure you want to delete this guidance article? Students will no longer be able to access it.",
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.lightTap();
      await ClinicalAuditService.recordLog(
        action: 'article_deleted',
        targetType: 'Psychoeducation Article',
        targetId: id,
        detail: 'Deleted psychoeducation article with ID $id.',
      );
      await ArticlesStorageService.deleteArticle(id);
      try {
        await _api.delete('/admin/articles/$id', silent: true);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Article deleted successfully."),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _fetchArticles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete article: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _showEngagementDrawer(ArticleModel a) {
    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (a.isFeatured)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('📌 Featured', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text("By: ${a.author} • ${a.authorRole}", style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
              const Divider(height: 24),

              // Button to Preview as Student
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a, isPreview: true)),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                  label: const Text('View Full Student Experience 📖', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
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
                ('💡', 'Insightful'),
                ('❤️', 'Helpful'),
                ('🌿', 'Calming'),
                ('👏', 'Inspiring'),
                ('😢', 'Touched'),
                ('😮', 'Amazing'),
                ('🤗', 'Comforting'),
                ('💪', 'Empowering'),
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
              if (a.isBuiltIn) ...[
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
                          'This is a built-in institutional article. Tap "+ New Article" to author custom guidance resources.',
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

  void _openArticleEditor([ArticleModel? article]) {
    final isNew = article == null;
    final titleCtrl = TextEditingController(text: article?.title ?? '');
    final subtitleCtrl = TextEditingController(text: article?.subtitle ?? '');
    final headingCtrl = TextEditingController(text: article?.sections.isNotEmpty == true ? article!.sections.first.heading : 'Key Insights');
    final bodyCtrl = TextEditingController(text: article?.sections.isNotEmpty == true ? article!.sections.first.content : '');
    final pointsCtrl = TextEditingController(text: article?.sections.isNotEmpty == true && article!.sections.first.keyPoints != null ? article.sections.first.keyPoints!.join('\n') : '');
    final authorCtrl = TextEditingController(text: article?.author ?? 'FSUU Guidance Center');
    String category = article?.category ?? 'Student Burnout';
    String readTime = article?.readTime ?? '4 min read';
    String? base64Image = article?.imageUrl;

    final categories = ArticlesData.categories.where((c) => c != 'All').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNew ? "Create Psychoeducation Guide" : "Edit Article",
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: "Article Title *",
                    hintText: "e.g. 5 Grounding Techniques for Exam Stress",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: "Subtitle / Tagline *",
                    hintText: "A brief summary for Urian students",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categories.contains(category) ? category : categories.first,
                  decoration: InputDecoration(
                    labelText: "Category *",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: authorCtrl,
                        decoration: InputDecoration(
                          labelText: "Author Name *",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: readTime),
                        onChanged: (val) => readTime = val,
                        decoration: InputDecoration(
                          labelText: "Read Time",
                          hintText: "e.g. 3 min read",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: headingCtrl,
                  decoration: InputDecoration(
                    labelText: "Section Heading",
                    hintText: "e.g. Recognizing Emotional Overwhelm",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: "Main Guidance Content *",
                    hintText: "Write evidence-based guidance notes and recommendations...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Key Takeaways (one per line)",
                    hintText: "Take deep belly breaths\nReach out to a counselor...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                // ── Image Picker ──
                InkWell(
                  onTap: () async {
                    HapticService.lightTap();
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setModalState(() {
                        base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, color: Color(0xFF0284C7), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            base64Image != null ? "Cover Image Attached ✓" : "Upload Article Cover Image (Optional)",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: base64Image != null ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              fontWeight: base64Image != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (base64Image != null)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final subtitle = subtitleCtrl.text.trim();
                      final heading = headingCtrl.text.trim();
                      final body = bodyCtrl.text.trim();
                      final author = authorCtrl.text.trim();

                      if (title.isEmpty || subtitle.isEmpty || body.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill in Title, Subtitle, and Main Content body."),
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                        return;
                      }

                      final rawPoints = pointsCtrl.text
                          .split('\n')
                          .map((p) => p.trim())
                          .where((p) => p.isNotEmpty)
                          .toList();

                      final sections = [
                        ArticleSection(
                          heading: heading.isNotEmpty ? heading : 'Key Insights',
                          content: body,
                          keyPoints: rawPoints.isNotEmpty ? rawPoints : null,
                        ),
                      ];

                      final localJson = {
                        'id': article?.id ?? 'counselor_${DateTime.now().millisecondsSinceEpoch}',
                        'title': title,
                        'subtitle': subtitle,
                        'category': category,
                        'status': 'published',
                        'read_time': readTime,
                        'author': author.isNotEmpty ? author : 'FSUU Guidance Center',
                        'author_role': 'Guidance Counselor',
                        'image_url': base64Image,
                        'theme_color_hex': '#0284C7',
                        'content_json': jsonEncode(sections.map((s) => s.toJson()).toList()),
                        'is_published': true,
                        'sections': sections.map((s) => s.toJson()).toList(),
                      };

                      Navigator.pop(ctx);
                      await ClinicalAuditService.recordLog(
                        action: article != null ? 'article_updated' : 'article_published',
                        targetType: 'Psychoeducation Article',
                        targetId: localJson['id'].toString(),
                        detail: '${article != null ? 'Updated' : 'Published'} psychoeducation article "$title" in category $category.',
                      );
                      await ArticlesStorageService.saveArticle(localJson);
                      try {
                        await _api.post('/admin/articles', body: localJson, silent: true);
                      } catch (_) {}

                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text("Article '$title' published successfully!"),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                      _fetchArticles();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isNew ? "Publish Psychoeducation Guide" : "Save Changes",
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel a) {
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
          color: a.isFeatured ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
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
                // Cover Thumbnail / Icon Box
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
                            child: Text(
                              a.category,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: a.themeColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ),
                          if (a.isFeatured) ...[const SizedBox(width: 4), const Text('📌', style: TextStyle(fontSize: 12))],
                          const Spacer(),
                          Text(a.readTime, style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.subtitle,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                          Text(
                            '${a.viewCount}',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          const Spacer(),
                          // Preview Button
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
                                  Text(
                                    'Preview',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!a.isBuiltIn) ...[
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
                          ] else ...[
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

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.title.toLowerCase().contains(q) || a.category.toLowerCase().contains(q) || a.subtitle.toLowerCase().contains(q) || a.author.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final publishedCount = _articles.where((a) => a.status == 'published' && !a.isBuiltIn).length;
    final draftsCount = _articles.where((a) => a.status == 'draft').length;
    final archivedCount = _articles.where((a) => a.status == 'archived').length;
    final builtInCount = _articles.where((a) => a.isBuiltIn).length;

    return Stack(
      children: [
        Column(
          children: [
            // ── Search & Metrics Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search articles by title, category, author...",
                      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Status Chips ──
                  Row(
                    children: [
                      _statChip('$publishedCount', 'Published', const Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      _statChip('$draftsCount', 'Drafts', const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _statChip('$archivedCount', 'Archived', const Color(0xFF94A3B8)),
                      const Spacer(),
                      _statChip('$builtInCount', 'Built-in', const Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Articles List ──
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text("No articles found matching criteria.", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B))),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchArticles,
                      color: const Color(0xFF0284C7),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final art = filtered[i];
                          return _buildArticleCard(art);
                        },
                      ),
                    ),
            ),
          ],
        ),

        // ── Floating Action Button: New Article ──
        Positioned(
          bottom: 16,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: () => _openArticleEditor(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              "New Article",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              shadowColor: const Color(0x400284C7),
            ),
          ),
        ),
      ],
    );
  }
}
