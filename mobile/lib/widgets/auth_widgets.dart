import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

/// Interactive Animated Kausap AI Companion Mascot ("Kausap Buddy")
/// Gently floats, breathes calmly in a soothing rhythm, blinks,
/// and responds to user taps AND typing in email/password with joyful wiggles, sparkles, and uplifting affirmations!
class KausapBuddyMascot extends StatefulWidget {
  const KausapBuddyMascot({super.key});

  @override
  State<KausapBuddyMascot> createState() => KausapBuddyMascotState();
}

class KausapBuddyMascotState extends State<KausapBuddyMascot> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounceController;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _wiggleAnim;

  int _affirmationIndex = 0;
  bool _showAffirmation = false;
  String _currentAffirmation = "You've got this! ✨";
  Timer? _dismissTimer;
  DateTime _lastTypingTrigger = DateTime.now().subtract(const Duration(seconds: 10));

  final List<String> _affirmations = [
    "You've got this! ✨",
    "Take a gentle, deep breath 🌿",
    "I'm so glad you're here! 💙",
    "One step at a time 🌱",
    "You are worthy and loved 💖",
    "Welcome back, friend! 🌟",
    "Peace begins with a smile 🌸",
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 0.94).chain(CurveTween(curve: Curves.easeInQuad)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
    ]).animate(_bounceController);

    _wiggleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _floatController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  /// Trigger mood boost from mascot tap or email/password input activity
  void triggerMoodBoost({String? customMessage, bool isTyping = false}) {
    // If triggered by typing, throttle so it triggers smoothly without overwhelming
    if (isTyping) {
      final now = DateTime.now();
      if (now.difference(_lastTypingTrigger).inMilliseconds < 1800) {
        return;
      }
      _lastTypingTrigger = now;
    }

    HapticService.lightTap();
    if (!_bounceController.isAnimating) {
      _bounceController.forward(from: 0.0);
    }

    setState(() {
      if (customMessage != null && customMessage.isNotEmpty) {
        _currentAffirmation = customMessage;
      } else {
        _affirmationIndex = (_affirmationIndex + 1) % _affirmations.length;
        _currentAffirmation = _affirmations[_affirmationIndex];
      }
      _showAffirmation = true;
    });

    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showAffirmation = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Floating Speech Bubble for Affirmations
        AnimatedOpacity(
          opacity: _showAffirmation ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedScale(
            scale: _showAffirmation ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0C0077B6), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Text(
                _currentAffirmation,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ),
        ),

        // Interactive Mascot
        GestureDetector(
          onTap: () => triggerMoodBoost(),
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([_floatController, _bounceController]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Transform.rotate(
                  angle: _wiggleAnim.value,
                  child: Transform.scale(
                    scale: _pulseAnim.value * _bounceAnim.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B4D8).withAlpha(80),
                            blurRadius: 20,
                            spreadRadius: 3,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Small sprout leaf / star at the top
                          Positioned(
                            top: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFBEE3F8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Expressive mascot face
                          CustomPaint(
                            size: const Size(40, 40),
                            painter: _MascotFacePainter(progress: _floatController.value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Brand Name & Subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Kausap AI', style: AppTextStyles.brandName),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text(
                'v2.1',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Your Mental Wellness Companion.',
          style: AppTextStyles.subheading.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

/// Custom painter for the expressive friendly mascot face
class _MascotFacePainter extends CustomPainter {
  final double progress;
  _MascotFacePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final blushPaint = Paint()
      ..color = const Color(0xFFFFB4A2).withAlpha(140)
      ..style = PaintingStyle.fill;

    final isBlinking = progress > 0.47 && progress < 0.53;

    if (isBlinking) {
      // Happy curved closed eye arcs when blinking
      final leftArc = Path()
        ..moveTo(size.width * 0.22, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.33, size.height * 0.36, size.width * 0.44, size.height * 0.44);
      final rightArc = Path()
        ..moveTo(size.width * 0.56, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.67, size.height * 0.36, size.width * 0.78, size.height * 0.44);
      canvas.drawPath(leftArc, mouthPaint);
      canvas.drawPath(rightArc, mouthPaint);
    } else {
      // Big sparkling anime-style expressive round eyes
      canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.42), 3.6, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.67, size.height * 0.42), 3.6, eyePaint);

      // Star sparkle catchlights inside eyes
      final shinePaint = Paint()..color = const Color(0xFF0077B6);
      canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.43), 1.6, shinePaint);
      canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.43), 1.6, shinePaint);

      final glintPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.40), 1.2, glintPaint);
      canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.40), 1.2, glintPaint);
    }

    // Soft rosy glowing blush cheeks
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.54), 3.2, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.54), 3.2, blushPaint);

    // Warm smiling mouth arc
    final mouthPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.72, size.width * 0.58, size.height * 0.58);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotFacePainter oldDelegate) => oldDelegate.progress != progress;
}

/// Official 4-Color Google Vector Logo Widget
class GoogleBrandLogo extends StatelessWidget {
  final double size;
  const GoogleBrandLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeW = w * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    // Blue segment
    canvas.drawArc(rect, -math.pi / 4, math.pi / 2, false, paintBlue);

    // Green segment
    canvas.drawArc(rect, math.pi / 4, math.pi / 2, false, paintGreen);

    // Yellow segment
    canvas.drawArc(rect, 3 * math.pi / 4, math.pi / 2, false, paintYellow);

    // Red segment
    canvas.drawArc(rect, 5 * math.pi / 4, math.pi / 2, false, paintRed);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy - strokeW / 2, radius, strokeW),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Facebook Vector Logo Badge
class FacebookBrandLogo extends StatelessWidget {
  final double size;
  const FacebookBrandLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: size * 0.72,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

/// Shared Kausap AI logo + tagline header (fallback / static)
class KausapHeader extends StatelessWidget {
  const KausapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const KausapBuddyMascot();
  }
}

/// White card container used on auth screens.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Footer branding used at the bottom of auth screens.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Kausap AI © 2026 • Campus Mental Health Shield',
          style: AppTextStyles.caption.copyWith(fontSize: 10.5, color: const Color(0xFF94A3B8)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('PRIVACY POLICY', style: AppTextStyles.caption.copyWith(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(width: 14),
            Text('TERMS OF SERVICE', style: AppTextStyles.caption.copyWith(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(width: 14),
            Text('SUPPORT', style: AppTextStyles.caption.copyWith(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
