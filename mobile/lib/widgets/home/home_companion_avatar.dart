import 'package:flutter/material.dart';
import '../../utils/haptic_service.dart';

class HomeCompanionAvatar extends StatefulWidget {
  final int? todayMood;
  final String firstName;
  final ValueChanged<String>? onAffirmation;

  const HomeCompanionAvatar({
    super.key,
    required this.todayMood,
    required this.firstName,
    this.onAffirmation,
  });

  @override
  State<HomeCompanionAvatar> createState() => _HomeCompanionAvatarState();
}

class _HomeCompanionAvatarState extends State<HomeCompanionAvatar> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounceController;

  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _wiggleAnim;

  final List<String> _mindfulAffirmations = [
    "Take a gentle, deep breath right now 🌿",
    "You're doing great, one step at a time! ✨",
    "I'm always here to listen and support you 💙",
    "Be kind and patient with your mind today 🌱",
    "You are capable of amazing growth 🌟",
    "Small steps every day bring peace of mind 🌸",
  ];

  int _affirmationIdx = 0;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.22).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 0.94).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    _wiggleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.16).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.16, end: 0.16).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.16, end: 0.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 25,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _tapCompanion() {
    HapticService.lightTap();
    _bounceController.forward(from: 0.0);

    setState(() {
      _affirmationIdx = (_affirmationIdx + 1) % _mindfulAffirmations.length;
    });

    final affirmation = _mindfulAffirmations[_affirmationIdx];
    widget.onAffirmation?.call(affirmation);
  }

  List<Color> _getAuraGradient() {
    switch (widget.todayMood) {
      case 5:
        return const [Color(0xFF06B6D4), Color(0xFF38BDF8)]; // Great (Cyan)
      case 4:
        return const [Color(0xFF0284C7), Color(0xFF60A5FA)]; // Good (Sky)
      case 3:
        return const [Color(0xFF10B981), Color(0xFF34D399)]; // Okay (Mint)
      case 2:
        return const [Color(0xFFF59E0B), Color(0xFFFBBF24)]; // Low (Amber)
      case 1:
        return const [Color(0xFFF43F5E), Color(0xFFFB7185)]; // Rough (Rose)
      default:
        return const [Color(0xFF0284C7), Color(0xFF38BDF8)]; // Default (Ocean Sky)
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getAuraGradient();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _tapCompanion,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _bounceController]),
          builder: (context, child) {
            final bounceProgress = _bounceController.value;
            return Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: Transform.rotate(
                angle: _wiggleAnim.value,
                child: Transform.scale(
                  scale: _pulseAnim.value * _bounceAnim.value,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withAlpha(90),
                          blurRadius: 14,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Headset Band
                        Positioned(
                          top: 6,
                          child: Container(
                            width: 42,
                            height: 18,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withAlpha(220), width: 2.2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        // Headset Ear Cushions
                        const Positioned(
                          left: 7,
                          top: 20,
                          child: CircleAvatar(radius: 4.5, backgroundColor: Colors.white),
                        ),
                        const Positioned(
                          right: 7,
                          top: 20,
                          child: CircleAvatar(radius: 4.5, backgroundColor: Colors.white),
                        ),
                        // Expressive Mood Face with Wink on Tap
                        CustomPaint(
                          size: const Size(40, 40),
                          painter: HomeMascotFacePainter(
                            mood: widget.todayMood,
                            progress: _floatController.value,
                            bounceProgress: bounceProgress,
                          ),
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
    );
  }
}

class HomeMascotFacePainter extends CustomPainter {
  final int? mood;
  final double progress;
  final double bounceProgress;

  HomeMascotFacePainter({
    required this.mood,
    required this.progress,
    this.bounceProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()..color = const Color(0xFFFFB4A2).withAlpha(170);

    final isBlinking = progress > 0.48 && progress < 0.52;
    final isWinking = bounceProgress > 0.05 && bounceProgress < 0.65;

    // ── EYES RENDERING (Adaptive by mood + wink + blink) ────────────────────
    if (isWinking) {
      // Playful Wink on Tap (Left eye closed happy arc, Right eye open sparkling)
      final leftWink = Path()
        ..moveTo(size.width * 0.24, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.36, size.width * 0.46, size.height * 0.44);
      canvas.drawPath(leftWink, strokePaint);

      // Right Eye Sparkling
      canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.42), 3.2, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.63, size.height * 0.39), 1.2, eyePaint);
    } else if (mood == 3 || isBlinking) {
      // Peaceful Zen Closed Smiling Eyes ( ˘ ᵕ ˘ )
      final leftArc = Path()
        ..moveTo(size.width * 0.24, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.36, size.width * 0.46, size.height * 0.44);
      final rightArc = Path()
        ..moveTo(size.width * 0.54, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.65, size.height * 0.36, size.width * 0.76, size.height * 0.44);
      canvas.drawPath(leftArc, strokePaint);
      canvas.drawPath(rightArc, strokePaint);
    } else if (mood == 2 || mood == 1) {
      // Empathetic Reassuring Eyes for Low / Rough Mood ( ◜‿◝ )
      final leftArc = Path()
        ..moveTo(size.width * 0.25, size.height * 0.45)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.38, size.width * 0.45, size.height * 0.45);
      final rightArc = Path()
        ..moveTo(size.width * 0.55, size.height * 0.45)
        ..quadraticBezierTo(size.width * 0.65, size.height * 0.38, size.width * 0.75, size.height * 0.45);
      canvas.drawPath(leftArc, strokePaint);
      canvas.drawPath(rightArc, strokePaint);
    } else {
      // Great (5) & Good (4) - Round Sparkling Twinkling Eyes
      canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.42), 3.2, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.42), 3.2, eyePaint);

      final glintPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.39), 1.2, glintPaint);
      canvas.drawCircle(Offset(size.width * 0.63, size.height * 0.39), 1.2, glintPaint);

      if (mood == 5) {
        // Extra star shine glint for Great mood
        canvas.drawCircle(Offset(size.width * 0.37, size.height * 0.44), 0.7, glintPaint);
        canvas.drawCircle(Offset(size.width * 0.67, size.height * 0.44), 0.7, glintPaint);
      }
    }

    // ── BLUSH CHEEKS ────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.54), 2.8, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.54), 2.8, blushPaint);

    // ── ADAPTIVE SMILE ──────────────────────────────────────────────────────
    if (mood == 1 || mood == 2) {
      // Gentle, caring reassuring smile
      final mouth = Path()
        ..moveTo(size.width * 0.40, size.height * 0.61)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.67, size.width * 0.60, size.height * 0.61);
      canvas.drawPath(mouth, strokePaint);
    } else if (mood == 5) {
      // Broad cheerful joyful smile
      final mouth = Path()
        ..moveTo(size.width * 0.36, size.height * 0.57)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.74, size.width * 0.64, size.height * 0.57);
      canvas.drawPath(mouth, strokePaint);
    } else {
      // Upbeat friendly smile
      final mouth = Path()
        ..moveTo(size.width * 0.38, size.height * 0.58)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.71, size.width * 0.62, size.height * 0.58);
      canvas.drawPath(mouth, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HomeMascotFacePainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.progress != progress ||
      oldDelegate.bounceProgress != bounceProgress;
}
