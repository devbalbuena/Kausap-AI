import 'package:flutter/material.dart';
import '../../utils/haptic_service.dart';

class HomeCompanionAvatar extends StatefulWidget {
  final int? todayMood;
  final String firstName;

  const HomeCompanionAvatar({
    super.key,
    required this.todayMood,
    required this.firstName,
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
    "You're doing great, one step at a time! ✨",
    "Take a gentle, deep breath right now 🌿",
    "I'm so glad you're here today! 💙",
    "Be kind to your mind today 🌱",
    "You are capable of amazing growth 🌟",
    "Peace begins with a gentle smile 🌸",
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
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack));

    _wiggleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 25),
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kausap Buddy: "$affirmation"',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
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
        return const [Color(0xFF7C3AED), Color(0xFF38BDF8)]; // Default (Purple-Cyan)
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
                        // Expressive Mood Face
                        CustomPaint(
                          size: const Size(40, 40),
                          painter: HomeMascotFacePainter(
                            mood: widget.todayMood,
                            progress: _floatController.value,
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

  HomeMascotFacePainter({
    required this.mood,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()..color = const Color(0xFFFFB4A2).withAlpha(160);

    final isBlinking = progress > 0.48 && progress < 0.52;

    if (mood == 3 || isBlinking) {
      // Peaceful closed smiling eyes ( ˘ ᵕ ˘ )
      final leftArc = Path()
        ..moveTo(size.width * 0.24, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.36, size.width * 0.46, size.height * 0.44);
      final rightArc = Path()
        ..moveTo(size.width * 0.54, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.65, size.height * 0.36, size.width * 0.76, size.height * 0.44);
      canvas.drawPath(leftArc, strokePaint);
      canvas.drawPath(rightArc, strokePaint);
    } else {
      // Round sparkling eyes
      canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.42), 3.2, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.42), 3.2, eyePaint);

      final glintPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.39), 1.2, glintPaint);
      canvas.drawCircle(Offset(size.width * 0.63, size.height * 0.39), 1.2, glintPaint);
    }

    // Cheeks
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.54), 2.8, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.54), 2.8, blushPaint);

    // Dynamic Smile
    if (mood == 1) {
      // Comforting gentle smile
      final mouth = Path()
        ..moveTo(size.width * 0.42, size.height * 0.62)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.68, size.width * 0.58, size.height * 0.62);
      canvas.drawPath(mouth, strokePaint);
    } else {
      // Upbeat open smile
      final mouth = Path()
        ..moveTo(size.width * 0.38, size.height * 0.58)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.72, size.width * 0.62, size.height * 0.58);
      canvas.drawPath(mouth, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HomeMascotFacePainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.progress != progress;
}
