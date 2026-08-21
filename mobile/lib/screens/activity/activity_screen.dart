import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'activity_start_screen.dart';

// ── Data model for an activity ──────────────────────────────────────────────
class ActivityItem {
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final String category;
  final IconData icon;
  final List<ActivityTag> tags;
  final String whatIsThis;
  final List<ActivityStep> steps;

  const ActivityItem({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.tags,
    required this.whatIsThis,
    required this.steps,
  });
}

class ActivityTag {
  final String label;
  final Color bg;
  final Color border;
  final Color text;

  const ActivityTag({
    required this.label,
    required this.bg,
    required this.border,
    required this.text,
  });
}

class ActivityStep {
  final int number;
  final String title;
  final String description;

  const ActivityStep({
    required this.number,
    required this.title,
    required this.description,
  });
}

// ── Static data matching Figma ───────────────────────────────────────────────
const activityList = [
  ActivityItem(
    title: '4-7-8 Breathing',
    description: 'A quick technique to reduce anxiety and promote better sleep.',
    duration: '5 min',
    difficulty: 'Easy',
    category: 'Breathing',
    icon: Icons.air_rounded,
    tags: [
      ActivityTag(label: 'Anxiety', bg: AppColors.tagGreenBg, border: AppColors.tagGreenBorder, text: AppColors.tagGreenText),
      ActivityTag(label: 'Stress', bg: AppColors.tagOrangeBg, border: Color(0x1A712611), text: AppColors.tagOrangeText),
      ActivityTag(label: 'Sleep issues', bg: AppColors.tagBlueBg, border: Color(0x4DC0C9C2), text: AppColors.tagBlueText),
    ],
    whatIsThis:
        'The 4-7-8 breathing technique, also known as "relaxing breath," involves breathing in for 4 seconds, '
        'holding the breath for 7 seconds, and exhaling for 8 seconds. This pattern aims to reduce anxiety or help '
        'people get to sleep. It acts as a natural tranquilizer for the nervous system, bringing your body into a state of deep relaxation.',
    steps: [
      ActivityStep(number: 1, title: 'Inhale', description: 'Close your mouth and inhale quietly through your nose to a mental count of four.'),
      ActivityStep(number: 2, title: 'Hold', description: 'Hold your breath for a count of seven.'),
      ActivityStep(number: 3, title: 'Exhale', description: 'Exhale completely through your mouth, making a whoosh sound to a count of eight.'),
      ActivityStep(number: 4, title: 'Repeat', description: 'This completes one cycle. Repeat the cycle three more times for a total of four breaths.'),
    ],
  ),
  ActivityItem(
    title: 'Guided Meditation',
    description: 'Find your center with a soothing voice guiding you through deep relaxation.',
    duration: '15 min',
    difficulty: 'Medium',
    category: 'Meditation',
    icon: Icons.self_improvement_rounded,
    tags: [
      ActivityTag(label: 'Stress', bg: AppColors.tagOrangeBg, border: Color(0x1A712611), text: AppColors.tagOrangeText),
      ActivityTag(label: 'Anxiety', bg: AppColors.tagGreenBg, border: AppColors.tagGreenBorder, text: AppColors.tagGreenText),
    ],
    whatIsThis:
        'Guided meditation is a form of meditation where a narrator guides you through a relaxing mental journey. '
        'It helps quiet the mind, reduce stress hormones, and cultivate a deeper sense of inner peace and self-awareness.',
    steps: [
      ActivityStep(number: 1, title: 'Find a comfortable position', description: 'Sit or lie down in a relaxed position. Close your eyes.'),
      ActivityStep(number: 2, title: 'Focus on your breath', description: 'Take a few deep breaths, letting go of tension with each exhale.'),
      ActivityStep(number: 3, title: 'Follow the guide', description: 'Listen carefully and allow the words to paint a calming picture in your mind.'),
      ActivityStep(number: 4, title: 'Return gently', description: 'When the session ends, slowly bring your awareness back to the room.'),
    ],
  ),
  ActivityItem(
    title: 'Gratitude Journal',
    description: 'Reflect on three things you are grateful for today to shift your perspective.',
    duration: '10 min',
    difficulty: 'Easy',
    category: 'Journaling',
    icon: Icons.edit_note_rounded,
    tags: [
      ActivityTag(label: 'Mood', bg: AppColors.tagGreenBg, border: AppColors.tagGreenBorder, text: AppColors.tagGreenText),
      ActivityTag(label: 'Mindfulness', bg: AppColors.tagBlueBg, border: Color(0x4DC0C9C2), text: AppColors.tagBlueText),
    ],
    whatIsThis:
        'Gratitude journaling is the practice of regularly writing down things you are thankful for. '
        'Research shows it can significantly increase well-being, improve sleep, and reduce stress by shifting focus from what is wrong to what is right.',
    steps: [
      ActivityStep(number: 1, title: 'Open your journal', description: 'Find a quiet space and open a blank page.'),
      ActivityStep(number: 2, title: 'Write 3 gratitudes', description: 'Write down 3 specific things you are grateful for today, and why.'),
      ActivityStep(number: 3, title: 'Reflect', description: 'Spend a moment really feeling the appreciation for each item you wrote.'),
    ],
  ),
  ActivityItem(
    title: 'Mindful Walking',
    description: 'Connect with nature and your body through a structured, observant walk.',
    duration: '20 min',
    difficulty: 'Easy',
    category: 'Exercise',
    icon: Icons.directions_walk_rounded,
    tags: [
      ActivityTag(label: 'Stress', bg: AppColors.tagOrangeBg, border: Color(0x1A712611), text: AppColors.tagOrangeText),
      ActivityTag(label: 'Energy', bg: AppColors.tagGreenBg, border: AppColors.tagGreenBorder, text: AppColors.tagGreenText),
    ],
    whatIsThis:
        'Mindful walking combines gentle physical exercise with mindfulness. '
        'Instead of walking on autopilot, you consciously pay attention to your body movements, breath, and surroundings to ground yourself in the present moment.',
    steps: [
      ActivityStep(number: 1, title: 'Start slow', description: 'Begin walking at a slow, comfortable pace.'),
      ActivityStep(number: 2, title: 'Focus on your feet', description: 'Notice how each foot lifts, moves forward, and makes contact with the ground.'),
      ActivityStep(number: 3, title: 'Engage your senses', description: 'Notice what you see, hear, smell, and feel around you without judgment.'),
      ActivityStep(number: 4, title: 'Return to breath', description: 'Whenever your mind wanders, gently return focus to your breathing and steps.'),
    ],
  ),
];

const _categories = ['All', 'Meditation', 'Breathing', 'Journaling', 'Exercise'];

// ── Main Activity Screen ─────────────────────────────────────────────────────
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const _storage = FlutterSecureStorage();
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, bool> _completedToday = {};
  int _activityStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reads per-activity completion keys for today and updates [_completedToday] and [_activityStreak].
  Future<void> _loadCompletions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, bool> result = {};
    for (final a in activityList) {
      final id = a.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
      final val = await _storage.read(key: 'activity_${id}_$today');
      result[id] = val == 'completed';
    }

    // Calculate dynamic activity streak from activity_history
    int streak = 0;
    try {
      final rawHistory = await _storage.read(key: 'activity_history');
      if (rawHistory != null) {
        final history = jsonDecode(rawHistory) as List;
        final Set<String> activeDates = {};
        for (final item in history) {
          final date = item['date'] as String?;
          if (date != null && date.length >= 10) {
            activeDates.add(date.substring(0, 10));
          }
        }

        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

        final startDay = activeDates.contains(todayStr)
            ? now
            : (activeDates.contains(yesterdayStr) ? now.subtract(const Duration(days: 1)) : null);

        if (startDay != null) {
          for (int i = 0; i < 365; i++) {
            final check = DateFormat('yyyy-MM-dd').format(startDay.subtract(Duration(days: i)));
            if (activeDates.contains(check)) {
              streak++;
            } else {
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _completedToday = result;
        _activityStreak = streak;
      });
    }
  }

  /// Navigate to ActivityStartScreen then reload completions when returning.
  Future<void> _openActivity(ActivityItem activity) async {
    await Navigator.of(context).push(slideRoute(ActivityStartScreen(activity: activity)));
    _loadCompletions();
  }

  /// Show the activity history bottom sheet.
  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ActivityHistorySheet(),
    );
  }

  String _activityId(ActivityItem a) =>
      a.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');

  List<ActivityItem> get _filteredActivities {
    final category = _categories[_selectedCategory];
    return activityList.where((a) {
      final matchesCategory = category == 'All' || a.category == category;
      final matchesSearch = _searchQuery.isEmpty ||
          a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 16),
            // Title section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTitleSection(),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 12),
            // Category tabs (horizontally scrollable)
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  // Streak card
                  _buildStreakCard(),
                  const SizedBox(height: 10),
                  // Activity cards
                  ..._filteredActivities.map((activity) => _buildActivityCard(activity)),
                  if (_filteredActivities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'No activities found.',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
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
          ],
        ),
        Row(
          children: [
            // History button
            Semantics(
              label: 'View activity history',
              button: true,
              child: GestureDetector(
                onTap: _showHistory,
                child: const Icon(Icons.history_rounded,
                    color: AppColors.textPrimary, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
            const SizedBox(width: 12),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser ?? {};
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
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activities',
          style: AppTextStyles.heading1.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.64,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find your center with guided exercises.',
          style: AppTextStyles.body.copyWith(
            color: const Color(0xFF414751),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0x1F3D405B)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: Color(0xFF727272), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.body.copyWith(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search Activities...',
                hintStyle: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF727272),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.categoryChipBg,
                borderRadius: BorderRadius.circular(9999),
                border: selected
                    ? null
                    : Border.all(color: const Color(0x33C0C9C2)),
                boxShadow: selected
                    ? [const BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1))]
                    : null,
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF404944),
                  letterSpacing: 0.14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.streakCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.streakCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140078D4),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Consistency Key',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.streakCardText,
                  letterSpacing: 0.14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _activityStreak == 0
                ? 'Start your activity streak!'
                : (_activityStreak == 1
                    ? '1-day activity streak!'
                    : '$_activityStreak-day activity streak!'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.streakCardTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _activityStreak == 0
                ? 'Complete an exercise today to build your daily habit.'
                : "Keep nurturing your mind. You're doing great.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.streakCardBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity) {
    final id = _activityId(activity);
    final isDone = _completedToday[id] ?? false;

    return GestureDetector(
      onTap: () => _openActivity(activity),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF22C55E).withAlpha(80)
                    : const Color(0x1AC0C9C2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140078D4),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D405B),
                        ),
                      ),
                    ),
                    if (isDone)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF22C55E), size: 22),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3D405B),
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: Color(0xFF707479)),
                        const SizedBox(width: 4),
                        Text(
                          activity.duration,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF707479),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          activity.difficulty,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF707479),
                          ),
                        ),
                      ],
                    ),
                    // Start / Done button
                    GestureDetector(
                      onTap: () => _openActivity(activity),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFDCFCE7)
                              : AppColors.categoryChipBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isDone ? 'Done ✓' : 'Start',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFF16A34A)
                                : AppColors.primary,
                            letterSpacing: 0.14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity History Bottom Sheet ─────────────────────────────────────────────
class ActivityHistorySheet extends StatefulWidget {
  const ActivityHistorySheet({super.key});

  @override
  State<ActivityHistorySheet> createState() => _ActivityHistorySheetState();
}

class _ActivityHistorySheetState extends State<ActivityHistorySheet> {
  static const _storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final raw = await _storage.read(key: 'activity_history');
    if (mounted) {
      setState(() {
        _history = raw != null
            ? List<Map<String, dynamic>>.from(
                (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
            : [];
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      if (d.year == today.year && d.month == today.month && d.day == today.day) {
        return 'Today';
      }
      if (d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day) {
        return 'Yesterday';
      }
      return DateFormat('MMM d, yyyy').format(d);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Activity History', style: AppTextStyles.heading2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌱',
                                style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              'No activities completed yet.\nStart one now!',
                              style: AppTextStyles.subheading.copyWith(
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = _history[index];
                          final dateLabel = _formatDate(
                              entry['date'] as String? ?? '');
                          final duration = _formatDuration(
                              (entry['durationSeconds'] as num?)?.toInt() ?? 0);
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.self_improvement_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              entry['title'] as String? ?? 'Activity',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              dateLabel,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
