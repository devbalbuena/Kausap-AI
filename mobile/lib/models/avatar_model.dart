/// Avatar model — represents a selectable AI persona.
class AvatarModel {
  final String id;
  final String name;
  final String tier; // 'basic' or 'premium'
  final String imagePath; // asset path
  final String systemPrompt;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.tier,
    required this.imagePath,
    required this.systemPrompt,
  });

  bool get isPremium => tier == 'premium';
}

/// All available avatars in the app.
class AvatarData {
  static const List<AvatarModel> all = [
    // ── Basic (Free) ───────────────────────────────────────────────────
    AvatarModel(
      id: 'basic_kim',
      name: 'Dr. Kim',
      tier: 'basic',
      imagePath: 'assets/avatars/avatar_basic_kim.png',
      systemPrompt: 'You are Dr. Kim, a warm and empathetic mental health AI companion. Speak in a calm, professional and nurturing tone.',
    ),
    AvatarModel(
      id: 'basic_park',
      name: 'Park',
      tier: 'basic',
      imagePath: 'assets/avatars/avatar_basic_park.png',
      systemPrompt: 'You are Park, a friendly and casual mental health AI companion. Speak in a relatable, easy-going but supportive tone.',
    ),
    // ── Premium ────────────────────────────────────────────────────────
    AvatarModel(
      id: 'premium_jeon',
      name: 'Jeon',
      tier: 'premium',
      imagePath: 'assets/avatars/avatar_premium_jeon.png',
      systemPrompt: 'You are Jeon, a sophisticated and insightful mental health AI companion. Speak with depth, confidence, and wisdom.',
    ),
    AvatarModel(
      id: 'premium_kim',
      name: 'Dr. Kim',
      tier: 'premium',
      imagePath: 'assets/avatars/avatar_premium_kim.png',
      systemPrompt: 'You are Dr. Kim (Premium), an elite mental health AI. Provide expert-level guidance with exceptional empathy and clarity.',
    ),
    AvatarModel(
      id: 'premium_min',
      name: 'Dr. Min',
      tier: 'premium',
      imagePath: 'assets/avatars/avatar_premium_min.png',
      systemPrompt: 'You are Dr. Min, a bold and innovative mental health AI companion. Speak with energy, creativity, and inspiration.',
    ),
  ];

  static AvatarModel get defaultAvatar => all.first;

  static AvatarModel? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
