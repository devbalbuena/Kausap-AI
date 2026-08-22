import 'dart:convert';
import 'package:flutter/material.dart';

class ArticleModel {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String readTime;
  final String author;
  final String authorRole;
  final String? imageUrl;
  final IconData categoryIcon;
  final Color themeColor;
  final List<ArticleSection> sections;
  final bool isPublished;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readTime,
    required this.author,
    required this.authorRole,
    this.imageUrl,
    required this.categoryIcon,
    required this.themeColor,
    required this.sections,
    this.isPublished = true,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as String? ?? 'Mental Awareness';
    final hexColor = json['theme_color_hex'] as String? ?? '#0284C7';
    Color color;
    try {
      final clean = hexColor.replaceAll('#', '');
      color = Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      color = const Color(0xFF0284C7);
    }

    List<ArticleSection> secList = [];
    if (json['content_json'] != null) {
      try {
        final parsed = jsonDecode(json['content_json'] as String);
        if (parsed is List) {
          secList = parsed.map((s) => ArticleSection.fromJson(s as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    } else if (json['sections'] != null && json['sections'] is List) {
      secList = (json['sections'] as List).map((s) => ArticleSection.fromJson(s as Map<String, dynamic>)).toList();
    }

    return ArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      subtitle: json['subtitle'] as String? ?? '',
      category: cat,
      readTime: json['read_time'] as String? ?? '4 min read',
      author: json['author'] as String? ?? 'CSU Guidance Center',
      authorRole: json['author_role'] as String? ?? 'Counselor',
      imageUrl: json['image_url'] as String?,
      categoryIcon: ArticlesData.iconForCategory(cat),
      themeColor: color,
      sections: secList,
      isPublished: json['is_published'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'read_time': readTime,
      'author': author,
      'author_role': authorRole,
      'image_url': imageUrl,
      'theme_color_hex': '#${themeColor.toARGB32().toRadixString(16).substring(2)}',
      'content_json': jsonEncode(sections.map((s) => s.toJson()).toList()),
      'is_published': isPublished,
    };
  }
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

  factory ArticleSection.fromJson(Map<String, dynamic> json) {
    List<String>? points;
    if (json['key_points'] is List) {
      points = (json['key_points'] as List).map((e) => e.toString()).toList();
    } else if (json['keyPoints'] is List) {
      points = (json['keyPoints'] as List).map((e) => e.toString()).toList();
    }
    return ArticleSection(
      heading: json['heading'] as String? ?? '',
      content: json['content'] as String? ?? '',
      keyPoints: points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heading': heading,
      'content': content,
      if (keyPoints != null) 'key_points': keyPoints,
    };
  }
}

class ArticlesData {
  static const List<String> categories = [
    'All',
    'Mental Awareness',
    'Student Burnout',
    'Anxiety & Coping',
    'Family & Relations',
    'Crisis Prevention',
    'Campus Wellness',
  ];

  static IconData iconForCategory(String category) {
    switch (category) {
      case 'Student Burnout':
        return Icons.school_rounded;
      case 'Anxiety & Coping':
        return Icons.psychology_rounded;
      case 'Family & Relations':
        return Icons.people_alt_rounded;
      case 'Crisis Prevention':
        return Icons.health_and_safety_rounded;
      case 'Campus Wellness':
        return Icons.spa_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  static List<ArticleModel> mergeWithDefaults(List<ArticleModel> dynamicArticles) {
    final existingIds = dynamicArticles.map((a) => a.id).toSet();
    final combined = List<ArticleModel>.from(dynamicArticles);
    for (final d in all) {
      if (!existingIds.contains(d.id)) {
        combined.add(d);
      }
    }
    return combined;
  }

  static const List<ArticleModel> all = [
    ArticleModel(
      id: 'student-burnout-awareness',
      title: 'Overcoming Academic and Work Burnout',
      subtitle: 'Recognize the clinical signs of cognitive exhaustion and recover sustainably.',
      category: 'Student Burnout',
      readTime: '4 min read',
      author: 'Dr. Kim Vance',
      authorRole: 'Clinical Psychologist',
      categoryIcon: Icons.school_rounded,
      themeColor: Color(0xFF0284C7),
      sections: [
        ArticleSection(
          heading: 'What is Student Burnout?',
          content:
              'Academic burnout is a state of chronic physical, cognitive, and emotional exhaustion caused by prolonged study overload, perfectionism, and inadequate rest periods.',
        ),
        ArticleSection(
          heading: 'Core Warning Signs',
          content:
              'Watch for these four primary indicators before exhaustion turns into severe mental health crises:',
          keyPoints: [
            'Emotional Detachment: Feeling cynical or indifferent toward subjects you once enjoyed.',
            'Brain Fog: Inability to retain lecture material or focus for more than 5 minutes.',
            'Physical Manifestations: Chronic tension headaches, digestive issues, and disrupted sleep.',
            'Imposter Syndrome: Believing that you do not deserve your spot or accomplishments.',
          ],
        ),
        ArticleSection(
          heading: 'Evidence-Based Recovery Protocol',
          content:
              'Implement the "Rule of Thirds": Divide your daily waking hours into 1/3 Focused Study, 1/3 Restorative Rest/Socializing, and 1/3 Physical Health (sleep, nutrition, movement).',
        ),
      ],
    ),
    ArticleModel(
      id: 'cbt-cognitive-distortions',
      title: 'Untangling Cognitive Distortions in College Life',
      subtitle: 'Identify and reframe automatic negative thought traps that fuel daily anxiety.',
      category: 'Anxiety & Coping',
      readTime: '5 min read',
      author: 'Coach Jeon',
      authorRole: 'CBT Wellness Coach',
      categoryIcon: Icons.psychology_rounded,
      themeColor: Color(0xFF7C3AED),
      sections: [
        ArticleSection(
          heading: 'Understanding Thought Distortions',
          content:
              'Cognitive distortions are habitual, exaggerated ways of thinking that distort reality, convincing your brain of worst-case scenarios without factual evidence.',
        ),
        ArticleSection(
          heading: 'The 3 Most Common Student Traps',
          content:
              'Notice if you catch yourself falling into these common cognitive patterns:',
          keyPoints: [
            'Catastrophizing: "If I fail this midterm, my whole degree is ruined and I have no future."',
            'All-or-Nothing Thinking: "If I didn\'t get the highest grade, I am a total failure."',
            'Mind Reading: "The professor looked at me weirdly; they definitely think I am dumb."',
          ],
        ),
        ArticleSection(
          heading: 'The CBT "Triple-Column" Technique',
          content:
              'Whenever a distressing thought surfaces: 1) Write down the automatic thought, 2) Identify the distortion label, and 3) Write a rational, balanced alternative based on objective reality.',
        ),
      ],
    ),
    ArticleModel(
      id: 'filipino-family-boundaries',
      title: 'Setting Healthy Boundaries in Filipino Families',
      subtitle: 'How to communicate personal limits with empathy, pakikiramay, and mutual respect.',
      category: 'Family & Relations',
      readTime: '4 min read',
      author: 'Dr. Min Santos',
      authorRole: 'Family & Youth Counselor',
      categoryIcon: Icons.diversity_3_rounded,
      themeColor: Color(0xFF059669),
      sections: [
        ArticleSection(
          heading: 'The Cultural Context of Boundaries',
          content:
              'In collectivistic Filipino culture, family closeness (*bayanihan* and *utang na loob*) is a profound strength. However, without clear personal boundaries, expectations can lead to emotional enmeshment and suppressed resentment.',
        ),
        ArticleSection(
          heading: 'Respectful Communication Framework',
          content:
              'You can honor your family while maintaining your mental sanity by applying the "Affirm + State Limit + Reassure" formula:',
          keyPoints: [
            'Affirm: "Ma/Pa, I love and appreciate how much you care about my grades."',
            'State Limit: "Right now, I need 2 hours of quiet time without interruptions to finish my project."',
            'Reassure: "I will join everyone for dinner right at 7:00 PM and catch up then."',
          ],
        ),
        ArticleSection(
          heading: 'Remember: Boundaries Are Not Disrespect',
          content:
              'Healthy boundaries do not divide families; they preserve relationships by preventing burnout and passive-aggressive conflict.',
        ),
      ],
    ),
    ArticleModel(
      id: 'crisis-prevention-awareness',
      title: 'Crisis & Suicide Awareness: How to Help a Friend',
      subtitle: 'Recognizing silent cries for help and connecting peers to Philippine 24/7 hotlines.',
      category: 'Crisis Prevention',
      readTime: '3 min read',
      author: 'Kausap Clinical Team',
      authorRole: 'Crisis Intervention Specialists',
      categoryIcon: Icons.emergency_rounded,
      themeColor: Color(0xFFDC2626),
      sections: [
        ArticleSection(
          heading: 'Why Awareness Saves Lives',
          content:
              'Most individuals experiencing acute mental distress or suicidal thoughts do not want to end their lives; they want to end an unbearable pain that feels inescapable.',
        ),
        ArticleSection(
          heading: 'Warning Signs to Notice',
          content:
              'Reach out with immediate compassion if a friend or classmate shows these signs:',
          keyPoints: [
            'Verbal Cues: Saying things like "I wish I could go to sleep and never wake up" or "You\'d be better off without me."',
            'Giving Away Possessions: Distributing valued books, accounts, or personal items.',
            'Sudden Withdrawal: Disappearing from group chats and social gatherings completely.',
            'Drastic Mood Shift: A sudden, unexpected calmness after a deep depression (often a signal of a decided plan).',
          ],
        ),
        ArticleSection(
          heading: 'Immediate 24/7 Support Resources in the Philippines',
          content:
              'Never hesitate to call or share these free confidential resources:\n• NCMH Crisis Helpline: 1553 (Toll-free 24/7) or 0917-899-8727\n• Hopeline Philippines: (02) 8804-4673 / 0917-558-4673\n• In Touch Community: 0917-800-1123\n• National Emergency Services: 911',
        ),
      ],
    ),
    ArticleModel(
      id: 'circadian-health-sleep-hygiene',
      title: 'Sleep Hygiene & Circadian Health for Students',
      subtitle: 'The physiological foundations of deep restorative REM sleep for memory and mood.',
      category: 'Mental Awareness',
      readTime: '4 min read',
      author: 'Dr. Min Santos',
      authorRole: 'Sleep Specialist',
      categoryIcon: Icons.bedtime_rounded,
      themeColor: Color(0xFF4F46E5),
      sections: [
        ArticleSection(
          heading: 'Sleep and Memory Consolidation',
          content:
              'During Slow-Wave and REM sleep stages, the brain\'s glymphatic system clears metabolic toxins, while the hippocampus transfers facts learned during study sessions into permanent long-term memory.',
        ),
        ArticleSection(
          heading: 'Actionable Night Pacing Habits',
          content:
              'Adopt these four proven habits to dramatically improve sleep quality:',
          keyPoints: [
            'Morning Sunlight: View 10-15 minutes of natural sunlight within an hour of waking to set your circadian timer.',
            'Digital Wind-Down: Stop looking at high-energy blue screens 45 minutes before sleep.',
            'Consistent Wake Time: Wake up at the same time every morning (even on weekends) to anchor your biological clock.',
            'Bedroom Association: Use your bed exclusively for sleeping, never for working on laptops or doing homework.',
          ],
        ),
      ],
    ),
  ];
}
