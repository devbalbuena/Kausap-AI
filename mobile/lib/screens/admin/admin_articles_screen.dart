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
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Always load locally stored articles first (offline-first)
    final localArticles = await ArticlesStorageService.loadLocalArticles();

    // Try syncing from API in background; fall back silently if unavailable
    List<ArticleModel> mergedList = localArticles;
    try {
      final res = await _api.get('/admin/articles');
      if (res is List) {
        final List<ArticleModel> apiList = res
            .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
            .toList();
        // Merge: API articles + any local-only articles not on server yet
        final apiIds = apiList.map((a) => a.id).toSet();
        final localOnly = localArticles.where((a) => !apiIds.contains(a.id)).toList();
        mergedList = [...localOnly, ...apiList];
      }
    } catch (_) {
      // Backend not yet deployed / offline — use local storage only, no error shown
    }

    if (mounted) {
      setState(() {
        _articles = mergedList;
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 8),
                              const Text('Articles loaded from local storage', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B))),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchArticles,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
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
                                    'No dynamic articles published yet',
                                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap "+ New Article" below to post your first article with images.',
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

  Widget _buildAdminArticleCard(ArticleModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a)),
            );
          },
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
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: a.themeColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            a.readTime,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '✍️ ${a.author}',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF0284C7)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _openArticleEditor(a),
                          ),
                          const SizedBox(width: 14),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteArticle(a.id),
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
  String? _imageUrl;
  bool _isSaving = false;

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
      'is_published': true,
    };

    // ── Save locally FIRST (always works, even offline) ──
    final localJson = {
      ...payload,
      'id': widget.existingArticle?.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      'author_role': _authorRoleController.text.trim().isEmpty ? 'Counselor' : _authorRoleController.text.trim(),
      'sections': sections.map((s) => s.toJson()).toList(),
    };
    await ArticlesStorageService.saveArticle(localJson);

    // ── Try syncing to backend in background (non-blocking) ──
    _api.post('/admin/articles', body: payload).catchError((_) => null);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                      widget.existingArticle != null ? 'Edit Article' : 'Publish Psychoeducation Article',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Form
          Expanded(
            child: ListView(
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

                // Category Selector
                const Text('Category', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Inter', fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
