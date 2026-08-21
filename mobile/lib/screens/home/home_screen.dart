import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../utils/app_routes.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/privacy_settings_service.dart';
import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/branded_refresh_indicator.dart';
import '../journal/daily_journal_screen.dart';
import '../chat/chatbot_screen.dart';
import '../insights/student_insights_screen.dart';
import '../activity/activity_screen.dart';
import '../activity/activity_start_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../crisis/sos_screen.dart';
import '../crisis/quick_escape_screen.dart';
import '../articles/articles_data.dart';
import '../articles/articles_screen.dart';
import '../articles/article_detail_screen.dart';

/// Client Home Screen — Figma: "Client/Home"
/// Sections: Header, Streak, Daily Check-in, Chat, Upcoming Session,
///           Quote, Suggested Activity, Book Session, Mood Trends, Bottom Nav
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _unreadCount = 0;
  int _streak = 0;
  int _goal = 30;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _dailyQuests = [
    {'title': 'Log your mood', 'completed': false},
    {'title': 'Write a journal entry', 'completed': false},
    {'title': 'Complete a mindfulness exercise', 'completed': false},
  ];

  int? _todayMoodLevel;
  bool _showQuickEscape = false;
  List<double?> _weeklyMoods = List.filled(7, null);
  double? _weeklyAverage;
  int _totalLogsThisWeek = 0;
  
  final NotificationService _notificationService = NotificationService();

  String get _firstName => widget.user['first_name'] ?? 'User';

  @override
  void initState() {
    super.initState();
    _fetchQuickEscapePref();
    _fetchUnreadCount();
    _fetchStreak();
    _fetchQuests();
    _fetchMoodTrends();
    // Show mood popup after first frame if mood not yet logged today
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowMoodPopup());
  }

  Future<void> _fetchQuickEscapePref() async {
    final enabled = await PrivacySettingsService.isQuickEscapeEnabled();
    if (mounted) {
      setState(() {
        _showQuickEscape = enabled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshHome() {
    // Scroll back to top
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
    // Re-fetch data
    _fetchQuickEscapePref();
    _fetchUnreadCount();
    _fetchStreak();
    _fetchQuests();
    _fetchMoodTrends();
  }

  String _getMoodEmojiAndLabel(int level) {
    switch (level) {
      case 5:
        return '😄 Great';
      case 4:
        return '🙂 Good';
      case 3:
        return '😐 Okay';
      case 2:
        return '😟 Low';
      case 1:
        return '😞 Rough';
      default:
        return '🙂 Good';
    }
  }

  /// Show unified friendly 1-tap mood check-in sheet
  Future<void> _openMoodPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodPopupSheet(
        firstName: _firstName,
        onMoodSelected: (level) async {
          try {
            await ApiClient().post(ApiConfig.mood, body: {
              'mood_level': level,
              'emotions': null,
              'intensity': level,
            });
            if (mounted) {
              setState(() {
                _todayMoodLevel = level;
                _dailyQuests[0]['completed'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mood logged! ✅ Daily quest updated.'),
                  backgroundColor: Color(0xFF22C55E),
                  duration: Duration(seconds: 2),
                ),
              );
              _fetchStreak();
              _fetchQuests();
              _fetchMoodTrends();
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not save mood. Try again.')),
              );
            }
          }
        },
      ),
    );
  }

  /// Show a friendly mood check-in pop-up on app start if not yet logged today.
  Future<void> _maybeShowMoodPopup() async {
    if (!mounted) return;
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final moodData = await ApiClient().get(ApiConfig.mood);
      if (moodData is List) {
        final loggedToday = moodData.any(
          (e) => (e['created_at'] as String?)?.startsWith(todayStr) ?? false,
        );
        if (loggedToday) return; // Already logged — skip popup
      }
    } catch (_) {
      return; // On error, don't bother the user
    }
    if (!mounted) return;
    await _openMoodPickerSheet();
  }

  Future<void> _fetchQuests() async {
    bool moodCompleted = false;
    bool journalCompleted = false;
    bool mindfulnessCompleted = false;
    int? todayLevel;

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Check mood
      try {
        final moodData = await ApiClient().get(ApiConfig.mood);
        if (moodData is List) {
          final todayEntries = moodData.where(
            (e) => (e['created_at'] as String?)?.startsWith(todayStr) ?? false,
          ).toList();
          if (todayEntries.isNotEmpty) {
            moodCompleted = true;
            todayLevel = (todayEntries.last['mood_level'] as num?)?.toInt();
          }
        }
      } catch (_) {}

      // 2. Check journal
      final storage = const FlutterSecureStorage();
      final savedJournal = await storage.read(key: 'journal_$todayStr');
      if (savedJournal != null && savedJournal.trim().isNotEmpty) {
        journalCompleted = true;
      }

      // 3. Check mindfulness
      final savedMindfulness = await storage.read(key: 'mindfulness_$todayStr');
      if (savedMindfulness == 'completed') {
        mindfulnessCompleted = true;
      }

    } catch (_) {}

    if (mounted) {
      setState(() {
        _todayMoodLevel = todayLevel;
        _dailyQuests[0]['completed'] = moodCompleted;
        _dailyQuests[1]['completed'] = journalCompleted;
        _dailyQuests[2]['completed'] = mindfulnessCompleted;
      });
    }
  }

  Future<void> _fetchStreak() async {
    try {
      final moodData = await ApiClient().get(ApiConfig.mood);
      if (moodData is! List || !mounted) return;

      // Collect unique calendar days that have at least one mood entry
      final Set<String> daysWithMood = {};
      for (final entry in moodData) {
        final created = entry['created_at'] as String?;
        if (created != null && created.length >= 10) {
          daysWithMood.add(created.substring(0, 10)); // 'yyyy-MM-dd'
        }
      }

      // Count consecutive days ending today (or yesterday if today not yet logged)
      int streak = 0;
      final today = DateTime.now();
      for (int i = 0; i < 365; i++) {
        final checkDay = today.subtract(Duration(days: i));
        final dayStr = DateFormat('yyyy-MM-dd').format(checkDay);
        if (daysWithMood.contains(dayStr)) {
          streak++;
        } else {
          break; // First gap ends the streak
        }
      }

      if (mounted) {
        setState(() {
          _streak = streak;
          _goal = 30; // 30-day wellness goal
        });
      }
    } catch (_) {
      // On error keep _streak = 0
    }
  }

  Future<void> _fetchMoodTrends() async {
    try {
      final moodData = await ApiClient().get(ApiConfig.mood);
      if (moodData is! List || !mounted) return;

      final now = DateTime.now();
      // Monday of current week (DateTime.weekday: Mon=1, Sun=7)
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      final List<double?> weeklyMoods = List.filled(7, null);
      double totalSum = 0;
      int loggedDays = 0;

      for (int i = 0; i < 7; i++) {
        final targetDate = monday.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

        final dayEntries = moodData.where((e) {
          final created = e['created_at'] as String?;
          return created != null && created.startsWith(dateStr);
        }).toList();

        if (dayEntries.isNotEmpty) {
          double daySum = 0;
          for (final entry in dayEntries) {
            final level = (entry['mood_level'] as num?)?.toDouble() ?? 3.0;
            daySum += level;
          }
          final avgLevel = (daySum / dayEntries.length).clamp(1.0, 5.0);
          weeklyMoods[i] = avgLevel;
          totalSum += avgLevel;
          loggedDays++;
        }
      }

      if (mounted) {
        setState(() {
          _weeklyMoods = weeklyMoods;
          _totalLogsThisWeek = loggedDays;
          _weeklyAverage = loggedDays > 0 ? (totalSum / loggedDays) : null;
        });
      }
    } catch (_) {
      // Keep defaults
    }
  }

  Color _moodColor(double level) {
    if (level >= 4.5) return const Color(0xFF06B6D4); // Great (Cyan)
    if (level >= 3.5) return const Color(0xFF10B981); // Good (Emerald)
    if (level >= 2.5) return const Color(0xFFF59E0B); // Okay (Amber)
    if (level >= 1.5) return const Color(0xFFF97316); // Low (Orange)
    return const Color(0xFFEF4444);                   // Rough (Red)
  }

  String _moodEmoji(double level) {
    if (level >= 4.5) return '😄';
    if (level >= 3.5) return '🙂';
    if (level >= 2.5) return '😐';
    if (level >= 1.5) return '😟';
    return '😞';
  }

  Future<void> _fetchUnreadCount() async {
    final connectivity = ConnectivityService();
    if (!connectivity.isOnline) {
      // Serve cached count when offline
      final cached = await CacheService.readMap('home_unread_count');
      if (cached != null && mounted) {
        setState(() => _unreadCount = (cached['count'] as int?) ?? 0);
      }
      return;
    }
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
      // Cache the result
      await CacheService.saveMap(
        'home_unread_count',
        {'count': count},
        ttlMinutes: 30,
      );
    } catch (_) {
      // Fallback to cache on error
      final cached = await CacheService.readMap('home_unread_count');
      if (cached != null && mounted) {
        setState(() => _unreadCount = (cached['count'] as int?) ?? 0);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchUnreadCount();
    // Give a small delay so the branded indicator is visible
    await Future.delayed(const Duration(milliseconds: 400));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Builds the home tab content (the main scrollable dashboard)
  Widget _buildHomeTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: BrandedRefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildGreeting(),
                    const SizedBox(height: 20),
                    _buildStreakCard(),
                    const SizedBox(height: 16),
                    _buildSosBanner(),
                    const SizedBox(height: 16),
                    _buildDailyQuestsCard(),
                    const SizedBox(height: 16),
                    _todayMoodLevel == null
                        ? _buildQuickActionCard(
                            iconBg: AppColors.checkinIcon,
                            icon: Icons.favorite_rounded,
                            iconColor: const Color(0xFFE74C3C),
                            title: 'How are you feeling today?',
                            subtitle: 'Tap to check-in your mood',
                            onTap: _openMoodPickerSheet,
                          )
                        : _buildQuickActionCard(
                            iconBg: const Color(0xFFE0F2FE),
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: "Today's Mood: ${_getMoodEmojiAndLabel(_todayMoodLevel!)}",
                            subtitle: 'Logged today ✅ • Tap to view trends & insights',
                            onTap: () => setState(() => _navIndex = 3),
                          ),
                    const SizedBox(height: 12),
                    _buildQuickActionCard(
                      iconBg: const Color(0xFFFEF3C7),
                      icon: Icons.edit_note_rounded,
                      iconColor: const Color(0xFFD97706),
                      title: 'Daily Journal',
                      subtitle: 'Write your thoughts and reflect',
                      onTap: () async {
                        final res = await Navigator.of(context).push(slideRoute(const DailyJournalScreen()));
                        if (res == true) {
                          _fetchQuests();
                          _fetchStreak();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionCard(
                      iconBg: AppColors.chatbotIcon,
                      icon: Icons.smart_toy_rounded,
                      iconColor: const Color(0xFF0077B6),
                      title: 'Talk to Kausap AI',
                      subtitle: '24/7 confidential CBT companion',
                      onTap: () => setState(() => _navIndex = 2),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionCard(
                      iconBg: const Color(0xFFD1FAE5),
                      icon: Icons.self_improvement_rounded,
                      iconColor: const Color(0xFF059669),
                      title: 'Mindfulness Exercises',
                      subtitle: 'Breathe, meditate & relax',
                      onTap: () => setState(() => _navIndex = 1),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionCard(
                      iconBg: const Color(0xFFEFF6FF),
                      icon: Icons.analytics_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Self-Assessments',
                      subtitle: 'PHQ-9 Depression & GAD-7 Anxiety Screeners',
                      onTap: () => setState(() => _navIndex = 3),
                    ),
                    const SizedBox(height: 16),
                    _buildQuoteCard(),
                    const SizedBox(height: 16),
                    _buildSuggestedActivity(),
                    const SizedBox(height: 16),
                    _buildScreenerPromoCard(),
                    const SizedBox(height: 16),
                    _buildArticlesSection(),
                    const SizedBox(height: 16),
                    _buildMoodTrends(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define the 5 tabs as inline widgets (keeps bottom nav always visible)
    final List<Widget> tabs = [
      _buildHomeTab(),                                      // 0 – Home
      const ActivityScreen(),                              // 1 – Activity
      const ChatbotScreen(),                               // 2 – Kausap AI
      const StudentInsightsScreen(),                       // 3 – Insights & Screeners
      const ProfileScreen(),                               // 4 – Profile
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _navIndex,
                children: tabs,
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header (Logo + bell + avatar) ─────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Text('Kausap AI',
              style: AppTextStyles.brandName
                  .copyWith(color: AppColors.primary, fontSize: 20)),
        ]),
        Row(children: [
          // Quick Escape panic button (Shown only if enabled in Settings)
          if (_showQuickEscape) ...[
            Semantics(
              label: 'Quick escape',
              button: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuickEscapeScreen(),
                    fullscreenDialog: true,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shield_outlined, color: Colors.red.shade400, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Semantics(
            label: _unreadCount > 0
                ? 'Notifications, $_unreadCount unread'
                : 'Notifications',
            button: true,
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(slideRoute(const NotificationsScreen()));
                _fetchUnreadCount();
              },
              child: Stack(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary, size: 24),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'Open profile tab for $_firstName',
            button: true,
            child: GestureDetector(
              onTap: () => setState(() => _navIndex = 4),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final user = auth.currentUser ?? widget.user;
                  final name = user['first_name'] ?? 'U';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                  final avatarUrl = user['avatar_url'] as String?;
                  return CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                        ? Text(
                            initial,
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w700),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()},',
          style: AppTextStyles.heading1.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        Text(
          '${_firstName.isNotEmpty ? _firstName[0].toUpperCase() + _firstName.substring(1) : 'User'}!',
          style: AppTextStyles.heading1.copyWith(fontSize: 26),
        ),
      ],
    );
  }

  // ── Streak Card ────────────────────────────────────────────────────────────
  Widget _buildStreakCard() {
    final clampedStreak = _streak.clamp(0, _goal);
    final progress = _goal > 0 ? clampedStreak / _goal : 0.0;
    final streakLabel = _streak == 0
        ? 'Start your streak today! 🌱'
        : '$_streak Day${_streak == 1 ? '' : 's'} Streak 🔥';
    final subLabel = _streak == 0
        ? 'Log your mood to begin'
        : '$clampedStreak / $_goal days to your goal';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_streak == 0 ? '🌱' : '🔥',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(streakLabel, style: AppTextStyles.heading2),
            ),
          ]),
          const SizedBox(height: 4),
          Text(subLabel, style: AppTextStyles.subheading),
          const SizedBox(height: 12),
          Stack(children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                  color: AppColors.streakTrack,
                  borderRadius: BorderRadius.circular(99)),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── SOS / Get Help Banner ────────────────────────────────────────────────────
  Widget _buildSosBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(slideRoute(const SosScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade400],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sos_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need immediate help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to access crisis support & hotlines',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Daily Quests Card ──────────────────────────────────────────────────────
  Widget _buildDailyQuestsCard() {
    final completedCount = _dailyQuests.where((q) => q['completed'] as bool).length;
    final totalQuests = _dailyQuests.length;
    final progress = totalQuests > 0 ? completedCount / totalQuests : 0.0;
    
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Quests', style: AppTextStyles.heading2),
              Text(
                '$completedCount/$totalQuests completed',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.streakTrack,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          ..._dailyQuests.asMap().entries.map((entry) {
            final idx = entry.key;
            final quest = entry.value;
            final isCompleted = quest['completed'] as bool;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  if (idx == 0) {
                    if (isCompleted) {
                      setState(() => _navIndex = 3);
                    } else {
                      _openMoodPickerSheet();
                    }
                  } else if (idx == 1) {
                    final res = await Navigator.of(context).push(slideRoute(const DailyJournalScreen()));
                    if (res == true) {
                      _fetchQuests();
                      _fetchStreak();
                    }
                  } else if (idx == 2) {
                    setState(() => _navIndex = 1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? AppColors.primary : AppColors.divider,
                            width: 2,
                          ),
                          color: isCompleted ? AppColors.primary : Colors.transparent,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quest['title'] as String,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isCompleted ? Colors.grey.shade400 : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Quick Action Card (Check-in / Chat) ───────────────────────────────────
  Widget _buildQuickActionCard({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: _card(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24, semanticLabel: title),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 24,
                  semanticLabel: 'navigate'),
            ],
          ),
        ),
      ),
    );
  }



  // ── Motivational Quote Card ───────────────────────────────────────────────
  Widget _buildQuoteCard() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          const Text('"', style: TextStyle(fontSize: 32, color: AppColors.divider)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'It is better to conquer yourself than to win a thousand battles',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF707070),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggested Activity ────────────────────────────────────────────────────
  Widget _buildSuggestedActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggested Activity',
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 10),
        _card(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.activityIcon,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.self_improvement_rounded,
                      color: Color(0xFF519C6B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🧘 "5-Minute Breathing Exercise"',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Based on your recent anxiety',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  textStyle: AppTextStyles.button,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    slideRoute(ActivityStartScreen(
                        activity: activityList[0],))
                  );
                },
                child: const Text('Start Activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Screener Promo Card ───────────────────────────────────────────────────
  Widget _buildScreenerPromoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0077B6), Color(0xFF0096C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0077B6).withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MENTAL HEALTH SCREENERS',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'Take evidence-based PHQ-9 & GAD-7 screeners to track depression and anxiety trends.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0077B6),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                    textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    setState(() => _navIndex = 3);
                  },
                  child: const Text('Take Assessment'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.analytics_rounded,
              color: Colors.white24, size: 70),
        ],
      ),
    );
  }

  // ── Articles & Wellness Insights Section ─────────────────────────────────
  Widget _buildArticlesSection() {
    final previewArticles = ArticlesData.all.take(4).toList();

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
              onTap: () => Navigator.of(context).push(slideRoute(const ArticlesScreen())),
              child: Text(
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
        Text('Curated reads for your mental wellness', style: AppTextStyles.subheading),
        const SizedBox(height: 12),
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewArticles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final article = previewArticles[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(slideRoute(ArticleDetailScreen(article: article))),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1AC0C9C2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                              color: article.themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.category,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: article.themeColor,
                              ),
                            ),
                          ),
                          Text(
                            article.readTime,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          height: 1.3,
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
                              article.author[0],
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
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Mood Trends ───────────────────────────────────────────────────────────
  Widget _buildMoodTrends() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIdx = DateTime.now().weekday - 1; // Mon=0, Sun=6

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mood Trends', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Your Week at a Glance', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              if (_weeklyAverage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _moodColor(_weeklyAverage!).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _moodColor(_weeklyAverage!).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_moodEmoji(_weeklyAverage!), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '${_weeklyAverage!.toStringAsFixed(1)} / 5',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _moodColor(_weeklyAverage!),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // 7-Day Chart
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final mood = _weeklyMoods[i];
                final isToday = i == todayIdx;
                final isFuture = i > todayIdx;

                // Max bar height = 65
                final barHeight = mood != null ? ((mood / 5.0) * 65).clamp(14.0, 65.0) : 0.0;
                final color = mood != null ? _moodColor(mood) : AppColors.primary;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Top Emoji or Indicator
                        SizedBox(
                          height: 18,
                          child: mood != null
                              ? Text(
                                  _moodEmoji(mood),
                                  style: const TextStyle(fontSize: 12),
                                )
                              : (isToday
                                  ? Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                        const SizedBox(height: 4),

                        // Bar
                        Expanded(
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary.withAlpha(20)
                                  : Colors.black.withAlpha(8),
                              borderRadius: BorderRadius.circular(10),
                              border: isToday
                                  ? Border.all(color: AppColors.primary.withAlpha(80), width: 1.2)
                                  : null,
                            ),
                            child: mood != null
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                    width: double.infinity,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          color,
                                          color.withAlpha(180),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withAlpha(50),
                                          blurRadius: 4,
                                          offset: const Offset(0, -1),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: isFuture ? 4 : 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isFuture
                                          ? Colors.black.withAlpha(12)
                                          : (isToday ? AppColors.primary.withAlpha(60) : Colors.black.withAlpha(25)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Day label
                        Text(
                          days[i],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : (isFuture ? AppColors.textSecondary.withAlpha(100) : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Footer info row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _totalLogsThisWeek > 0 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _totalLogsThisWeek > 0 ? const Color(0xFF10B981) : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _totalLogsThisWeek > 0
                        ? '$_totalLogsThisWeek ${_totalLogsThisWeek == 1 ? "day" : "days"} logged this week. Keep it up!'
                        : 'No logs yet this week. Tap "How are you feeling today?" to start!',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _navIndex = 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Insights',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.fitness_center_rounded, 'Activity'),
      (Icons.chat_bubble_rounded, 'Kausap'),
      (Icons.analytics_rounded, 'Insights'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 5.5,
              offset: const Offset(0, -2))
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final selected = i == _navIndex;
                return Semantics(
                  label: '${items[i].$2} tab${selected ? ', selected' : ''}',
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    onTap: () {
                      if (i == 0 && _navIndex == 0) {
                        // Already on Home — scroll to top and refresh
                        _refreshHome();
                      } else {
                        setState(() => _navIndex = i);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 68,
                      height: 65,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].$1,
                            size: 24,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            semanticLabel: items[i].$2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].$2,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── Card helper ───────────────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }
}

// ── Mood Quick-Check Pop-up Sheet ─────────────────────────────────────────────
class _MoodPopupSheet extends StatefulWidget {
  final String firstName;
  final Future<void> Function(int level) onMoodSelected;

  const _MoodPopupSheet({
    required this.firstName,
    required this.onMoodSelected,
  });

  @override
  State<_MoodPopupSheet> createState() => _MoodPopupSheetState();
}

class _MoodPopupSheetState extends State<_MoodPopupSheet>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _select(int level) async {
    setState(() => _isSaving = true);
    Navigator.of(context).pop(); // Dismiss sheet first
    await widget.onMoodSelected(level);
  }

  @override
  Widget build(BuildContext context) {
    const emojis = [
      {'emoji': '😞', 'label': 'Rough', 'level': 1},
      {'emoji': '😟', 'label': 'Low', 'level': 2},
      {'emoji': '😐', 'label': 'Okay', 'level': 3},
      {'emoji': '🙂', 'label': 'Good', 'level': 4},
      {'emoji': '😄', 'label': 'Great', 'level': 5},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Bouncing emoji mascot
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: child,
              ),
              child: const Text('🌿', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 12),

            Text(
              'Hey ${widget.firstName.isNotEmpty ? widget.firstName[0].toUpperCase() + widget.firstName.substring(1) : ''}! 👋',
              style: AppTextStyles.heading2.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'How are you feeling today?',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Emoji mood picker row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: emojis.map((item) {
                return GestureDetector(
                  onTap: _isSaving ? null : () => _select(item['level'] as int),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(40), width: 1),
                        ),
                        child: Center(
                          child: Text(item['emoji'] as String,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['label'] as String,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Skip link
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Skip for now',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
