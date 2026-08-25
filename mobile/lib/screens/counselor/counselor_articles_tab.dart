import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/articles_storage_service.dart';
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
  String _selectedCategoryFilter = 'All';

  final List<String> _categories = ArticlesData.categories;

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

  Future<void> _deleteArticle(ArticleModel article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Delete Article",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          "Are you sure you want to delete '${article.title}'? Students will no longer be able to access it.",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
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
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.lightTap();
      await ArticlesStorageService.deleteArticle(article.id);
      try {
        await _api.delete('/admin/articles/${article.id}', silent: true);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Article '${article.title}' deleted."),
          backgroundColor: const Color(0xFF16A34A),
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

    final categories = _categories.where((c) => c != 'All').toList();

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

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((a) {
      if (_selectedCategoryFilter != 'All' && a.category != _selectedCategoryFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.title.toLowerCase().contains(q) || a.category.toLowerCase().contains(q) || a.subtitle.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Search & New Article Bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search articles by title or keyword...",
                        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openArticleEditor(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("New Guide", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Category Horizontal Filter Chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final selected = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategoryFilter = cat);
                        },
                        selectedColor: const Color(0xFFE0F2FE),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                        side: BorderSide(color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                      ),
                    );
                  }).toList(),
                ),
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
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final art = filtered[i];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: art)),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          art.category,
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                            onPressed: () => _openArticleEditor(art),
                                            tooltip: "Edit",
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                            onPressed: () => _deleteArticle(art),
                                            tooltip: "Delete",
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            art.readTime,
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    art.title,
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    art.subtitle,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "By: ${art.author}",
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text("${art.viewCount}", style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.share_outlined, size: 14, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 4),
                                          Text("${art.shareCount}", style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
