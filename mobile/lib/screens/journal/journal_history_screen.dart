import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../utils/haptic_service.dart';
import 'daily_journal_screen.dart';

class JournalHistoryScreen extends StatefulWidget {
  final bool fromDailyJournal;

  const JournalHistoryScreen({super.key, this.fromDailyJournal = false});

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
    bool apiSuccess = false;

    try {
      // 1. Try fetching from cloud backend API (authoritative source of truth)
      try {
        final remote = await ApiClient().get(ApiConfig.journal, silent: true);
        if (remote is List) {
          apiSuccess = true;
          for (final item in remote) {
            if (item is Map) {
              loaded.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (e) {
        debugPrint('Remote journal fetch failed, falling back to local storage: $e');
      }

      if (apiSuccess) {
        // When cloud API succeeds, update local cache with authoritative server list
        await _storage.write(key: 'journal_history', value: jsonEncode(loaded));
      } else {
        // Offline Fallback: Only read from local storage if API was unreachable
        final raw = await _storage.read(key: 'journal_history');
        if (raw != null && raw.isNotEmpty) {
          final List<dynamic> list = jsonDecode(raw);
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              loaded.add(item);
            }
          }
        }
      }

      // Sort newest to oldest
      loaded.sort((a, b) {
        final dateA = (a['created_at'] ?? a['entry_date'] ?? a['date']) as String? ?? '';
        final dateB = (b['created_at'] ?? b['entry_date'] ?? b['date']) as String? ?? '';
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      debugPrint('Error in _loadHistory: $e');
    }

    if (mounted) {
      setState(() {
        _entries = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Journal Entry',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this journal entry?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticService.lightTap();
    final id = entry['id']?.toString() ?? '';
    final content = entry['content']?.toString() ?? '';
    final dateStr = (entry['entry_date'] ?? entry['date'] ?? entry['created_at'])?.toString() ?? '';

    // Optimistically remove ONLY the targeted entry from state list (by exact ID if present)
    setState(() {
      if (id.isNotEmpty) {
        _entries.removeWhere((e) => e['id']?.toString() == id);
      } else {
        _entries.removeWhere((e) =>
            e['content']?.toString() == content &&
            (e['entry_date'] ?? e['created_at'])?.toString() == dateStr);
      }
    });

    try {
      // 1. Delete from Cloud Database if entry has a server UUID
      if (id.isNotEmpty && !id.startsWith('legacy_') && !id.startsWith('local_')) {
        await ApiClient().delete('${ApiConfig.journal}/$id', silent: true);
      }

      // 2. Delete from local storage 'journal_history' cache
      final raw = await _storage.read(key: 'journal_history');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        if (id.isNotEmpty) {
          list.removeWhere((e) => e['id']?.toString() == id);
        } else {
          list.removeWhere((e) =>
              e['content']?.toString() == content &&
              (e['entry_date'] ?? e['created_at'])?.toString() == dateStr);
        }
        await _storage.write(key: 'journal_history', value: jsonEncode(list));
      }

      // 3. Purge legacy single-day keys in local storage if matching
      final allKeys = await _storage.readAll();
      final cleanDate = dateStr.contains('T') ? dateStr.substring(0, 10) : dateStr;
      for (final key in allKeys.keys) {
        if (key.startsWith('journal_')) {
          if (allKeys[key] == content ||
              (cleanDate.isNotEmpty && key == 'journal_$cleanDate') ||
              (cleanDate.isNotEmpty && key == 'journal_mood_$cleanDate')) {
            await _storage.delete(key: key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting journal entry: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry permanently deleted.'),
          backgroundColor: Color(0xFF334155),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editEntry(Map<String, dynamic> entry) async {
    HapticService.lightTap();
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyJournalScreen(entryToEdit: entry),
      ),
    );
    if (res == true) {
      _loadHistory();
    }
  }

  String _formatDisplayDate(Map<String, dynamic> entry) {
    final rawDate = (entry['created_at'] ?? entry['entry_date'] ?? entry['date'])?.toString();
    if (rawDate == null || rawDate.isEmpty) return 'Recent Entry';
    try {
      final parsed = DateTime.parse(rawDate.contains('T') ? rawDate : '${rawDate}T00:00:00');
      if (rawDate.contains('T')) {
        return DateFormat('EEEE, MMM d, yyyy • h:mm a').format(parsed.toLocal());
      }
      return DateFormat('EEEE, MMMM d, yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  void _showEntryDetail(Map<String, dynamic> entry) {
    HapticService.lightTap();
    final moodTag = entry['mood_tag'] ?? entry['type'] ?? '🌿 Calm';
    final prompt = entry['prompt'] as String?;
    final content = entry['content'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(ctx).size.height * 0.8,
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
                    _formatDisplayDate(entry),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (moodTag != null && moodTag.toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      moodTag.toString(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
              ],
            ),
            if (prompt != null && prompt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    color: Color(0xFF1E293B),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editEntry(entry);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteEntry(entry);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
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
        title: const Text(
          'Journal History',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
            tooltip: 'Write New Entry',
            onPressed: () async {
              if (widget.fromDailyJournal) {
                Navigator.pop(context);
              } else {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyJournalScreen()),
                );
                if (res == true) _loadHistory();
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: _entries.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                if (widget.fromDailyJournal) {
                  Navigator.pop(context);
                } else {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyJournalScreen()),
                  );
                  if (res == true) _loadHistory();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text('New Entry', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
            ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_note_rounded, size: 48, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Journal Entries Yet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Start your first reflection to track your personal growth!',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _entries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final entry = _entries[i];
                        final moodTag = entry['mood_tag'] ?? entry['type'];
                        final content = entry['content'] ?? '';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showEntryDetail(entry),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(4),
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
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFD97706)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _formatDisplayDate(entry),
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (moodTag != null && moodTag.toString().isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            moodTag.toString(),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0284C7),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      // Dedicated Edit button with hit-stop
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit entry',
                                        onPressed: () => _editEntry(entry),
                                      ),
                                      const SizedBox(width: 4),
                                      // Dedicated Delete button with hit-stop
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete entry',
                                        onPressed: () => _deleteEntry(entry),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    content,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
