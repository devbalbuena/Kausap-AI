import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
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
      if (data.isNotEmpty) {
        if (mounted) setState(() { _notifications = data; _isLoading = false; });
        return;
      }
    } catch (_) {}

    // Dynamic fallback generation based on user's real account state
    try {
      final dynamicList = await _generateDynamicNotifications();
      if (mounted) {
        setState(() {
          _notifications = dynamicList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _generateDynamicNotifications() async {
    final list = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 1. Check if mood logged today
    bool moodLogged = false;
    int moodCount = 0;
    try {
      final moodData = await ApiClient().get(ApiConfig.mood);
      if (moodData is List) {
        moodCount = moodData.length;
        moodLogged = moodData.any((e) => (e['created_at'] as String?)?.startsWith(todayStr) ?? false);
      }
    } catch (_) {}

    if (!moodLogged) {
      list.add({
        'id': 'notif_daily_mood',
        'type': 'mood',
        'title': '🌿 Daily Wellness Check-in',
        'body': 'How are you feeling today? Tap to record your mood in 1 tap.',
        'is_read': false,
        'created_at': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      });
    } else {
      list.add({
        'id': 'notif_mood_done',
        'type': 'mood',
        'title': '✨ Daily Mood Logged',
        'body': 'Great job tracking your emotional wellness today! Check out your trends.',
        'is_read': true,
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
      });
    }

    // 2. Streak alert
    if (moodCount >= 2) {
      list.add({
        'id': 'notif_streak',
        'type': 'alert',
        'title': '🔥 Streak Milestone!',
        'body': 'You are maintaining your consistency! Keep up your daily check-in habits.',
        'is_read': false,
        'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
      });
    }

    // 3. Clinical screener check-in invitation
    list.add({
      'id': 'notif_screener',
      'type': 'assessment',
      'title': '📋 Clinical Self-Assessment Ready',
      'body': 'Take a quick 2-minute PHQ-9 or GAD-7 screener to gain deep emotional insights.',
      'is_read': false,
      'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    });

    // 4. Daily journal reminder
    list.add({
      'id': 'notif_journal',
      'type': 'journal',
      'title': '📖 Evening Reflection',
      'body': 'Take a few minutes to write or voice record your thoughts in your Daily Journal.',
      'is_read': true,
      'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    });

    return list;
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

  void _handleNotificationTap(Map<String, dynamic> notif) {
    _markAsRead(notif);
    final type = notif['type']?.toString().toLowerCase() ?? '';

    if (type == 'mood' || type == 'assessment') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentInsightsScreen()));
    } else if (type == 'journal') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyJournalScreen()));
    }
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return DateFormat('MMM d').format(dt);
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
          if (hasUnread)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
              label: const Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
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
                            return _buildNotificationCard(notif);
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
