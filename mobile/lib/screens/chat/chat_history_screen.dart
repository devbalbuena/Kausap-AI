import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_helper.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

typedef ResumeSessionCallback = void Function(
  String? sessionId,
  List<Map<String, dynamic>> messages,
  String? avatarId,
  String? avatarName,
);

class ChatHistoryScreen extends StatefulWidget {
  final ResumeSessionCallback? onResumeSession;

  const ChatHistoryScreen({super.key, this.onResumeSession});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  static const _storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> list = [];

    // 1. Local history (instant, works offline)
    try {
      final raw = await _storage.read(key: 'chat_history_sessions');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final s in decoded) {
            if (s is Map) {
              list.add(Map<String, dynamic>.from(s));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading local chat history: $e');
    }

    // 2. Fetch remote sessions from backend API (syncs in production & local test)
    try {
      final remote = await ApiClient().get(ApiConfig.chatSessions, silent: true);
      if (remote is List) {
        for (final item in remote) {
          if (item is Map) {
            final remoteSession = Map<String, dynamic>.from(item);
            final sId = (remoteSession['id'] ?? '').toString();
            final rawMsgs = remoteSession['messages'];
            final List<Map<String, dynamic>> parsedMsgs = [];
            if (rawMsgs is List) {
              for (final m in rawMsgs) {
                if (m is Map) {
                  parsedMsgs.add(Map<String, dynamic>.from(m));
                }
              }
            }

            if (parsedMsgs.isNotEmpty) {
              final existingIdx = list.indexWhere((s) => s['id']?.toString() == sId);
              final String? existingAvatarName = existingIdx >= 0 ? list[existingIdx]['avatarName']?.toString() : null;
              final String? existingAvatarId = existingIdx >= 0 ? list[existingIdx]['avatarId']?.toString() : null;

              // Try to get avatar from local cache first, then remote fields
              String? resolvedAvatarId = existingAvatarId ?? remoteSession['avatar_id']?.toString() ?? remoteSession['avatarId']?.toString();
              String? resolvedAvatarName = existingAvatarName;

              // If remote topic is generic (e.g. "Free Talk") or missing a persona name,
              // infer the persona from the first assistant message content
              final remoteTopic = remoteSession['topic']?.toString() ?? '';
              final isGenericTopic = remoteTopic.isEmpty ||
                  remoteTopic == 'Free Talk' ||
                  remoteTopic == 'Chat' ||
                  remoteTopic == 'New Session';

              if ((resolvedAvatarName == null || resolvedAvatarName.isEmpty) && isGenericTopic) {
                final inferred = _inferPersonaFromMessages(parsedMsgs);
                if (inferred != null) {
                  resolvedAvatarName = inferred[0];
                  resolvedAvatarId ??= inferred[1];
                }
              }

              resolvedAvatarName ??= isGenericTopic ? 'Kausap Buddy (Mascot)' : remoteTopic;

              final sessionMap = {
                'id': sId,
                'date': remoteSession['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                'avatarId': resolvedAvatarId,
                'avatarName': resolvedAvatarName,
                'messages': parsedMsgs,
              };

              if (existingIdx >= 0) {
                final localMsgs = list[existingIdx]['messages'] as List?;
                if (localMsgs == null || localMsgs.length < parsedMsgs.length) {
                  list[existingIdx] = sessionMap;
                }
              } else {
                list.add(sessionMap);
              }
            }
          }
        }

        list.sort((a, b) {
          final da = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

        await _storage.write(key: 'chat_history_sessions', value: jsonEncode(list));
      }
    } catch (e) {
      debugPrint('Error syncing chat sessions from backend: $e');
    }

    if (mounted) {
      setState(() {
        _sessions = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clear any active SnackBars when user leaves Chat History
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    super.dispose();
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final sessionId = session['id']?.toString();
    setState(() {
      _sessions.removeWhere((s) => s['id']?.toString() == sessionId);
    });
    await _storage.write(key: 'chat_history_sessions', value: jsonEncode(_sessions));

    // Also delete permanently from backend database if valid UUID
    if (sessionId != null && sessionId.isNotEmpty && sessionId.contains('-')) {
      try {
        await ApiClient().delete('${ApiConfig.chatSessions}/$sessionId', silent: true);
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat session deleted.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getAvatarEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('maya')) return '👩‍🎓';
    if (lower.contains('ben')) return '👨‍🎓';
    if (lower.contains('santos') || lower.contains('doc')) return '🩺';
    if (lower.contains('leo') || lower.contains('coach leo')) return '🏆';
    if (lower.contains('grace') || lower.contains('tita')) return '💜';
    if (lower.contains('gabriel') || lower.contains('prof')) return '📖';
    if (lower.contains('serena') || lower.contains('zen')) return '🌙';
    if (lower.contains('alex')) return '🔥';
    return '🤖';
  }

  /// Scans the first assistant message to detect which AI persona sent it.
  /// Returns [name, avatarId] or null if undetectable.
  List<String>? _inferPersonaFromMessages(List<Map<String, dynamic>> messages) {
    // Look at first few assistant messages for persona self-identification
    final assistantMsgs = messages
        .where((m) => (m['role'] ?? m['sender'] ?? '').toString() == 'assistant')
        .take(3);

    for (final m in assistantMsgs) {
      final content = (m['content'] ?? '').toString().toLowerCase();
      if (content.contains('ate maya') || content.contains("i'm maya") || content.contains('i am maya')) {
        return ['Ate Maya', 'maya'];
      }
      if (content.contains('kuya ben') || content.contains("i'm ben") || content.contains('i am ben')) {
        return ['Kuya Ben', 'ben'];
      }
      if (content.contains('coach leo') || content.contains("i'm leo")) {
        return ['Coach Leo', 'coach_leo'];
      }
      if (content.contains('tita grace') || content.contains("i'm grace")) {
        return ['Tita Grace', 'tita_grace'];
      }
      if (content.contains('doc santos') || content.contains('dr. santos') || content.contains('doctor santos')) {
        return ['Doc Santos', 'santos'];
      }
      if (content.contains('prof. gabriel') || content.contains('prof gabriel') || content.contains("i'm gabriel")) {
        return ['Prof. Gabriel', 'prof_gabriel'];
      }
      if (content.contains('serena') || content.contains('zen')) {
        return ['Serena Zen', 'serena_zen'];
      }
      if (content.contains('coach alex') || content.contains("i'm alex")) {
        return ['Coach Alex', 'coach_alex'];
      }
      if (content.contains('kausap buddy') || content.contains('buddy')) {
        return ['Kausap Buddy (Mascot)', 'buddy'];
      }
    }
    return null;
  }

  String _formatSessionDate(String? isoDate) {
    return DateHelper.formatDateTime(isoDate);
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
          'Chat History',
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
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 34),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Past Conversations',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Your conversations with Kausap AI will be saved here so you can review them anytime.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _sessions.length,
                  itemBuilder: (context, idx) {
                    final session = _sessions[idx];
                    final dateStr = _formatSessionDate(session['date'] as String?);
                    final avatarName = session['avatarName'] as String? ?? 'Kausap AI';
                    final rawMsgs = session['messages'] as List? ?? [];
                    final List<Map<String, dynamic>> messages = [];
                    for (final m in rawMsgs) {
                      if (m is Map) {
                        messages.add(Map<String, dynamic>.from(m));
                      }
                    }
                    final lastMsg = messages.isNotEmpty ? (messages.last['content'] as String? ?? '') : 'No messages';

                    return Dismissible(
                      key: Key('session_${session['id'] ?? idx}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteSession(session),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withAlpha(25),
                            child: Text(_getAvatarEmoji(avatarName), style: const TextStyle(fontSize: 18)),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  avatarName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              lastMsg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: 'Delete this chat',
                            onPressed: () => _deleteSession(session),
                          ),
                          onTap: () {
                            if (widget.onResumeSession != null) {
                              widget.onResumeSession!(
                                session['id']?.toString(),
                                messages,
                                session['avatarId']?.toString(),
                                session['avatarName']?.toString(),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ), // Material
                      ),
                    );
                  },
                ),
    );
  }
}
