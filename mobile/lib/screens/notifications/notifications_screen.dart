import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_widgets.dart';
import '../journal/daily_journal_screen.dart';
import '../insights/student_insights_screen.dart';
import '../guidance/guidance_notices_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'unread', 'guidance', 'alert', 'wellness'

  bool _isGuidanceNotice(Map<String, dynamic> notif) {
    final type = notif['type']?.toString().toLowerCase() ?? '';
    final title = notif['title']?.toString().toLowerCase() ?? '';
    return type == 'guidance_notice' ||
        title.contains('guidance') ||
        title.contains('call-slip') ||
        title.contains('consultation notice');
  }

  bool _matchesCategoryFilter(Map<String, dynamic> notif) {
    if (_selectedFilter == 'all') return true;
    if (_selectedFilter == 'unread') return notif['is_read'] != true;
    final type = notif['type']?.toString().toLowerCase() ?? '';
    final title = notif['title']?.toString().toLowerCase() ?? '';
    final body = notif['body']?.toString().toLowerCase() ?? '';
    if (_selectedFilter == 'guidance') {
      return _isGuidanceNotice(notif);
    }
    if (_selectedFilter == 'alert') {
      return type == 'alert' ||
          title.contains('crisis') ||
          title.contains('triage') ||
          title.contains('flag') ||
          title.contains('distress') ||
          body.contains('escalation');
    }
    if (_selectedFilter == 'wellness') {
      return type == 'mood' ||
          type == 'journal' ||
          type == 'assessment' ||
          type == 'session' ||
          title.contains('check-in') ||
          title.contains('journal') ||
          title.contains('mood');
    }
    return true;
  }

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
              minimumSize: const Size(0, 40),
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
    final body = notif['body']?.toString().toLowerCase() ?? '';

    if (_isGuidanceNotice(notif)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidanceNoticesScreen()));
    } else if (title.contains('crisis') || title.contains('triage') || title.contains('flag') || body.contains('triage') || body.contains('escalation')) {
      Navigator.pop(context, 'open_triage');
    } else if (title.contains('distress') || title.contains('appeal') || title.contains('student') || body.contains('low moods') || body.contains('appeal')) {
      Navigator.pop(context, 'open_students');
    } else if (title.contains('check-in') || title.contains('mood') || type == 'mood') {
      Navigator.pop(context, 'open_mood');
    } else if (title.contains('assessment') || title.contains('phq') || title.contains('gad') || type == 'session' || type == 'assessment') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentInsightsScreen()));
    } else if (title.contains('journal') || title.contains('reflection') || type == 'journal') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyJournalScreen()));
    } else if (title.contains('streak') || type == 'alert') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentInsightsScreen()));
    } else {
      Navigator.pop(context);
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
      case 'guidance_notice':
        return Icons.account_balance_rounded;
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
      case 'guidance_notice':
        return const Color(0xFF0369A1);
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

  Widget _buildFilterChip(String label, String value, {int? count}) {
    final isSelected = _selectedFilter == value;
    final display = count != null && count > 0 ? '$label ($count)' : label;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          display,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['is_read'] != true);
    final unreadCount = _notifications.where((n) => n['is_read'] != true).length;
    final guidanceCount = _notifications.where(_isGuidanceNotice).length;
    final filteredNotifications = _notifications.where(_matchesCategoryFilter).toList();

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
                ? const SkeletonSessionList(count: 5)
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All', 'all', count: _notifications.length),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Unread', 'unread', count: unreadCount),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('🏛️ Guidance Notices', 'guidance', count: guidanceCount),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('🚨 Alerts', 'alert'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('🌿 Wellness', 'wellness'),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          Expanded(
                            child: filteredNotifications.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.filter_list_off_rounded, size: 42, color: Color(0xFF94A3B8)),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'No matching notifications',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Try switching to another filter category above.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    color: AppColors.primary,
                                    onRefresh: _fetchNotifications,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      itemCount: filteredNotifications.length,
                                      itemBuilder: (context, index) {
                                        final notif = filteredNotifications[index];
                                        return _buildDismissibleCard(notif);
                                      },
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
                    if (_isGuidanceNotice(notif)) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Text(
                          '🏛️ FSUU Guidance Office Call-Slip',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ],
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
                    if (_isGuidanceNotice(notif)) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text(
                            'View Official Call-Slip & Confirm Visit',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ],
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
