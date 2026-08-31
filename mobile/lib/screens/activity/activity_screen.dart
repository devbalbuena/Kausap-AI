import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../services/offline_mood_queue.dart';
import '../profile/profile_screen.dart';
import 'activity_start_screen.dart';

// ── Data model for an activity ──────────────────────────────────────────────
class ActivityItem {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final String category;
  final IconData icon;
  final List<Color> gradient;
  final List<ActivityTag> tags;
  final String whatIsThis;
  final List<ActivityStep> steps;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.gradient,
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

// ── Expanded Activity Library Tailored for Student Mental Health ────────────
const activityList = [
  ActivityItem(
    id: '4-7-8-breathing',
    title: '4-7-8 Relaxing Breath',
    description: 'A quick, powerful technique to ease anxiety and prepare for restful sleep.',
    duration: '5 min',
    difficulty: 'Easy',
    category: 'Breathing',
    icon: Icons.air_rounded,
    gradient: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    tags: [
      ActivityTag(label: 'Anxiety', bg: Color(0xFFDCFCE7), border: Color(0xFF86EFAC), text: Color(0xFF166534)),
      ActivityTag(label: 'Stress', bg: Color(0xFFFFEDD5), border: Color(0xFFFED7AA), text: Color(0xFF9A3412)),
      ActivityTag(label: 'Sleep', bg: Color(0xFFE0E7FF), border: Color(0xFFC7D2FE), text: Color(0xFF3730A3)),
    ],
    whatIsThis:
        'The 4-7-8 breathing technique, developed by Dr. Andrew Weil, involves inhaling for 4 seconds, '
        'holding for 7 seconds, and exhaling slowly for 8 seconds. It serves as a natural tranquilizer for your nervous system.',
    steps: [
      ActivityStep(number: 1, title: 'Inhale Quietly', description: 'Close your mouth and inhale quietly through your nose for 4 seconds.'),
      ActivityStep(number: 2, title: 'Hold Breath', description: 'Hold your breath comfortably for a count of 7 seconds.'),
      ActivityStep(number: 3, title: 'Exhale Completely', description: 'Exhale completely through your mouth with a gentle whoosh sound for 8 seconds.'),
      ActivityStep(number: 4, title: 'Repeat Cycles', description: 'Repeat this sequence for 4 cycles to feel your heart rate stabilize.'),
    ],
  ),
  ActivityItem(
    id: 'box-breathing',
    title: 'Box Breathing (4-4-4-4)',
    description: 'Master your focus and calm pre-exam panic with equal-duration breathing.',
    duration: '5 min',
    difficulty: 'Easy',
    category: 'Breathing',
    icon: Icons.grid_view_rounded,
    gradient: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    tags: [
      ActivityTag(label: 'Focus', bg: Color(0xFFE0F2FE), border: Color(0xFFBAE6FD), text: Color(0xFF0369A1)),
      ActivityTag(label: 'Exam Prep', bg: Color(0xFFFEF3C7), border: Color(0xFFFDE68A), text: Color(0xFF92400E)),
      ActivityTag(label: 'Grounding', bg: Color(0xFFDCFCE7), border: Color(0xFF86EFAC), text: Color(0xFF166534)),
    ],
    whatIsThis:
        'Also known as square breathing, Box Breathing is used by top performers and first responders '
        'to heighten mental clarity, lower cortisol, and instantly regain control during high-stress moments.',
    steps: [
      ActivityStep(number: 1, title: 'Inhale', description: 'Breathe in slowly through your nose for 4 seconds, feeling your lungs fill.'),
      ActivityStep(number: 2, title: 'Hold', description: 'Hold your breath gently at the top for 4 seconds without straining.'),
      ActivityStep(number: 3, title: 'Exhale', description: 'Release the air smoothly through your mouth for 4 seconds.'),
      ActivityStep(number: 4, title: 'Hold Empty', description: 'Hold your lungs empty for 4 seconds before the next breath.'),
    ],
  ),
  ActivityItem(
    id: '5-4-3-2-1-grounding',
    title: '5-4-3-2-1 Sensory Grounding',
    description: 'Halt overthinking and panic spirals by connecting with your immediate physical senses.',
    duration: '7 min',
    difficulty: 'Easy',
    category: 'Grounding',
    icon: Icons.nature_people_rounded,
    gradient: [Color(0xFF059669), Color(0xFF34D399)],
    tags: [
      ActivityTag(label: 'Overthinking', bg: Color(0xFFF3E8FF), border: Color(0xFFDDD6FE), text: Color(0xFF6B21A8)),
      ActivityTag(label: 'Panic Reset', bg: Color(0xFFFFE4E6), border: Color(0xFFFECDD3), text: Color(0xFF9F1239)),
      ActivityTag(label: 'Mindfulness', bg: Color(0xFFE0F2FE), border: Color(0xFFBAE6FD), text: Color(0xFF0369A1)),
    ],
    whatIsThis:
        'The 5-4-3-2-1 technique is an evidence-based grounding exercise that reconnects your racing mind '
        'to the present environment by activating all five physical senses one by one.',
    steps: [
      ActivityStep(number: 1, title: '5 Things You See', description: 'Look around and notice 5 distinct objects or colors in your room.'),
      ActivityStep(number: 2, title: '4 Things You Feel', description: 'Notice 4 physical sensations: your feet on the floor, clothing texture, chair support.'),
      ActivityStep(number: 3, title: '3 Things You Hear', description: 'Listen closely for 3 background sounds around you.'),
      ActivityStep(number: 4, title: '2 Things You Smell', description: 'Inhale gently and notice 2 subtle scents (fresh air, book, coffee).'),
      ActivityStep(number: 5, title: '1 Thing You Taste / Love', description: 'Focus on a taste or anchor on 1 thing you are grateful for today.'),
    ],
  ),
  ActivityItem(
    id: 'guided-meditation',
    title: 'Guided Body Scan & Calm',
    description: 'Release deep physical tension in your shoulders and neck after long study sessions.',
    duration: '15 min',
    difficulty: 'Medium',
    category: 'Meditation',
    icon: Icons.self_improvement_rounded,
    gradient: [Color(0xFF4F46E5), Color(0xFF818CF8)],
    tags: [
      ActivityTag(label: 'Tension Relief', bg: Color(0xFFE0E7FF), border: Color(0xFFC7D2FE), text: Color(0xFF3730A3)),
      ActivityTag(label: 'Stress', bg: Color(0xFFFFEDD5), border: Color(0xFFFED7AA), text: Color(0xFF9A3412)),
      ActivityTag(label: 'Restoration', bg: Color(0xFFDCFCE7), border: Color(0xFF86EFAC), text: Color(0xFF166534)),
    ],
    whatIsThis:
        'A body scan meditation systematically directs focused attention to different areas of your body, '
        'noticing sensations without judgment to release accumulated academic fatigue and tightness.',
    steps: [
      ActivityStep(number: 1, title: 'Settle In', description: 'Sit comfortably or lie down. Soften your jaw and let your eyes close.'),
      ActivityStep(number: 2, title: 'Scan from Feet Up', description: 'Notice sensations in your toes, moving gently up through your legs.'),
      ActivityStep(number: 3, title: 'Release Shoulders', description: 'Exhale deeply, dropping your shoulders and unclasping your hands.'),
      ActivityStep(number: 4, title: 'Full Body Peace', description: 'Feel your entire body resting in calm, grounded stillness.'),
    ],
  ),
  ActivityItem(
    id: 'self-compassion-break',
    title: 'Self-Compassion & Affirmation Break',
    description: 'Cultivate kindness towards yourself when facing tough academic challenges or burnout.',
    duration: '8 min',
    difficulty: 'Easy',
    category: 'Meditation',
    icon: Icons.favorite_rounded,
    gradient: [Color(0xFF9333EA), Color(0xFFC084FC)],
    tags: [
      ActivityTag(label: 'Self-Care', bg: Color(0xFFFCE7F3), border: Color(0xFFFBCFE8), text: Color(0xFF9D174D)),
      ActivityTag(label: 'Burnout', bg: Color(0xFFFEF3C7), border: Color(0xFFFDE68A), text: Color(0xFF92400E)),
      ActivityTag(label: 'Confidence', bg: Color(0xFFE0F2FE), border: Color(0xFFBAE6FD), text: Color(0xFF0369A1)),
    ],
    whatIsThis:
        'Designed by Dr. Kristin Neff, this practice helps students acknowledge difficult moments '
        'with kindness rather than harsh self-criticism, fostering emotional resilience and motivation.',
    steps: [
      ActivityStep(number: 1, title: 'Acknowledge the Struggle', description: 'Place a warm hand over your heart and silently say: "This is a moment of challenge."'),
      ActivityStep(number: 2, title: 'Common Humanity', description: 'Remind yourself: "Struggling is part of the human journey. I am not alone."'),
      ActivityStep(number: 3, title: 'Kind Affirmation', description: 'Offer yourself comforting words: "May I be kind to myself and give myself patience."'),
    ],
  ),
  ActivityItem(
    id: 'gratitude-journal',
    title: 'Gratitude & Perspective Shift',
    description: 'Anchor on positive wins and small campus blessings to boost long-term happiness.',
    duration: '10 min',
    difficulty: 'Easy',
    category: 'Journaling',
    icon: Icons.edit_note_rounded,
    gradient: [Color(0xFFD97706), Color(0xFFFBBF24)],
    tags: [
      ActivityTag(label: 'Perspective', bg: Color(0xFFFEF3C7), border: Color(0xFFFDE68A), text: Color(0xFF92400E)),
      ActivityTag(label: 'Happiness', bg: Color(0xFFDCFCE7), border: Color(0xFF86EFAC), text: Color(0xFF166534)),
      ActivityTag(label: 'Mindset', bg: Color(0xFFE0F2FE), border: Color(0xFFBAE6FD), text: Color(0xFF0369A1)),
    ],
    whatIsThis:
        'Gratitude journaling trains your brain to notice everyday blessings. '
        'Clinical studies show 10 minutes of gratitude significantly improves mood, sleep quality, and academic stamina.',
    steps: [
      ActivityStep(number: 1, title: 'Reflect on 3 Wins', description: 'Think of 3 specific moments or people that made today lighter.'),
      ActivityStep(number: 2, title: 'Write the Why', description: 'Write down why each moment was meaningful to your well-being.'),
      ActivityStep(number: 3, title: 'Savor the Feeling', description: 'Take 30 seconds to truly appreciate these gifts in your life.'),
    ],
  ),
  ActivityItem(
    id: 'mindful-walking',
    title: 'Mindful Campus Walk',
    description: 'Transform your walk between classes into a revitalizing mindfulness session.',
    duration: '15 min',
    difficulty: 'Easy',
    category: 'Exercise',
    icon: Icons.directions_walk_rounded,
    gradient: [Color(0xFFE11D48), Color(0xFFFB7185)],
    tags: [
      ActivityTag(label: 'Movement', bg: Color(0xFFFFE4E6), border: Color(0xFFFECDD3), text: Color(0xFF9F1239)),
      ActivityTag(label: 'Energy', bg: Color(0xFFFEF3C7), border: Color(0xFFFDE68A), text: Color(0xFF92400E)),
      ActivityTag(label: 'Nature', bg: Color(0xFFDCFCE7), border: Color(0xFF86EFAC), text: Color(0xFF166534)),
    ],
    whatIsThis:
        'Mindful walking bridges active physical movement with present-moment awareness. '
        'It energizes your body, reduces mental fog, and connects you with your campus surroundings.',
    steps: [
      ActivityStep(number: 1, title: 'Pace & Posture', description: 'Walk at a steady, relaxed pace. Keep your gaze soft and shoulders relaxed.'),
      ActivityStep(number: 2, title: 'Feel Footsteps', description: 'Pay attention to the rhythm of your heels touching the ground.'),
      ActivityStep(number: 3, title: 'Observe Nature', description: 'Notice the breeze, rustling trees, and sunlight without getting distracted by your phone.'),
    ],
  ),
];

const _categories = ['All', 'Favorites ❤️', 'Breathing', 'Meditation', 'Grounding', 'Journaling', 'Exercise'];

// ── Main Activity Screen ─────────────────────────────────────────────────────
class ActivityScreen extends StatefulWidget {
  final VoidCallback? onActivityCompleted;
  const ActivityScreen({super.key, this.onActivityCompleted});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const _storage = FlutterSecureStorage();
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, bool> _completedToday = {};
  Set<String> _favoriteIds = {};
  int _activityStreak = 0;
  int _totalMindfulMinutesThisWeek = 0;
  int? _todayMoodLevel;

  @override
  void initState() {
    super.initState();
    _loadCompletions();
    _loadFavorites();
    _loadStatsAndMood();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final raw = await _storage.read(key: 'favorite_activities');
      if (raw != null) {
        final list = List<String>.from(jsonDecode(raw));
        if (mounted) setState(() => _favoriteIds = list.toSet());
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String activityId) async {
    HapticService.lightTap();
    setState(() {
      if (_favoriteIds.contains(activityId)) {
        _favoriteIds.remove(activityId);
      } else {
        _favoriteIds.add(activityId);
      }
    });
    await _storage.write(key: 'favorite_activities', value: jsonEncode(_favoriteIds.toList()));
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

  Future<void> _loadStatsAndMood() async {
    // Check mood from API or offline
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
        if (todayEntries.isNotEmpty && mounted) {
          setState(() {
            _todayMoodLevel = (todayEntries.first['mood_level'] as num?)?.toInt();
          });
        }
      }
    } catch (_) {}

    if (_todayMoodLevel == null) {
      final offline = await OfflineMoodQueue().getTodayOfflineMood();
      if (offline != null && mounted) setState(() => _todayMoodLevel = offline);
    }

    // Calculate mindful minutes this week
    try {
      final rawHistory = await _storage.read(key: 'activity_history');
      if (rawHistory != null) {
        final history = jsonDecode(rawHistory) as List;
        final now = DateTime.now();
        final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        int totalSecs = 0;

        for (final item in history) {
          final dateStr = item['date'] as String?;
          if (dateStr != null) {
            final entryDate = DateTime.tryParse(dateStr);
            if (entryDate != null && entryDate.isAfter(monday.subtract(const Duration(days: 1)))) {
              final dur = (item['durationSeconds'] as num?)?.toInt() ?? 300;
              totalSecs += dur;
            }
          }
        }
        if (mounted) setState(() => _totalMindfulMinutesThisWeek = (totalSecs / 60).round());
      }
    } catch (_) {}
  }

  Future<void> _loadCompletions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, bool> result = {};
    for (final a in activityList) {
      final val = await _storage.read(key: 'activity_${a.id}_$today');
      result[a.id] = val == 'completed';
    }

    // Dynamic activity streak from activity_history
    int streak = 0;
    try {
      final rawHistory = await _storage.read(key: 'activity_history');
      if (rawHistory != null) {
        final history = jsonDecode(rawHistory) as List;
        final Set<String> activeDates = {};
        for (final item in history) {
          final dateStr = item['date'] as String?;
          if (dateStr != null && dateStr.isNotEmpty) {
            activeDates.add(dateStr);
          }
        }
        final now = DateTime.now();
        for (int i = 0; i < 365; i++) {
          final checkDate = now.subtract(Duration(days: i));
          final key = DateFormat('yyyy-MM-dd').format(checkDate);
          if (activeDates.contains(key)) {
            streak++;
          } else {
            break;
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

  ActivityItem _getRecommendedActivity() {
    if (_todayMoodLevel != null) {
      if (_todayMoodLevel! <= 1) {
        return activityList.firstWhere((a) => a.id == '5-4-3-2-1-grounding');
      } else if (_todayMoodLevel! == 2) {
        return activityList.firstWhere((a) => a.id == 'box-breathing');
      } else if (_todayMoodLevel! == 3) {
        return activityList.firstWhere((a) => a.id == 'self-compassion-break');
      } else {
        return activityList.firstWhere((a) => a.id == 'gratitude-journal');
      }
    }
    return activityList[0]; // Default 4-7-8
  }

  List<ActivityItem> get _filteredActivities {
    return activityList.where((activity) {
      // Category filter
      if (_selectedCategory == 1) {
        // Favorites
        if (!_favoriteIds.contains(activity.id)) return false;
      } else if (_selectedCategory > 1) {
        final cat = _categories[_selectedCategory].toLowerCase();
        if (activity.category.toLowerCase() != cat) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = activity.title.toLowerCase().contains(q);
        final matchDesc = activity.description.toLowerCase().contains(q);
        final matchTags = activity.tags.any((t) => t.label.toLowerCase().contains(q));
        if (!matchTitle && !matchDesc && !matchTags) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openActivity(ActivityItem activity) async {
    HapticService.lightTap();
    await Navigator.of(context).push(
      slideRoute(ActivityStartScreen(activity: activity)),
    );
    await _loadCompletions();
    await _loadStatsAndMood();
    widget.onActivityCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredActivities;
    final recommended = _getRecommendedActivity();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildCategoryChips(),
            const SizedBox(height: 16),

            // Spotlight Recommended Hero Card (if on All tab and no active search)
            if (_selectedCategory == 0 && _searchQuery.isEmpty) ...[
              _buildSpotlightHeroCard(recommended),
              const SizedBox(height: 16),
              _buildMindfulStatsBar(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Mindfulness Exercises',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${filtered.length} activities',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Activity List Cards
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered.map((activity) => _buildActivityCard(activity)),
          ],
        ),
      ),
    );
  }

  // ── Header (Title + Activity History + Avatar) ──────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mindfulness Hub',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Find your center with guided exercises',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Color(0xFF334155), size: 22),
          tooltip: 'Activity History',
          onPressed: () {
            HapticService.lightTap();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ActivityHistorySheet(),
            );
          },
        ),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.currentUser;
            final name = user?['first_name'] ?? 'U';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
            final avatarUrl = user?['avatar_url'] as String?;

            return GestureDetector(
              onTap: () {
                HapticService.lightTap();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withAlpha(25),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                    ? Text(
                        initial,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search breathing, meditation, grounding...',
          hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = index == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticService.lightTap();
                setState(() => _selectedCategory = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Spotlight Recommended Hero Card ───────────────────────────────────────
  Widget _buildSpotlightHeroCard(ActivityItem activity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activity.gradient.first,
            activity.gradient.last.withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: activity.gradient.first.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'Recommended for You Today',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleFavorite(activity.id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _favoriteIds.contains(activity.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _favoriteIds.contains(activity.id) ? const Color(0xFFFFE4E6) : Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activity.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            activity.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          activity.duration,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.difficulty,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _openActivity(activity),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 18, color: activity.gradient.first),
                      const SizedBox(width: 4),
                      Text(
                        'Start Now',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: activity.gradient.first,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mindful Stats Bar ─────────────────────────────────────────────────────
  Widget _buildMindfulStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Text(_activityStreak > 0 ? '🔥' : '🌱', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activityStreak == 1 ? '1 Day' : '$_activityStreak Days',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const Text('Active Streak', style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          Row(
            children: [
              const Text('⏱️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_totalMindfulMinutesThisWeek mins',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const Text('This Week', style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Activity Card ─────────────────────────────────────────────────────────
  Widget _buildActivityCard(ActivityItem activity) {
    final isDone = _completedToday[activity.id] ?? false;
    final isFav = _favoriteIds.contains(activity.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isDone ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openActivity(activity),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category tag + Favorite button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: activity.gradient),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(activity.icon, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.category.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: activity.gradient.first,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleFavorite(activity.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title & Description
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Tag Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: activity.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tag.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tag.border),
                      ),
                      child: Text(
                        tag.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: tag.text,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Bottom Meta Row: Duration + Difficulty + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          activity.duration,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFCBD5E1))),
                        const SizedBox(width: 10),
                        Text(
                          activity.difficulty,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isDone ? 'Do Again' : 'Start ➔',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDone ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Text('🔍', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            'No matching activities found',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your search or category filter.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
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
    try {
      final raw = await _storage.read(key: 'activity_history');
      if (raw != null) {
        final list = List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        if (mounted) {
          setState(() {
            _history = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: Color(0xFF0284C7), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Activity History',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Text(
                  '${_history.length} sessions',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🧘', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text(
                              'No activity logs yet',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Complete an exercise today to start tracking!',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final title = item['title'] as String? ?? 'Mindfulness Session';
                          final dateStr = item['date'] as String? ?? '';
                          final dur = (item['durationSeconds'] as num?)?.toInt() ?? 300;
                          final mins = (dur / 60).round();

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    '$mins mins',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                  ),
                                ),
                              ],
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
