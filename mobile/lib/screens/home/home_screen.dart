import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_selection_screen.dart';
import '../checkin/daily_checkin_step1_screen.dart';

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

  String get _firstName => widget.user['first_name'] ?? 'User';

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: CustomScrollView(
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
                            _buildQuickActionCard(
                              iconBg: AppColors.checkinIcon,
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFFE74C3C),
                              title: 'How are you feeling today?',
                              subtitle: 'Tap to check-in',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DailyCheckinStep1Screen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionCard(
                              iconBg: AppColors.chatbotIcon,
                              icon: Icons.smart_toy_rounded,
                              iconColor: const Color(0xFF0077B6),
                              title: 'Chat with Kausap AI',
                              subtitle: 'Need someone to talk to?',
                              onTap: () {},
                            ),
                            const SizedBox(height: 16),
                            _buildUpcomingSessionCard(),
                            const SizedBox(height: 16),
                            _buildQuoteCard(),
                            const SizedBox(height: 16),
                            _buildSuggestedActivity(),
                            const SizedBox(height: 16),
                            _buildBookSessionCard(),
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
          const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary, size: 24),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showProfileMenu,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary.withAlpha(30),
              child: Text(
                _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('$_firstName\'s Account',
                  style: AppTextStyles.heading2),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('Sign Out',
                  style: AppTextStyles.body.copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
    const streak = 7;
    const goal = 30;
    const progress = streak / goal;
    return _card(
      child: Column(
        children: [
          Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text('$streak Day Streak!', style: AppTextStyles.heading2),
          ]),
          const SizedBox(height: 4),
          Text('Keep your wellness journey going',
              style: AppTextStyles.subheading),
          const SizedBox(height: 12),
          Stack(children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                  color: AppColors.streakTrack,
                  borderRadius: BorderRadius.circular(99)),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99)),
                alignment: Alignment.center,
                child: Text(
                  '$streak/$goal',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
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
    return GestureDetector(
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
              child: Icon(icon, color: iconColor, size: 24),
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
                color: AppColors.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Upcoming Session Card ─────────────────────────────────────────────────
  Widget _buildUpcomingSessionCard() {
    return Container(
      height: 172,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sessionCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UPCOMING SESSION',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('May 15, 2026 • 2:00 PM',
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text('with Ms. Maria Santos',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white, fontSize: 12)),
                ]),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    textStyle: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {},
                  child: const Text('View Session'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.spa_rounded,
              color: Colors.white.withAlpha(70), size: 80),
        ],
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
                  foregroundColor: Colors.white,
                  textStyle: AppTextStyles.button,
                ),
                onPressed: () {},
                child: const Text('Start Activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Book Session Card ─────────────────────────────────────────────────────
  Widget _buildBookSessionCard() {
    return Container(
      height: 172,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bookSessionCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 ON 1 SESSIONS',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.bookSessionText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Let\'s open up to the things that matter the most',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.bookSessionText, fontSize: 12),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.accentOrange,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    textStyle: AppTextStyles.label.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {},
                  child: const Text('Book a Session'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.content_paste_rounded,
              color: AppColors.accentOrange.withAlpha(100), size: 80),
        ],
      ),
    );
  }

  // ── Mood Trends ───────────────────────────────────────────────────────────
  Widget _buildMoodTrends() {
    // Mock weekly mood data 0-5 (Mon–Sun)
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [1.5, 2.5, 3.5, 1.5, 4.0, 5.0, 2.5];
    final todayIdx = DateTime.now().weekday - 1; // Mon=0

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bar_chart_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 6),
            Text('Mood Trends', style: AppTextStyles.heading2),
          ]),
          const SizedBox(height: 2),
          Text('Your Week at a Glance', style: AppTextStyles.subheading),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final h = (values[i] / 5.0) * 100;
                final isToday = i == todayIdx;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 20,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withAlpha(130),
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }),
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
      (Icons.calendar_today_rounded, 'Session'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                return GestureDetector(
                  onTap: () => setState(() => _navIndex = i),
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
        color: Colors.white,
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
