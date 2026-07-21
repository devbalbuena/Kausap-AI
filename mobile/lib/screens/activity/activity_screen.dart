import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary.withAlpha(30),
              child: Text(
                'U',
                style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
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
            '3-day activity streak!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.streakCardTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Keep nurturing your mind. You're doing great.",
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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActivityStartScreen(activity: activity)),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x1AC0C9C2)),
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
            // Title
            Text(
              activity.title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D405B),
              ),
            ),
            const SizedBox(height: 4),
            // Description
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
            // Duration, difficulty, Start button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF707479)),
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
                // Start button
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ActivityStartScreen(activity: activity)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.categoryChipBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
    );
  }
}
