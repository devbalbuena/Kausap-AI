import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'activity_screen.dart';

class ActivityStartScreen extends StatelessWidget {
  final ActivityItem activity;

  const ActivityStartScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          // Scrollable body content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTags(),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'What is this?',
                      child: Text(
                        activity.whatIsThis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF404944),
                          height: 1.71,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'How it works',
                      child: Column(
                        children: activity.steps.map(_buildStep).toList(),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          // Back button over hero
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Material(
                color: Colors.white.withAlpha(40),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
          // Fixed bottom Start button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStartButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0x4C005DA7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Icon(activity.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),
          Text(
            activity.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 10),
          // Duration + difficulty pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${activity.duration} minutes',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white.withAlpha(128),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.trending_up_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 4),
                Text(
                  activity.difficulty,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: activity.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration: BoxDecoration(
            color: tag.bg,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: tag.border),
          ),
          child: Text(
            tag.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tag.text,
              letterSpacing: 0.14,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D405B),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildStep(ActivityStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6FF),
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.number}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D405B),
                letterSpacing: 0.14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D405B),
                    letterSpacing: 0.14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3D405B),
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(31),
            blurRadius: 5.5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity started! 🎉'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text(
                'Start Activity',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
