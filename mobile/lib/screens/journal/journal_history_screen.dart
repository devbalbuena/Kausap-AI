import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  static const _storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> loaded = [];

    try {
      final raw = await _storage.read(key: 'journal_history');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            loaded.add(item);
          }
        }
      }

      // Also check standard journal_YYYY-MM-DD keys for any legacy or single-day entries
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('journal_') && key != 'journal_history') {
          final dateStr = key.replaceFirst('journal_', '');
          final content = allKeys[key];
          if (content != null && content.isNotEmpty) {
            final alreadyInList = loaded.any((e) => e['date'] == dateStr);
            if (!alreadyInList) {
              loaded.add({
                'id': dateStr,
                'date': dateStr,
                'type': content.contains('Gratitude Reflection') ? 'guided' : 'freeform',
                'content': content,
                'mood': allKeys['mood_$dateStr'] ?? '5',
                'created_at': dateStr,
              });
            }
          }
        }
      }

      // Sort newest to oldest
      loaded.sort((a, b) {
        final dateA = a['date'] as String? ?? '';
        final dateB = b['date'] as String? ?? '';
        return dateB.compareTo(dateA);
      });
    } catch (_) {}

    if (mounted) {
      setState(() {
        _entries = loaded;
        _isLoading = false;
      });
    }
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  void _showEntryDetail(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDisplayDate(entry['date'] ?? ''),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (entry['type'] ?? 'freeform').toString().toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  entry['content'] ?? 'No entry content',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Color(0xFF334155),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Journal History',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Journal Entries Yet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your daily reflections and gratitude entries will show here.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _entries.length,
                  itemBuilder: (context, idx) {
                    final entry = _entries[idx];
                    final dateStr = entry['date'] ?? '';
                    final content = entry['content'] ?? '';
                    final isGuided = entry['type'] == 'guided';

                    return GestureDetector(
                      onTap: () => _showEntryDetail(entry),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(isGuided ? '☀️' : '✍️', style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDisplayDate(dateStr),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
