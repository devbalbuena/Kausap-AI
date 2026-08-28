import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import 'home_companion_avatar.dart';

// ── Caring Support Modal Sheet (For Levels 1-3) ──────────────────────────────
class CaringSupportModal extends StatefulWidget {
  final int level;
  final String firstName;
  final VoidCallback onTalkToAi;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenMindfulness;
  final VoidCallback onOpenSos;

  const CaringSupportModal({
    super.key,
    required this.level,
    required this.firstName,
    required this.onTalkToAi,
    required this.onOpenJournal,
    required this.onOpenMindfulness,
    required this.onOpenSos,
  });

  @override
  State<CaringSupportModal> createState() => _CaringSupportModalState();
}

class _CaringSupportModalState extends State<CaringSupportModal> {
  final Set<String> _selectedTriggers = {};

  final List<String> _triggers = [
    '📚 Academics',
    '📝 Exam Stress',
    '😴 Exhaustion',
    '💭 Overthinking',
    '💔 Relationships',
    '🏡 Family',
    '🌧️ Feeling low',
  ];

  String _getTitle() {
    final name = widget.firstName.isNotEmpty
        ? widget.firstName[0].toUpperCase() + widget.firstName.substring(1)
        : 'friend';
    switch (widget.level) {
      case 1:
        return "I'm right here with you, $name 💙";
      case 2:
        return "Sending you warmth, $name 🌿";
      default:
        return "Checking in on you, $name ✨";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),

              // Living Mascot Avatar
              HomeCompanionAvatar(
                todayMood: widget.level,
                firstName: widget.firstName,
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                "It's completely okay to have heavy days. What's contributing to this feeling right now?",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Trigger Tag Selector Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _triggers.map((tag) {
                  final isSelected = _selectedTriggers.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      setState(() {
                        if (isSelected) {
                          _selectedTriggers.remove(tag);
                        } else {
                          _selectedTriggers.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ways to support you right now:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Action 1: Talk to Kausap AI
              _buildSupportTile(
                icon: Icons.chat_bubble_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'Talk with Kausap AI 💬',
                subtitle: 'Safe, 24/7 space to unpack what is on your mind',
                onTap: widget.onTalkToAi,
              ),
              const SizedBox(height: 8),

              // Action 2: Write in Daily Journal
              _buildSupportTile(
                icon: Icons.edit_note_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                title: 'Write in Daily Journal 📖',
                subtitle: 'Pour your thoughts into a private reflection space',
                onTap: widget.onOpenJournal,
              ),
              const SizedBox(height: 8),

              // Action 3: Calming Breath
              _buildSupportTile(
                icon: Icons.self_improvement_rounded,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                title: '2-Minute Calming Breath 🧘',
                subtitle: 'Guided box breathing to slow your heart rate',
                onTap: widget.onOpenMindfulness,
              ),

              // If level == 1 (Rough), add SOS Hotline shortcut
              if (widget.level == 1) ...[
                const SizedBox(height: 8),
                _buildSupportTile(
                  icon: Icons.sos_rounded,
                  iconBg: const Color(0xFFFFE4E6),
                  iconColor: const Color(0xFFE11D48),
                  title: 'Need Immediate Crisis Help? 🆘',
                  subtitle: 'Connect with campus guidance & 24/7 hotlines',
                  onTap: widget.onOpenSos,
                ),
              ],

              const SizedBox(height: 18),

              // Dismiss
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "I'm okay for now, thanks 🌿",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

// ── Positive Mood Celebration Sheet (For Levels 4-5) ─────────────────────────
class CelebrationModal extends StatelessWidget {
  final int level;
  final String firstName;
  final VoidCallback onOpenGratitudeJournal;
  final VoidCallback onTalkToAi;

  const CelebrationModal({
    super.key,
    required this.level,
    required this.firstName,
    required this.onOpenGratitudeJournal,
    required this.onTalkToAi,
  });

  @override
  Widget build(BuildContext context) {
    final name = firstName.isNotEmpty
        ? firstName[0].toUpperCase() + firstName.substring(1)
        : 'friend';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),

              // Living Mascot in celebratory style
              HomeCompanionAvatar(
                todayMood: level,
                firstName: firstName,
              ),
              const SizedBox(height: 12),

              // Celebration Heading
              Text(
                level == 5
                    ? 'Yay! So wonderful to hear, $name! 🌟'
                    : "That's fantastic, $name! 😊",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'What made today feel so good? Anchoring positive wins strengthens long-term emotional resilience!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Action 1: Log a Gratitude Note
              _buildCelebrationTile(
                icon: Icons.favorite_rounded,
                iconBg: const Color(0xFFFFE4E6),
                iconColor: const Color(0xFFE11D48),
                title: 'Log a Gratitude Note 📝',
                subtitle: "Capture 3 things you're grateful for today",
                onTap: onOpenGratitudeJournal,
              ),
              const SizedBox(height: 8),

              // Action 2: Save this Moment in Journal
              _buildCelebrationTile(
                icon: Icons.auto_stories_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                title: 'Save this Moment in Journal 🎨',
                subtitle: 'Record what went well and celebrate your growth',
                onTap: onOpenGratitudeJournal,
              ),
              const SizedBox(height: 8),

              // Action 3: Share with Kausap AI
              _buildCelebrationTile(
                icon: Icons.smart_toy_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'Share the Good News with Kausap AI 💬',
                subtitle: 'Tell your companion what made you smile today!',
                onTap: onTalkToAi,
              ),

              const SizedBox(height: 18),

              // Dismiss
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Keep enjoying your day! ✨',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

// ── Mood Quick-Check Pop-up Sheet ─────────────────────────────────────────────
class MoodPopupSheet extends StatefulWidget {
  final String firstName;
  final Future<void> Function(int level) onMoodSelected;

  const MoodPopupSheet({
    super.key,
    required this.firstName,
    required this.onMoodSelected,
  });

  @override
  State<MoodPopupSheet> createState() => _MoodPopupSheetState();
}

class _MoodPopupSheetState extends State<MoodPopupSheet>
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
                final label = item['label'] as String;
                final level = item['level'] as int;
                return Semantics(
                  label: 'Check in feeling $label, level $level of 5',
                  button: true,
                  child: GestureDetector(
                    onTap: _isSaving ? null : () => _select(level),
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
                          label,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Skip link
            Semantics(
              label: 'Skip mood check-in for now',
              button: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
