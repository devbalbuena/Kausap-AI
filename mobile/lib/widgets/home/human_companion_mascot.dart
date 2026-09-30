import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

/// Supported mood states for the Kausap Companion Mascot.
enum CompanionMood {
  rough(
    keyName: 'rough',
    level: 1,
    label: 'Rough',
    statusText: 'Here with gentle comfort',
    primaryColor: Color(0xFF818CF8), // Soft caring periwinkle
    secondaryColor: Color(0xFFA5B4FC),
    accentIcon: Icons.favorite_rounded,
    badgeEmoji: '🌸',
  ),
  low(
    keyName: 'low',
    level: 2,
    label: 'Low',
    statusText: 'Holding space for you',
    primaryColor: Color(0xFF38BDF8), // Calming sky blue
    secondaryColor: Color(0xFF7DD3FC),
    accentIcon: Icons.spa_rounded,
    badgeEmoji: '🌿',
  ),
  okay(
    keyName: 'okay',
    level: 3,
    label: 'Okay',
    statusText: 'Balanced & steady',
    primaryColor: Color(0xFF0D9488), // Signature Kausap teal
    secondaryColor: Color(0xFF2DD4BF),
    accentIcon: Icons.eco_rounded,
    badgeEmoji: '🌱',
  ),
  good(
    keyName: 'good',
    level: 4,
    label: 'Good',
    statusText: 'Radiant & energized',
    primaryColor: Color(0xFF10B981), // Warm emerald
    secondaryColor: Color(0xFF34D399),
    accentIcon: Icons.wb_sunny_rounded,
    badgeEmoji: '☀️',
  ),
  great(
    keyName: 'great',
    level: 5,
    label: 'Great',
    statusText: 'Bright & thriving',
    primaryColor: Color(0xFF059669), // Vibrant joyful emerald
    secondaryColor: Color(0xFF6EE7B7),
    accentIcon: Icons.auto_awesome_rounded,
    badgeEmoji: '✨',
  );

  final String keyName;
  final int level;
  final String label;
  final String statusText;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData accentIcon;
  final String badgeEmoji;

  const CompanionMood({
    required this.keyName,
    required this.level,
    required this.label,
    required this.statusText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentIcon,
    required this.badgeEmoji,
  });

  /// Parse mood from either an integer (1–5) or string name ('rough', 'low', 'okay', 'good', 'great').
  static CompanionMood from(dynamic value) {
    if (value == null) return CompanionMood.okay;

    if (value is int) {
      for (final m in CompanionMood.values) {
        if (m.level == value) return m;
      }
      if (value <= 1) return CompanionMood.rough;
      if (value >= 5) return CompanionMood.great;
      return CompanionMood.okay;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      for (final m in CompanionMood.values) {
        if (m.keyName == normalized || m.label.toLowerCase() == normalized) {
          return m;
        }
      }
      final parsedInt = int.tryParse(normalized);
      if (parsedInt != null) return CompanionMood.from(parsedInt);
    }

    return CompanionMood.okay;
  }
}

/// Available official Kausap companions.
enum KausapCompanionType {
  brainBuddy(
    name: 'Brain Buddy',
    assetPath: 'assets/images/kausap/human_companion/brain_buddy.png',
    description: 'Waves hello and cheers you on',
    fit: BoxFit.contain,
    padding: 4.0,
  ),
  heartBuddy(
    name: 'Heart Buddy',
    assetPath: 'assets/images/kausap/human_companion/heart_buddy.png',
    description: 'Gives the warmest hugs',
    fit: BoxFit.contain,
    padding: 4.0,
  ),
  calmHuman(
    name: 'Calm Human',
    assetPath: 'assets/images/kausap/human_companion/calm_human.png',
    description: 'Takes a peaceful breath with you',
    fit: BoxFit.contain,
    padding: 2.0,
  ),
  kiko(
    name: 'Kiko',
    assetPath: 'assets/images/kausap/human_companion/kiko.png',
    description: 'Cheers you on with a thumbs up',
    fit: BoxFit.cover,
    padding: 0.0,
  ),
  ateMira(
    name: 'Ate Mira',
    assetPath: 'assets/images/kausap/human_companion/ate_mira.png',
    description: 'Waves hello and checks in on you',
    fit: BoxFit.cover,
    padding: 0.0,
  );

  final String name;
  final String assetPath;
  final String description;
  final BoxFit fit;
  final double padding;

  const KausapCompanionType({
    required this.name,
    required this.assetPath,
    required this.description,
    required this.fit,
    required this.padding,
  });
}

/// The official Kausap Companion Mascot widget.
///
/// Features smooth idle breathing, floating, glowing aura,
/// interactive tap bounce with mindful affirmations and haptic feedback.
class HumanCompanionMascot extends StatefulWidget {
  final dynamic mood;
  final double size;
  final String? assetPath;
  final String? firstName;
  final ValueChanged<String>? onAffirmation;
  final bool enableAnimation;
  final bool showMoodBadge;
  final KausapCompanionType? companionType;

  const HumanCompanionMascot({
    super.key,
    this.mood,
    this.size = 76.0,
    this.assetPath,
    this.firstName,
    this.onAffirmation,
    this.enableAnimation = true,
    this.showMoodBadge = true,
    this.companionType,
  });

  @override
  State<HumanCompanionMascot> createState() => _HumanCompanionMascotState();
}

class _HumanCompanionMascotState extends State<HumanCompanionMascot>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _floatAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _glowAnim;

  late AnimationController _tapController;
  late Animation<double> _tapScaleXAnim;
  late Animation<double> _tapScaleYAnim;

  final List<String> _mindfulAffirmations = [
    "Take a gentle, deep breath right now 🌿",
    "You're doing great, one step at a time! ✨",
    "I'm always here to listen and cheer you on 💙",
    "Be kind and patient with yourself today 🌱",
    "You are capable of amazing growth 🌟",
    "Small steps every day bring peace of mind 🌸",
  ];
  int _affirmationIdx = 0;

  static const String _defaultAssetPath =
      'assets/images/kausap/human_companion/kiko.png';

  @override
  void initState() {
    super.initState();

    // ── Idle breathing & floating controller (3.0s) ─────────────────────────
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _floatAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    _breatheAnim = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    _glowAnim = Tween<double>(begin: 0.35, end: 0.70).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    if (widget.enableAnimation) {
      _idleController.repeat(reverse: true);
    }

    // ── Interactive tap feedback controller (squash & stretch) ─────────────
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tapScaleXAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
    ]).animate(_tapController);

    _tapScaleYAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
    ]).animate(_tapController);
  }

  @override
  void didUpdateWidget(covariant HumanCompanionMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation != oldWidget.enableAnimation) {
      if (widget.enableAnimation) {
        if (!_idleController.isAnimating) _idleController.repeat(reverse: true);
      } else {
        _idleController.stop();
        _idleController.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTapCompanion() {
    HapticService.lightTap();
    _tapController.forward(from: 0.0);

    setState(() {
      _affirmationIdx = (_affirmationIdx + 1) % _mindfulAffirmations.length;
    });

    final name = (widget.firstName != null && widget.firstName!.trim().isNotEmpty)
        ? '${widget.firstName!.trim()}, '
        : '';
    final rawAffirmation = _mindfulAffirmations[_affirmationIdx];
    final affirmation = '$name$rawAffirmation';

    widget.onAffirmation?.call(affirmation);
  }

  @override
  Widget build(BuildContext context) {
    final companionMood = CompanionMood.from(widget.mood);
    final effectiveSize = widget.size.clamp(48.0, 160.0);
    final badgeSize = (effectiveSize * 0.32).clamp(18.0, 32.0);

    final String resolvedAsset = widget.companionType?.assetPath ??
        widget.assetPath ??
        _defaultAssetPath;

    final BoxFit resolvedFit = widget.companionType?.fit ??
        (resolvedAsset.contains('kiko') || resolvedAsset.contains('ate_mira')
            ? BoxFit.cover
            : BoxFit.contain);

    final double resolvedPadding = widget.companionType?.padding ??
        (resolvedFit == BoxFit.contain ? 4.0 : 0.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Kausap Companion • Tap for gentle affirmation 🌱',
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: _onTapCompanion,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _idleController,
              _tapController,
            ]),
            builder: (context, child) {
              final floatOffset =
                  widget.enableAnimation ? _floatAnim.value : 0.0;
              final breatheScale =
                  widget.enableAnimation ? _breatheAnim.value : 1.0;
              final tapScaleX = _tapScaleXAnim.value;
              final tapScaleY = _tapScaleYAnim.value;
              final glowAlpha =
                  (_glowAnim.value * 255).round().clamp(0, 255);

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.scale(
                  scaleX: breatheScale * tapScaleX,
                  scaleY: breatheScale * tapScaleY,
                  child: SizedBox(
                    width: effectiveSize,
                    height: effectiveSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // ── Soft ambient glow aura ───────────────────────────
                        Container(
                          width: effectiveSize * 0.95,
                          height: effectiveSize * 0.95,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: companionMood.primaryColor
                                    .withAlpha(glowAlpha ~/ 2.8),
                                blurRadius: 20,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: companionMood.secondaryColor
                                    .withAlpha(glowAlpha ~/ 4.5),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),

                        // ── Outer decorative gradient ring & avatar ──────────
                        Container(
                          width: effectiveSize,
                          height: effectiveSize,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                companionMood.secondaryColor.withAlpha(230),
                                companionMood.primaryColor,
                                KausapColors.accent(context).withAlpha(190),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(resolvedPadding),
                              child: Image.asset(
                                resolvedAsset,
                                fit: resolvedFit,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: companionMood.primaryColor.withAlpha(40),
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      size: effectiveSize * 0.5,
                                      color: companionMood.primaryColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // ── Mood badge (corner micro-pill) ───────────────────
                        if (widget.showMoodBadge)
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              width: badgeSize,
                              height: badgeSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: KausapColors.cardBg(context),
                                border: Border.all(
                                  color: Colors.white.withAlpha(240),
                                  width: 1.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: companionMood.primaryColor
                                        .withAlpha(130),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    companionMood.primaryColor,
                                    companionMood.secondaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  companionMood.badgeEmoji,
                                  style: TextStyle(
                                    fontSize:
                                        (badgeSize * 0.52).clamp(9.0, 15.0),
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
