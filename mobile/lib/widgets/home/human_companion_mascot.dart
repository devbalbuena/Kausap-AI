import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

/// Supported mood states for the Human Companion Mascot.
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

/// A human, emotionally approachable wellness companion mascot widget for Kausap AI.
///
/// Designed to replace robotic avatars with a warm, college-age student companion
/// in modern 3D illustrated style, representing a supportive digital wellness peer
/// rather than a therapist or machine.
class HumanCompanionMascot extends StatefulWidget {
  /// The current student mood state (accepts int 1..5, String 'rough'..'great', or CompanionMood).
  final dynamic mood;

  /// Diameter of the mascot avatar widget.
  /// Defaults to 76.0 for clean visual hierarchy in the Home greeting card.
  final double size;

  /// Custom image asset path.
  /// Defaults to 'assets/images/kausap/human_companion/kausap_human_companion.png'.
  final String? assetPath;

  /// First name of the student for personalized affirmations.
  final String? firstName;

  /// Callback when companion is tapped, providing a calming affirmation.
  final ValueChanged<String>? onAffirmation;

  /// Whether to enable subtle idle breathing/floating animation.
  final bool enableAnimation;

  /// Whether to show the subtle mood badge in the corner.
  final bool showMoodBadge;

  const HumanCompanionMascot({
    super.key,
    this.mood,
    this.size = 76.0,
    this.assetPath,
    this.firstName,
    this.onAffirmation,
    this.enableAnimation = true,
    this.showMoodBadge = true,
  });

  @override
  State<HumanCompanionMascot> createState() => _HumanCompanionMascotState();
}

class _HumanCompanionMascotState extends State<HumanCompanionMascot>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _tapController;

  late Animation<double> _floatAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _tapAnim;

  final List<String> _mindfulAffirmations = [
    "Take a gentle, deep breath right now 🌿",
    "You're doing great, one step at a time! ✨",
    "I'm always here to listen and support you 💙",
    "Be kind and patient with your mind today 🌱",
    "You are capable of amazing growth 🌟",
    "Small steps every day bring peace of mind 🌸",
  ];

  int _affirmationIdx = 0;

  static const String _defaultAssetPath =
      'assets/images/kausap/human_companion/kausap_human_companion.png';
  static const String _fallbackAssetPath =
      'assets/avatars/avatar_basic_kim.png';

  @override
  void initState() {
    super.initState();

    // ── Slow, calming idle breathing / floating controller (2.8s) ──────────
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    if (widget.enableAnimation) {
      _idleController.repeat(reverse: true);
    }

    // 2-3px subtle smooth floating (no bouncing)
    _floatAnim = Tween<double>(begin: -2.2, end: 2.2).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Micro breathing scale (0.99 to 1.01)
    _breatheAnim = Tween<double>(begin: 0.99, end: 1.01).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Subtle breathing aura glow opacity
    _glowAnim = Tween<double>(begin: 0.45, end: 0.75).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // ── Interactive tap feedback controller ────────────────────────────────
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _tapAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.98).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 25,
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

    final affirmation = _mindfulAffirmations[_affirmationIdx];
    widget.onAffirmation?.call(affirmation);
  }

  @override
  Widget build(BuildContext context) {
    final companionMood = CompanionMood.from(widget.mood);
    final effectiveSize = widget.size.clamp(48.0, 160.0);
    final badgeSize = (effectiveSize * 0.32).clamp(18.0, 32.0);
    final resolvedAsset = widget.assetPath ?? _defaultAssetPath;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Kausap Companion • Tap for a mindful moment 🌱',
        waitDuration: const Duration(milliseconds: 600),
        child: GestureDetector(
          onTap: _onTapCompanion,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idleController, _tapController]),
            builder: (context, child) {
              final floatOffset = widget.enableAnimation ? _floatAnim.value : 0.0;
              final breatheScale = widget.enableAnimation ? _breatheAnim.value : 1.0;
              final tapScale = _tapAnim.value;
              final glowAlpha = (_glowAnim.value * 255).round().clamp(0, 255);

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.scale(
                  scale: breatheScale * tapScale,
                  child: SizedBox(
                    width: effectiveSize,
                    height: effectiveSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // ── SOFT ORGANIC GLOW AURA ──────────────────────────
                        Container(
                          width: effectiveSize * 0.94,
                          height: effectiveSize * 0.94,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: companionMood.primaryColor.withAlpha(glowAlpha ~/ 2.5),
                                blurRadius: 18,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: companionMood.secondaryColor.withAlpha(glowAlpha ~/ 4),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),

                        // ── OUTER CIRCULAR GRADIENT BORDER ───────────────────
                        Container(
                          width: effectiveSize,
                          height: effectiveSize,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                companionMood.secondaryColor.withAlpha(220),
                                companionMood.primaryColor,
                                KausapColors.accent(context).withAlpha(180),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KausapColors.cardBg(context),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Base background fill while image loads
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          companionMood.primaryColor.withAlpha(35),
                                          companionMood.secondaryColor.withAlpha(20),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),

                                  // Human Companion Character Asset
                                  Image.asset(
                                    resolvedAsset,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Seamless fallback if asset directory is still bundling
                                      return Image.asset(
                                        _fallbackAssetPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error2, stackTrace2) {
                                          return Container(
                                            color: companionMood.primaryColor.withAlpha(40),
                                            child: Icon(
                                              Icons.face_retouching_natural_rounded,
                                              size: effectiveSize * 0.5,
                                              color: companionMood.primaryColor,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  // Subtle mood-toned lighting tint (gentle warmth/comfort)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          companionMood.primaryColor.withAlpha(
                                            companionMood == CompanionMood.rough ? 22 :
                                            companionMood == CompanionMood.great ? 20 : 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── SUBTLE MOOD BADGE (Corner micro-indicator) ───────
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
                                  color: Colors.white.withAlpha(230),
                                  width: 1.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: companionMood.primaryColor.withAlpha(120),
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
                                    fontSize: (badgeSize * 0.52).clamp(9.0, 15.0),
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
