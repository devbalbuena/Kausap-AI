import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/privacy_settings_service.dart';
import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../services/offline_mood_queue.dart';
import '../../services/articles_storage_service.dart';
import '../../services/ambient_audio_service.dart';
import '../../widgets/branded_refresh_indicator.dart';

import '../../widgets/home/home_companion_avatar.dart';
import '../../widgets/home/home_support_modals.dart';
import '../../widgets/home/mood_influence_sheet.dart';
import '../../widgets/home/daily_quests_card.dart';
import '../../widgets/home/home_mood_trends_card.dart';
import '../../widgets/home/home_streak_card.dart';
import '../../widgets/home/home_sos_banner.dart';
import '../../widgets/home/home_quick_action_card.dart';
import '../../widgets/home/home_suggested_activity.dart';
import '../../widgets/home/home_articles_section.dart';

// Screens
import '../journal/daily_journal_screen.dart';
import '../chat/chatbot_screen.dart';
import '../insights/student_insights_screen.dart';
import '../activity/activity_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../crisis/sos_screen.dart';
import '../crisis/quick_escape_screen.dart';
import '../articles/articles_data.dart';
import '../articles/articles_screen.dart';

/// Client Home Screen — Clean Modular Architecture
/// Sections: Header, Companion Hero, 1-Tap Mood Check-In, Streak, SOS Banner,
///           Daily Quests, Quick Actions, Quote, Suggested Activity, Promo, Articles, Mood Trends, Bottom Nav
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  int _unreadCount = 0;
  int _streak = 0;
  int _goal = 30;
  int _insightsRefreshKey = 0;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _dailyQuests = [
    {'title': 'Log your mood', 'completed': false},
    {'title': 'Write a journal entry', 'completed': false},
    {'title': 'Complete a mindfulness exercise', 'completed': false},
  ];

  int? _todayMoodLevel;
  bool _showQuickEscape = false;
  List<double?> _weeklyMoods = List.filled(7, null);
  List<String?> _weeklyLatestEmojis = List.filled(7, null);
  List<int> _weeklyLogCounts = List.filled(7, 0);
  double? _weeklyAverage;
  int _totalLogsThisWeek = 0;
  List<ArticleModel> _homeArticles = ArticlesData.all;

  final NotificationService _notificationService = NotificationService();
  late AnimationController _bellAnimController;
  late Animation<double> _bellRotationAnim;
  late Animation<double> _badgeScaleAnim;
  bool _hasPlayedEntryChime = false;

  String get _firstName => widget.user['first_name'] ?? 'User';

  @override
  void initState() {
    super.initState();
    _bellAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Smooth rotational bell wiggle (rings left and right with natural decay)
    _bellRotationAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: -0.25, end: 0.25).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.25, end: -0.18).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: -0.18, end: 0.18).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.18, end: -0.08).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: -0.08, end: 0.08).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.08, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
    ]).animate(_bellAnimController);

    // Pop & elastic bounce for badge
    _badgeScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.30).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.30, end: 0.90).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_bellAnimController);

    _fetchQuickEscapePref();
    _fetchUnreadCount();
    _fetchStreak();
    _fetchQuests();
    _fetchMoodTrends();
    _fetchHomeArticles();
    // Show mood popup after first frame if mood not yet logged today
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowMoodPopup());
  }

  Future<void> _fetchHomeArticles() async {
    try {
      final all = await ArticlesStorageService.loadAllArticlesWithEngagement();
      if (mounted) {
        setState(() {
          _homeArticles = all;
        });
      }
    } catch (_) {}
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
    _bellAnimController.dispose();
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
    _fetchHomeArticles();
    // Silently sync any queued offline moods
    OfflineMoodQueue().syncPendingMoods();
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

  String _getEmojiOnly(int level) {
    switch (level) {
      case 5:
        return '😄';
      case 4:
        return '🙂';
      case 3:
        return '😐';
      case 2:
        return '😟';
      case 1:
        return '😞';
      default:
        return '🙂';
    }
  }

  Future<void> _logMood(int level) async {
    HapticService.mediumTap();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MoodInfluenceSheet(
        moodLevel: level,
        firstName: _firstName,
        onSave: (factors, note) async {
          Navigator.pop(ctx);
          await _submitMoodCheckin(level, factors, note);
        },
      ),
    );
  }

  Future<void> _submitMoodCheckin(int level, List<String> factors, String? note) async {
    final isOnline = ConnectivityService().isOnline;

    if (!isOnline) {
      // ── Option A: Offline Mode — Queue locally and proceed seamlessly ──
      await OfflineMoodQueue().enqueueMood(
        moodLevel: level,
        emotions: factors.isNotEmpty ? factors : null,
        intensity: level,
        note: note,
      );

      if (mounted) {
        setState(() {
          _todayMoodLevel = level;
          _dailyQuests[0]['completed'] = true;
        });
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood checked in as ${_getMoodEmojiAndLabel(level)}! ✅ Saved locally • Will sync online.'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 3),
          ),
        );
        _fetchStreak();
        _fetchQuests();
        _fetchMoodTrends();

        if (level <= 3) {
          _openCaringSupportSheet(level);
        } else {
          _openCelebrationSheet(level);
        }
      }
      return;
    }

    try {
      await ApiClient().post(ApiConfig.mood, body: {
        'mood_level': level,
        'emotions': factors.isNotEmpty ? factors : null,
        'intensity': level,
        'note': note,
      });
      if (mounted) {
        setState(() {
          _todayMoodLevel = level;
          _dailyQuests[0]['completed'] = true;
          _insightsRefreshKey++;
        });
        HapticService.success();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood checked in as ${_getMoodEmojiAndLabel(level)}! ✅ Daily tracking updated.'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 3),
          ),
        );
        _fetchStreak();
        _fetchQuests();
        _fetchMoodTrends();

        // Prompt caring support for rough/low/okay moods, or celebration for good/great moods
        if (level <= 3) {
          _openCaringSupportSheet(level);
        } else {
          _openCelebrationSheet(level);
        }
      }
    } catch (_) {
      // Network failure fallback — enqueue offline
      await OfflineMoodQueue().enqueueMood(
        moodLevel: level,
        emotions: factors.isNotEmpty ? factors : null,
        intensity: level,
        note: note,
      );
      if (mounted) {
        setState(() {
          _todayMoodLevel = level;
          _dailyQuests[0]['completed'] = true;
        });
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood checked in as ${_getMoodEmojiAndLabel(level)}! ✅ Saved locally • Will sync online.'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 3),
          ),
        );
        _fetchStreak();
        _fetchQuests();
        _fetchMoodTrends();

        if (level <= 3) {
          _openCaringSupportSheet(level);
        } else {
          _openCelebrationSheet(level);
        }
      }
    }
  }

  Future<void> _openCaringSupportSheet(int level) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CaringSupportModal(
        level: level,
        firstName: _firstName,
        onTalkToAi: () {
          Navigator.of(ctx).pop();
          setState(() => _navIndex = 2);
        },
        onOpenJournal: () async {
          Navigator.of(ctx).pop();
          final res = await Navigator.of(context).push(slideRoute(const DailyJournalScreen()));
          if (res == true) {
            _fetchQuests();
            _fetchStreak();
          }
        },
        onOpenMindfulness: () {
          Navigator.of(ctx).pop();
          setState(() => _navIndex = 1);
        },
        onOpenSos: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).push(slideRoute(const SosScreen()));
        },
      ),
    );
  }

  Future<void> _openCelebrationSheet(int level) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CelebrationModal(
        level: level,
        firstName: _firstName,
        onOpenGratitudeJournal: () async {
          Navigator.of(ctx).pop();
          final res = await Navigator.of(context).push(slideRoute(const DailyJournalScreen()));
          if (res == true) {
            _fetchQuests();
            _fetchStreak();
          }
        },
        onTalkToAi: () {
          Navigator.of(ctx).pop();
          setState(() => _navIndex = 2);
        },
      ),
    );
  }

  /// Show unified friendly 1-tap mood check-in sheet
  Future<void> _openMoodPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodPopupSheet(
        firstName: _firstName,
        onMoodSelected: (level) => _logMood(level),
      ),
    );
  }

  /// Show a friendly mood check-in pop-up on app start if not yet logged today.
  Future<void> _maybeShowMoodPopup() async {
    if (!mounted) return;
    // Check if already logged offline today
    final offlineMood = await OfflineMoodQueue().getTodayOfflineMood();
    if (offlineMood != null) {
      if (mounted) {
        setState(() {
          _todayMoodLevel = offlineMood;
          _dailyQuests[0]['completed'] = true;
        });
      }
      return;
    }

    try {
      final now = DateTime.now();
      final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
      if (moodData is List) {
        final todayEntries = moodData.where((e) {
          final dt = _parseDateLocal(e['created_at']);
          return dt != null &&
              dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        }).toList();

        if (todayEntries.isNotEmpty) {
          if (mounted) {
            setState(() {
              _todayMoodLevel = (todayEntries.first['mood_level'] as num?)?.toInt();
              _dailyQuests[0]['completed'] = true;
            });
          }
          return; // Already logged — skip popup
        }
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
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      // 1. Check mood from API with timezone-accurate local date comparison
      try {
        final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
        if (moodData is List) {
          final todayEntries = moodData.where((e) {
            final dt = _parseDateLocal(e['created_at']);
            return dt != null &&
                dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day;
          }).toList();

          if (todayEntries.isNotEmpty) {
            moodCompleted = true;
            todayLevel = (todayEntries.first['mood_level'] as num?)?.toInt();
          }
        }
      } catch (_) {}

      // 1b. Check local offline mood queue if not detected from API
      if (!moodCompleted) {
        final offlineToday = await OfflineMoodQueue().getTodayOfflineMood();
        if (offlineToday != null) {
          moodCompleted = true;
          todayLevel = offlineToday;
        }
      }

      // 2. Check journal — local storage first (written on every save), then API
      final storage = const FlutterSecureStorage();
      final savedJournal = await storage.read(key: 'journal_$todayStr');
      if (savedJournal != null && savedJournal.trim().isNotEmpty) {
        journalCompleted = true;
      } else {
        // Backend returns List[JournalRead], NOT a single Map — check the list length
        try {
          final jToday = await ApiClient().get(ApiConfig.journalToday, silent: true);
          if (jToday is List && jToday.isNotEmpty) {
            journalCompleted = true;
            // Cache the first entry content locally so future refreshes are instant
            final firstContent = jToday.first['content']?.toString() ?? '';
            if (firstContent.trim().isNotEmpty) {
              await storage.write(key: 'journal_$todayStr', value: firstContent);
            }
          } else if (jToday is Map &&
              jToday['content'] != null &&
              jToday['content'].toString().trim().isNotEmpty) {
            // Fallback: old single-object shape (future-proof)
            journalCompleted = true;
          }
        } catch (_) {}
      }

      // 3. Check mindfulness
      final savedMindfulness = await storage.read(key: 'mindfulness_$todayStr');
      if (savedMindfulness == 'completed') {
        mindfulnessCompleted = true;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        // Only update mood level if the API actually returned one this call;
        // otherwise preserve the existing value so it isn't reset to null on refresh.
        if (todayLevel != null) _todayMoodLevel = todayLevel;
        _dailyQuests[0]['completed'] = moodCompleted || _todayMoodLevel != null;
        _dailyQuests[1]['completed'] = journalCompleted;
        _dailyQuests[2]['completed'] = mindfulnessCompleted;
      });
    }
  }

  DateTime? _parseDateLocal(dynamic created) {
    if (created == null) return null;
    try {
      final str = created.toString();
      final dt = DateTime.parse(str);
      return dt.isUtc ? dt.toLocal() : (str.endsWith('Z') || str.contains('+') ? dt.toLocal() : DateTime.parse('${str}Z').toLocal());
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchStreak() async {
    try {
      final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
      if (moodData is! List || !mounted) return;

      final Set<String> daysWithMood = {};
      for (final entry in moodData) {
        final dt = _parseDateLocal(entry['created_at']);
        if (dt != null) {
          daysWithMood.add(DateFormat('yyyy-MM-dd').format(dt));
        }
      }
      if (_todayMoodLevel != null) {
        daysWithMood.add(DateFormat('yyyy-MM-dd').format(DateTime.now()));
      }

      int streak = 0;
      final today = DateTime.now();
      for (int i = 0; i < 365; i++) {
        final checkDay = today.subtract(Duration(days: i));
        final dayStr = DateFormat('yyyy-MM-dd').format(checkDay);
        if (daysWithMood.contains(dayStr)) {
          streak++;
        } else {
          break;
        }
      }

      if (mounted) {
        setState(() {
          _streak = streak;
          _goal = 30; // 30-day wellness goal
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMoodTrends() async {
    try {
      final moodData = await ApiClient().get(ApiConfig.mood, silent: true);
      if (moodData is! List || !mounted) return;

      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      final List<double?> weeklyMoods = List.filled(7, null);
      final List<String?> weeklyLatestEmojis = List.filled(7, null);
      final List<int> weeklyLogCounts = List.filled(7, 0);
      double totalSum = 0;
      int loggedDays = 0;

      for (int i = 0; i < 7; i++) {
        final targetDate = monday.add(Duration(days: i));

        final dayEntries = moodData.where((e) {
          final dt = _parseDateLocal(e['created_at']);
          return dt != null &&
              dt.year == targetDate.year &&
              dt.month == targetDate.month &&
              dt.day == targetDate.day;
        }).toList();

        if (dayEntries.isNotEmpty) {
          double daySum = 0;
          for (final entry in dayEntries) {
            final level = (entry['mood_level'] as num?)?.toDouble() ?? 3.0;
            daySum += level;
          }
          final avgLevel = (daySum / dayEntries.length).clamp(1.0, 5.0);
          weeklyMoods[i] = avgLevel;
          weeklyLogCounts[i] = dayEntries.length;

          // Day's latest mood emoji: first entry in sorted descending list
          final latestLevel = (dayEntries.first['mood_level'] as num?)?.toInt() ?? avgLevel.round();
          weeklyLatestEmojis[i] = _getEmojiOnly(latestLevel);

          totalSum += avgLevel;
          loggedDays++;
        }
      }

      // If user checked in today but it's not yet in the server response, merge it
      if (_todayMoodLevel != null) {
        final todayIdx = DateTime.now().weekday - 1;
        if (weeklyMoods[todayIdx] == null) {
          weeklyMoods[todayIdx] = _todayMoodLevel!.toDouble();
          weeklyLatestEmojis[todayIdx] = _getEmojiOnly(_todayMoodLevel!);
          weeklyLogCounts[todayIdx] = 1;
          totalSum += _todayMoodLevel!.toDouble();
          loggedDays++;
        } else {
          weeklyLatestEmojis[todayIdx] = _getEmojiOnly(_todayMoodLevel!);
        }
      }

      if (mounted) {
        setState(() {
          _weeklyMoods = weeklyMoods;
          _weeklyLatestEmojis = weeklyLatestEmojis;
          _weeklyLogCounts = weeklyLogCounts;
          _totalLogsThisWeek = loggedDays;
          _weeklyAverage = loggedDays > 0 ? (totalSum / loggedDays) : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
    final connectivity = ConnectivityService();
    int count = 0;
    if (!connectivity.isOnline) {
      final cached = await CacheService.readMap('home_unread_count');
      if (cached != null && mounted) {
        count = (cached['count'] as int?) ?? 0;
        setState(() => _unreadCount = count);
        if (count > 0) _ringBellAndChime();
      }
      return;
    }
    try {
      count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
        if (count > 0) _ringBellAndChime();
      }
      await CacheService.saveMap(
        'home_unread_count',
        {'count': count},
        ttlMinutes: 30,
      );
    } catch (_) {
      final cached = await CacheService.readMap('home_unread_count');
      if (cached != null && mounted) {
        count = (cached['count'] as int?) ?? 0;
        setState(() => _unreadCount = count);
        if (count > 0) _ringBellAndChime();
      }
    }
  }

  void _ringBellAndChime() {
    if (!mounted) return;
    _bellAnimController.forward(from: 0);
    if (!_hasPlayedEntryChime) {
      _hasPlayedEntryChime = true;
      AmbientAudioService.playNotificationChimeIfAllowed();
    }
  }

  Future<void> _onRefresh() async {
    await _fetchUnreadCount();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  String _greetingPeriodFilipino() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'umaga';
    if (hour < 18) return 'hapon';
    return 'gabi';
  }

  // ── Header (Logo + Quick Escape + Animated Bell + Profile Avatar Menu) ───
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
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Text(
            'Kausap AI',
            style: AppTextStyles.brandName.copyWith(color: AppColors.primary, fontSize: 20),
          ),
        ]),
        Row(children: [
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
            label: _unreadCount > 0 ? 'Notifications, $_unreadCount unread' : 'Notifications',
            button: true,
            child: GestureDetector(
              onTap: () async {
                HapticService.lightTap();
                final result = await Navigator.of(context).push(slideRoute(const NotificationsScreen()));
                _fetchUnreadCount();
                if (result == 'open_mood') {
                  _openMoodPickerSheet();
                }
              },
              child: ValueListenableBuilder<int>(
                valueListenable: _notificationService.unreadCountNotifier,
                builder: (context, count, _) {
                  final displayCount = count;
                  return AnimatedBuilder(
                    animation: _bellAnimController,
                    builder: (context, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Transform.rotate(
                            angle: displayCount > 0 ? _bellRotationAnim.value : 0.0,
                            origin: const Offset(0, -6),
                            child: Icon(
                              displayCount > 0
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_outlined,
                              color: displayCount > 0 ? AppColors.primary : AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                          if (displayCount > 0)
                            Positioned(
                              right: -5,
                              top: -4,
                              child: Transform.scale(
                                scale: _bellAnimController.isAnimating ? _badgeScaleAnim.value : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33EF4444),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Center(
                                    child: Text(
                                      displayCount > 9 ? '9+' : '$displayCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Poppins',
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser ?? widget.user;
              final name = user['first_name'] ?? 'U';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
              final avatarUrl = user['avatar_url'] as String?;
              final avatar = CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary.withAlpha(30),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                    ? Text(
                        initial,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              );
              return PopupMenuButton<String>(
                offset: const Offset(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                child: avatar,
                onSelected: (value) {
                  if (value == 'profile') {
                    HapticService.lightTap();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withAlpha(20),
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                              ? Text(initial,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                            const Text('View Profile & Settings', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ]),
      ],
    );
  }

  // ── Home Companion Hero Card ─────────────────────────────────────────────
  Widget _buildHomeCompanionHero() {
    final hasMood = _todayMoodLevel != null;
    final moodLabel = hasMood ? _getMoodEmojiAndLabel(_todayMoodLevel!) : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080077B6),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeCompanionAvatar(
            todayMood: _todayMoodLevel,
            firstName: _firstName,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text(
                    '🌱 Campus Wellness Shield',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Magandang ${_greetingPeriodFilipino()},\n${_firstName.isNotEmpty ? _firstName[0].toUpperCase() + _firstName.substring(1) : 'Friend'}! ✨',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasMood
                      ? 'Feeling $moodLabel right now • Keep blooming 🌱'
                      : 'How are you feeling right now? Tap a mood below 💙',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1-Tap Quick Mood Check-In Bar ────────────────────────────────────────
  Widget _build1TapMoodSection() {
    final hasLogged = _todayMoodLevel != null;
    final List<Map<String, dynamic>> moodOptions = [
      {'level': 1, 'emoji': '😞', 'label': 'Rough', 'color': const Color(0xFFEF4444)},
      {'level': 2, 'emoji': '😟', 'label': 'Low', 'color': const Color(0xFFF97316)},
      {'level': 3, 'emoji': '😐', 'label': 'Okay', 'color': const Color(0xFFF59E0B)},
      {'level': 4, 'emoji': '🙂', 'label': 'Good', 'color': const Color(0xFF10B981)},
      {'level': 5, 'emoji': '😄', 'label': 'Great', 'color': const Color(0xFF06B6D4)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Daily Mood Check-In',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasLogged ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasLogged ? 'Checked In Today ✅' : '1-Tap Log',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: hasLogged ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moodOptions.map((opt) {
              final lvl = opt['level'] as int;
              final isCurrent = _todayMoodLevel == lvl;
              final Color col = opt['color'] as Color;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _logMood(lvl),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? col.withAlpha(25) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? col : const Color(0xFFE2E8F0),
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(opt['emoji'] as String, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? col : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildHomeCompanionHero(),
                    const SizedBox(height: 14),
                    _build1TapMoodSection(),
                    const SizedBox(height: 14),
                    HomeStreakCard(streak: _streak, goal: _goal),
                    const SizedBox(height: 14),
                    HomeSosBanner(
                      onTap: () => Navigator.of(context).push(slideRoute(const SosScreen())),
                    ),
                    const SizedBox(height: 14),
                    DailyQuestsCard(
                      dailyQuests: _dailyQuests,
                      onLogMoodTap: _openMoodPickerSheet,
                      onCompletedMoodTap: () => setState(() => _navIndex = 3),
                      onWriteJournalTap: () async {
                        final res = await Navigator.of(context).push(slideRoute(const DailyJournalScreen()));
                        if (res == true) {
                          _fetchQuests();
                          _fetchStreak();
                        }
                      },
                      onMindfulnessTap: () => setState(() => _navIndex = 1),
                    ),
                    const SizedBox(height: 14),
                    HomeQuickActionCard(
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
                    HomeQuickActionCard(
                      iconBg: AppColors.chatbotIcon,
                      icon: Icons.smart_toy_rounded,
                      iconColor: const Color(0xFF0077B6),
                      title: 'Talk to Kausap AI',
                      subtitle: '24/7 confidential wellness companion',
                      onTap: () => setState(() => _navIndex = 2),
                    ),
                    const SizedBox(height: 12),
                    HomeQuickActionCard(
                      iconBg: const Color(0xFFD1FAE5),
                      icon: Icons.self_improvement_rounded,
                      iconColor: const Color(0xFF059669),
                      title: 'Mindfulness Exercises',
                      subtitle: 'Breathe, meditate & relax',
                      onTap: () => setState(() => _navIndex = 1),
                    ),
                    const SizedBox(height: 12),
                    HomeQuickActionCard(
                      iconBg: const Color(0xFFEFF6FF),
                      icon: Icons.analytics_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Self-Assessments',
                      subtitle: 'PHQ-9 Depression & GAD-7 Anxiety Screeners',
                      onTap: () => setState(() => _navIndex = 3),
                    ),
                    const SizedBox(height: 16),
                    const HomeQuoteCard(),
                    const SizedBox(height: 16),
                    HomeSuggestedActivity(
                      onActivityCompleted: () {
                        _fetchQuests();
                        _fetchStreak();
                      },
                    ),
                    const SizedBox(height: 16),
                    HomeScreenerPromoCard(
                      onTakeAssessment: () => setState(() => _navIndex = 3),
                    ),
                    const SizedBox(height: 16),
                    HomeArticlesSection(
                      homeArticles: _homeArticles,
                      todayMoodLevel: _todayMoodLevel,
                      onSeeAllTap: () => setState(() => _navIndex = 4),
                    ),
                    const SizedBox(height: 16),
                    HomeMoodTrendsCard(
                      weeklyMoods: _weeklyMoods,
                      latestEmojis: _weeklyLatestEmojis,
                      logCounts: _weeklyLogCounts,
                      weeklyAverage: _weeklyAverage,
                      totalLogsThisWeek: _totalLogsThisWeek,
                      onInsightsTap: () => setState(() {
                        _insightsRefreshKey++;
                        _navIndex = 3;
                      }),
                    ),
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

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.fitness_center_rounded, 'Activity'),
      (Icons.chat_bubble_rounded, 'Kausap'),
      (Icons.analytics_rounded, 'Insights'),
      (Icons.article_rounded, 'Articles'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 5.5,
            offset: const Offset(0, -2),
          ),
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
                        _refreshHome();
                      } else {
                        setState(() {
                          _navIndex = i;
                          if (i == 3) _insightsRefreshKey++;
                        });
                        if (i == 0) {
                          _fetchQuests();
                          _fetchStreak();
                          _fetchMoodTrends();
                        }
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
                            color: selected ? AppColors.primary : AppColors.textPrimary,
                            semanticLabel: items[i].$2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].$2,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: selected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildHomeTab(), // 0 – Home
      ActivityScreen(
        onActivityCompleted: () {
          _fetchQuests();
          _fetchStreak();
        },
      ), // 1 – Activity
      ChatbotScreen(
        contextualMoodLevel: _todayMoodLevel,
        userName: _firstName,
      ), // 2 – Kausap AI
      StudentInsightsScreen(
        refreshTrigger: _insightsRefreshKey,
      ), // 3 – Insights & Screeners
      const ArticlesScreen(), // 4 – Articles
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
}
