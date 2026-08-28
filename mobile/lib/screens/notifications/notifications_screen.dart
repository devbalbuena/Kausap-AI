import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../journal/daily_journal_screen.dart';
import '../insights/student_insights_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    try {
      await _service.markAsRead(notification['id'].toString());
    } catch (_) {}
    if (mounted) {
      setState(() => notification['is_read'] = true);
    }
  }

  Future<void> _markAllAsRead() async {
    HapticService.lightTap();
    try {
      await _service.markAllAsRead();
    } catch (_) {}
    if (mounted) {
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read. ✅'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notif) async {
    HapticService.lightTap();
    final id = notif['id']?.toString() ?? '';
    setState(() {
      _notifications.removeWhere((n) => n['id']?.toString() == id);
    });

    if (id.isNotEmpty) {
      await _service.deleteNotification(id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification removed.'),
          backgroundColor: Color(0xFF334155),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Notifications',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to clear all notifications from your inbox?',
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticService.mediumTap();
    setState(() => _notifications.clear());
    await _service.clearAllNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inbox cleared. ✨'),
          backgroundColor: Color(0xFF0F172A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    _markAsRead(notif);
    final type = notif['type']?.toString().toLowerCase() ?? '';
    final title = notif['title']?.toString().toLowerCase() ?? '';

    if (title.contains('check-in') || title.contains('mood') || type == 'mood') {
      Navigator.pop(context, 'open_mood');
    } else if (title.contains('assessment') || title.contains('phq') || title.contains('gad') || type == 'session' || type == 'assessment') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentInsightsScreen()));
    } else if (title.contains('journal') || title.contains('reflection') || type == 'journal') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyJournalScreen()));
    } else if (title.contains('streak') || type == 'alert') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentInsightsScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentInsightsScreen()));
    }
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final String parsedIso = (isoDate.endsWith('Z') || isoDate.contains('+'))
          ? isoDate
          : '${isoDate}Z';
      final dt = DateTime.parse(parsedIso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 5 && diff.inMinutes >= 0) return 'Just now';
      if (diff.inMinutes < 60 && diff.inMinutes >= 0) return '${diff.inMinutes}m ago';

      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (isToday) {
        return 'Today, ${DateFormat('h:mm a').format(dt)}';
      }

      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
      if (isYesterday) {
        return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
      }

      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'mood':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'session':
        return Icons.calendar_today_rounded;
      case 'journal':
        return Icons.edit_note_rounded;
      case 'assessment':
        return Icons.assignment_outlined;
      case 'alert':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'mood':
        return const Color(0xFF0284C7);
      case 'session':
        return const Color(0xFF2E9E6B);
      case 'journal':
        return const Color(0xFFD97706);
      case 'assessment':
        return const Color(0xFF8B5CF6);
      case 'alert':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['is_read'] != true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'read_all') {
                  _markAllAsRead();
                } else if (val == 'clear_all') {
                  _clearAllNotifications();
                }
              },
              itemBuilder: (ctx) => [
                if (hasUnread)
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text('Mark all as read', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Text('Clear all notifications', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFDC2626))),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return _buildDismissibleCard(notif);
                          },
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.notifications_off_rounded,
      title: 'You\'re all caught up!',
      description: 'No new notifications right now. We will notify you when wellness reminders or counselor notes arrive.',
    );
  }

  Widget _buildDismissibleCard(Map<String, dynamic> notif) {
    final id = notif['id']?.toString() ?? UniqueKey().toString();
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => _deleteNotification(notif),
      child: _buildNotificationCard(notif),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final bool isRead = notif['is_read'] == true;
    final String type = notif['type'] ?? 'system';
    final Color typeColor = _colorForType(type);
    final IconData typeIcon = _iconForType(type);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? const Color(0xFFE2E8F0) : typeColor.withAlpha(90),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] ?? 'Notification',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                              fontSize: 13.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(notif['created_at']),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator dot
              if (!isRead) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
