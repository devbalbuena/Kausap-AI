import 'package:flutter/material.dart';

class ArticleModel {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String readTime;
  final String author;
  final String authorRole;
  final IconData categoryIcon;
  final Color themeColor;
  final List<ArticleSection> sections;
  final String? relatedActivityTitle;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readTime,
    required this.author,
    required this.authorRole,
    required this.categoryIcon,
    required this.themeColor,
    required this.sections,
    this.relatedActivityTitle,
  });
}

class ArticleSection {
  final String heading;
  final String content;
  final List<String>? keyPoints;

  const ArticleSection({
    required this.heading,
    required this.content,
    this.keyPoints,
  });
}

class ArticlesData {
  static const List<String> categories = [
    'All',
    'Anxiety & Stress',
    'Sleep & Rest',
    'Mindfulness',
    'Relationships',
    'Student Life',
  ];

  static const List<ArticleModel> all = [
    ArticleModel(
      id: 'grounding-techniques-for-anxiety',
      title: '5 Grounding Techniques When Anxiety Hits',
      subtitle: 'Simple somatic tools to regain your calm in under 3 minutes.',
      category: 'Anxiety & Stress',
      readTime: '3 min read',
      author: 'Dr. Kim Vance',
      authorRole: 'Clinical Psychologist',
      categoryIcon: Icons.spa_rounded,
      themeColor: Color(0xFF10B981),
      relatedActivityTitle: '4-7-8 Breathing',
      sections: [
        ArticleSection(
          heading: 'What is Grounding?',
          content:
              'Grounding is a set of somatic strategies that help detach you from emotional pain (like racing thoughts, panic, or overwhelm) by anchoring you directly into the physical present moment.',
        ),
        ArticleSection(
          heading: 'The 5-4-3-2-1 Sensory Method',
          content:
              'Look around your immediate environment and consciously identify:',
          keyPoints: [
            '5 things you can see (a leaf, a shadow, a pen, your shoes)',
            '4 things you can physically feel (the chair beneath you, your shirt texture)',
            '3 things you can hear (clock ticking, ambient traffic, your breath)',
            '2 things you can smell (coffee, fresh air, clean clothes)',
            '1 thing you can taste (or a single deep sip of cold water)',
          ],
        ),
        ArticleSection(
          heading: 'Why This Works',
          content:
              'When you direct cognitive bandwidth toward sensory observation, you signal safety to your amygdala (the brain\'s alarm center), lowering heart rate and activating your parasympathetic nervous system.',
        ),
      ],
    ),
    ArticleModel(
      id: 'building-better-sleep-habits',
      title: 'The Science of Restorative Sleep & Nighttime Routine',
      subtitle: 'How to calm a busy mind before bed and wake up truly refreshed.',
      category: 'Sleep & Rest',
      readTime: '4 min read',
      author: 'Dr. Min Santos',
      authorRole: 'Sleep & Wellness Specialist',
      categoryIcon: Icons.nightlight_round,
      themeColor: Color(0xFF6366F1),
      relatedActivityTitle: 'Guided Meditation',
      sections: [
        ArticleSection(
          heading: 'Why Sleep Quality Beats Quantity',
          content:
              'Deep slow-wave sleep and REM sleep are vital for cognitive repair and emotional regulation. Going to bed with an activated nervous system keeps cortisol elevated, preventing deep sleep cycles.',
        ),
        ArticleSection(
          heading: '3 Habits for Better Sleep Tonight',
          content:
              'Small adjustments to your evening routine can transform your rest:',
          keyPoints: [
            'Dim lights 60 minutes before bed to stimulate natural melatonin release.',
            'Do a "Brain Dump" journal session: write down tomorrow\'s tasks to close cognitive loops.',
            'Keep your room cool (between 18°C–21°C) to facilitate your body\'s natural core temperature drop.',
          ],
        ),
        ArticleSection(
          heading: 'Evening Wind-Down Prompt',
          content:
              'Take 5 slow breaths, relax your jaw, unclench your shoulders, and remind yourself: "I have done enough for today. Tomorrow is a fresh start."',
        ),
      ],
    ),
    ArticleModel(
      id: 'daily-mindfulness-in-busy-life',
      title: 'Mindfulness for People Who Are Too Busy to Meditate',
      subtitle: 'How to integrate micro-mindfulness into your daily Filipino lifestyle.',
      category: 'Mindfulness',
      readTime: '3 min read',
      author: 'Coach Jeon',
      authorRole: 'Mindfulness Practitioner',
      categoryIcon: Icons.self_improvement_rounded,
      themeColor: Color(0xFF0EA5E9),
      relatedActivityTitle: 'Mindful Walking',
      sections: [
        ArticleSection(
          heading: 'Meditation Doesn’t Require an Hour',
          content:
              'You do not need to sit cross-legged on a cushion for 45 minutes to enjoy the benefits of mindfulness. Micro-mindfulness practices throughout your day take less than 60 seconds each.',
        ),
        ArticleSection(
          heading: '3 Micro-Moments to Try Today',
          content:
              'Transform everyday routines into calming anchors:',
          keyPoints: [
            'Mindful Morning Sip: Focus purely on the warmth, aroma, and taste of your first cup of coffee or tea.',
            'Traffic/Commute Breath: When stopped at a red light or riding a jeep/train, take three deep belly breaths instead of checking notifications.',
            'Transition Pauses: Before opening a new meeting or class, pause and do one full conscious inhale and exhale.',
          ],
        ),
      ],
    ),
    ArticleModel(
      id: 'dealing-with-academic-burnout',
      title: 'Overcoming Academic and Work Burnout',
      subtitle: 'Recognize the signs of cognitive fatigue and recharge sustainably.',
      category: 'Student Life',
      readTime: '5 min read',
      author: 'Dr. Kim Vance',
      authorRole: 'Clinical Psychologist',
      categoryIcon: Icons.school_rounded,
      themeColor: Color(0xFFF59E0B),
      relatedActivityTitle: 'Gratitude Journal',
      sections: [
        ArticleSection(
          heading: 'Burnout vs Normal Tiredness',
          content:
              'Tiredness goes away with a weekend of rest. Burnout is a chronic state of physical, emotional, and mental exhaustion accompanied by cynicism and feeling ineffective.',
        ),
        ArticleSection(
          heading: 'Steps to Recover and Protect Your Energy',
          content:
              'Protecting your mental health during intense academic or work periods:',
          keyPoints: [
            'Implement strict digital boundaries: Turn off non-essential work notifications after 7 PM.',
            'Use the 50/10 Pomodoro Rhythm: Work focused for 50 minutes, then stand up and stretch for 10 minutes.',
            'Celebrate small wins: Acknowledge what you completed today rather than fixating exclusively on what remains on your to-do list.',
          ],
        ),
      ],
    ),
    ArticleModel(
      id: 'healthy-boundaries-with-family',
      title: 'Setting Healthy Boundaries in Filipino Families',
      subtitle: 'How to communicate personal limits with empathy and respect.',
      category: 'Relationships',
      readTime: '4 min read',
      author: 'Dr. Min Santos',
      authorRole: 'Family & Relationship Counselor',
      categoryIcon: Icons.favorite_border_rounded,
      themeColor: Color(0xFFEC4899),
      sections: [
        ArticleSection(
          heading: 'The Cultural Context',
          content:
              'In Filipino culture, family closeness (pakikisama, utang na loob) is cherished. However, without healthy boundaries, it can lead to emotional exhaustion and resentment.',
        ),
        ArticleSection(
          heading: 'How to Say "No" with Malasakit',
          content:
              'Phrases that set clear boundaries without creating conflict:',
          keyPoints: [
            '"I love being here for family, but right now I need to rest so I can show up well for everyone tomorrow."',
            '"I appreciate your advice, and I\'d like to think through this decision on my own pace."',
            '"I won\'t be able to commit to that this week, but let\'s catch up when my schedule clears."',
          ],
        ),
      ],
    ),
  ];
}
