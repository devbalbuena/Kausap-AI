import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      title: 'Your AI Companion',
      subtitle: 'Talk freely with Kausap AI anytime. Our AI listens with empathy, understands your emotions, and guides you through every mood.',
      bgGradient: [Color(0xFFF5F3FF), Color(0xFFE0F2FE)],
      badgeColor: Color(0xFF7C3AED),
    ),
    _OnboardingSlideData(
      title: 'Mindfulness & Zen',
      subtitle: 'Practice guided breathing, soothing reflections, and daily wellness rituals tailored to calm student stress and anxiety.',
      bgGradient: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
      badgeColor: Color(0xFF059669),
    ),
    _OnboardingSlideData(
      title: 'Track Your Wellness',
      subtitle: 'Log your emotional journey, discover personalized wellness insights, and celebrate every milestone in your mental growth.',
      bgGradient: [Color(0xFFFFF1F2), Color(0xFFFFF7ED)],
      badgeColor: Color(0xFFE11D48),
    ),
  ];

  void _onPageChanged(int index) {
    HapticService.lightTap();
    setState(() => _currentPage = index);
  }

  void _goToNext() {
    HapticService.mediumTap();
    if (_currentPage < _slides.length - 1) {
      final nextIndex = _currentPage + 1;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    HapticService.heavyTap();
    const storage = FlutterSecureStorage();
    await storage.write(key: 'seen_onboarding', value: 'true');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: currentSlide.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Brand + Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.spa_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 5),
                          Text(
                            'Kausap AI',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page View with Interactive Companions
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildSlidePage(0),
                      _buildSlidePage(1),
                      _buildSlidePage(2),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation & Progress Dots
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    // Animated Progress Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage ? AppColors.primary : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Next / Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1 ? 'Get Started 🚀' : 'Continue',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidePage(int index) {
    final slide = _slides[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCompanion(index),
          const SizedBox(height: 24),
          Text(
            slide.title,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            style: AppTextStyles.body.copyWith(
              fontSize: 13.5,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanion(int index) {
    switch (index) {
      case 0:
        return const _ChattyCompanionWidget();
      case 1:
        return const _ZenCompanionWidget();
      case 2:
        return const _StarCompanionWidget();
      default:
        return const SizedBox();
    }
  }
}

/// Slide 1 Companion: "Chatty Kausap" (AI Companion with Headset & Audio Wave Aura)
class _ChattyCompanionWidget extends StatefulWidget {
  const _ChattyCompanionWidget();

  @override
  State<_ChattyCompanionWidget> createState() => _ChattyCompanionWidgetState();
}

class _ChattyCompanionWidgetState extends State<_ChattyCompanionWidget> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounceController;
  late AnimationController _pulseRingController;
  late Animation<double> _floatAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _wiggleAnim;
  late Animation<double> _pulseRingAnim;

  Offset _gazeOffset = Offset.zero;
  bool _showQuote = false;
  int _quoteIdx = 0;
  final List<String> _quotes = [
    "I'm always here to listen! 💬 ✨",
    "Tell me anything on your mind 💙",
    "No judgement, just support 🌿",
    "How was your day today? 🌸",
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _pulseRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseRingAnim = Tween<double>(begin: 0.9, end: 1.35).animate(
      CurvedAnimation(parent: _pulseRingController, curve: Curves.easeOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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
    _pulseRingController.dispose();
    super.dispose();
  }

  void _tapMascot() {
    HapticService.lightTap();
    _bounceController.forward(from: 0.0);
    setState(() {
      _quoteIdx = (_quoteIdx + 1) % _quotes.length;
      _showQuote = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showQuote = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech Bubble & Tap Hint
        SizedBox(
          height: 38,
          child: Center(
            child: AnimatedOpacity(
              opacity: _showQuote ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0C7C3AED), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Text(
                  _quotes[_quoteIdx],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Interactive Mascot with Empathy Soundwave Aura & Eye Tracking
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (e) {
            final center = Offset(135 / 2, 135 / 2);
            final delta = (e.localPosition - center);
            setState(() {
              _gazeOffset = Offset(
                (delta.dx / 40).clamp(-2.0, 2.0),
                (delta.dy / 40).clamp(-2.0, 2.0),
              );
            });
          },
          child: GestureDetector(
            onTap: _tapMascot,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatController, _bounceController, _pulseRingController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Empathy Soundwave Rings
                      Transform.scale(
                        scale: _pulseRingAnim.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withAlpha(((1.0 - _pulseRingController.value) * 120).toInt()),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      // Floating Mascot Body
                      Transform.rotate(
                        angle: _wiggleAnim.value,
                        child: Transform.scale(
                          scale: _bounceAnim.value,
                          child: Container(
                            width: 135,
                            height: 135,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF38BDF8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withAlpha(80),
                                  blurRadius: 28,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Headset band
                                Positioned(
                                  top: 14,
                                  child: Container(
                                    width: 86,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white.withAlpha(220), width: 3.5),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(50),
                                        topRight: Radius.circular(50),
                                      ),
                                    ),
                                  ),
                                ),
                                // Headset ear cushions
                                const Positioned(
                                  left: 17,
                                  top: 44,
                                  child: CircleAvatar(radius: 7.5, backgroundColor: Colors.white),
                                ),
                                const Positioned(
                                  right: 17,
                                  top: 44,
                                  child: CircleAvatar(radius: 7.5, backgroundColor: Colors.white),
                                ),
                                // Expressive Face with Eye Gaze Tracking
                                CustomPaint(
                                  size: const Size(60, 60),
                                  painter: _ChattyFacePainter(
                                    progress: _floatController.value,
                                    gazeOffset: _gazeOffset,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChattyFacePainter extends CustomPainter {
  final double progress;
  final Offset gazeOffset;

  _ChattyFacePainter({required this.progress, required this.gazeOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = Colors.white;
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()..color = const Color(0xFFFFB4A2).withAlpha(150);

    final isBlinking = progress > 0.48 && progress < 0.52;

    if (isBlinking) {
      final leftArc = Path()
        ..moveTo(size.width * 0.24, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.36, size.width * 0.46, size.height * 0.44);
      final rightArc = Path()
        ..moveTo(size.width * 0.54, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.65, size.height * 0.36, size.width * 0.76, size.height * 0.44);
      canvas.drawPath(leftArc, mouthPaint);
      canvas.drawPath(rightArc, mouthPaint);
    } else {
      // Big sparkling anime-style expressive round eyes with gaze offset
      canvas.drawCircle(Offset(size.width * 0.35 + gazeOffset.dx, size.height * 0.42 + gazeOffset.dy), 4.8, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.65 + gazeOffset.dx, size.height * 0.42 + gazeOffset.dy), 4.8, eyePaint);

      final glintPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.width * 0.32 + gazeOffset.dx, size.height * 0.39 + gazeOffset.dy), 1.8, glintPaint);
      canvas.drawCircle(Offset(size.width * 0.62 + gazeOffset.dx, size.height * 0.39 + gazeOffset.dy), 1.8, glintPaint);
    }

    // Blush
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.56), 4.0, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.56), 4.0, blushPaint);

    // Warm Smile
    final mouth = Path()
      ..moveTo(size.width * 0.40, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.74, size.width * 0.60, size.height * 0.60);
    canvas.drawPath(mouth, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _ChattyFacePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.gazeOffset != gazeOffset;
}

/// Slide 2 Companion: "Meditating Zen Buddy" (Mindfulness with Inhale/Exhale Breathing & Floating Leaves)
class _ZenCompanionWidget extends StatefulWidget {
  const _ZenCompanionWidget();

  @override
  State<_ZenCompanionWidget> createState() => _ZenCompanionWidgetState();
}

class _ZenCompanionWidgetState extends State<_ZenCompanionWidget> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _bounceController;
  late Animation<double> _breatheScale;
  late Animation<double> _floatAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _leafFloatAnim;

  bool _showQuote = false;
  int _quoteIdx = 0;
  final List<String> _quotes = [
    "Inhale calm... Exhale worry 🌿",
    "Find your center in this moment 🌸",
    "Breathe gently and be kind to yourself ✨",
    "One deep breath resets the mind 🌱",
  ];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    _breatheScale = Tween<double>(begin: 0.94, end: 1.07).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );

    _leafFloatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _tapMascot() {
    HapticService.lightTap();
    _bounceController.forward(from: 0.0);
    setState(() {
      _quoteIdx = (_quoteIdx + 1) % _quotes.length;
      _showQuote = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showQuote = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed-height Speech Bubble
        SizedBox(
          height: 38,
          child: Center(
            child: AnimatedOpacity(
              opacity: _showQuote ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0C059669), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Text(
                  _quotes[_quoteIdx],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Interactive Mascot with Floating Zen Leaves & Inhale/Exhale Expansion
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _tapMascot,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([_breatheController, _bounceController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Floating Ambient Zen Leaves
                      Positioned(
                        left: -20 + _leafFloatAnim.value,
                        top: 20 - _leafFloatAnim.value,
                        child: Transform.rotate(
                          angle: 0.3,
                          child: const Icon(Icons.eco_rounded, color: Color(0x6610B981), size: 20),
                        ),
                      ),
                      Positioned(
                        right: -18 - _leafFloatAnim.value,
                        top: 35 + _leafFloatAnim.value,
                        child: Transform.rotate(
                          angle: -0.4,
                          child: const Icon(Icons.eco_rounded, color: Color(0x5534D399), size: 18),
                        ),
                      ),

                      // Lotus Base
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 115,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF86EFAC).withAlpha(120),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),

                      // Zen Buddy Orb
                      Transform.scale(
                        scale: _breatheScale.value * _bounceAnim.value,
                        child: Container(
                          width: 135,
                          height: 135,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withAlpha(80),
                                blurRadius: 28,
                                spreadRadius: 3,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Sprout on top
                              Positioned(
                                top: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.rotate(
                                      angle: -0.4,
                                      child: const Icon(Icons.eco_rounded, color: Color(0xFFDCFCE7), size: 16),
                                    ),
                                    Transform.rotate(
                                      angle: 0.4,
                                      child: const Icon(Icons.eco_rounded, color: Color(0xFFDCFCE7), size: 16),
                                    ),
                                  ],
                                ),
                              ),
                              // Peaceful Zen Face
                              CustomPaint(
                                size: const Size(60, 60),
                                painter: _ZenFacePainter(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ZenFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()..color = const Color(0xFFFFC0D3).withAlpha(160);

    // Peaceful closed smiling curved eyes (˘ ᵕ ˘)
    final leftEye = Path()
      ..moveTo(size.width * 0.22, size.height * 0.44)
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.52, size.width * 0.46, size.height * 0.44);
    final rightEye = Path()
      ..moveTo(size.width * 0.54, size.height * 0.44)
      ..quadraticBezierTo(size.width * 0.66, size.height * 0.52, size.width * 0.78, size.height * 0.44);
    canvas.drawPath(leftEye, arcPaint);
    canvas.drawPath(rightEye, arcPaint);

    // Cheeks
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.54), 4.0, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.54), 4.0, blushPaint);

    // Gentle tranquil smile
    final mouth = Path()
      ..moveTo(size.width * 0.42, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.70, size.width * 0.58, size.height * 0.60);
    canvas.drawPath(mouth, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slide 3 Companion: "Celebratory Star Buddy" (Wellness Tracking with Orbiting Stars & Hearts)
class _StarCompanionWidget extends StatefulWidget {
  const _StarCompanionWidget();

  @override
  State<_StarCompanionWidget> createState() => _StarCompanionWidgetState();
}

class _StarCompanionWidgetState extends State<_StarCompanionWidget> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounceController;
  late AnimationController _orbitController;
  late Animation<double> _floatAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _starPulseAnim;

  bool _showQuote = false;
  int _quoteIdx = 0;
  final List<String> _quotes = [
    "You are capable of amazing growth! ⭐",
    "Celebrate every small milestone! 💖",
    "Your journey matters deeply 🌟",
    "Every day is a fresh new start! 🚀",
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutQuad),
    );

    _starPulseAnim = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _tapMascot() {
    HapticService.lightTap();
    _bounceController.forward(from: 0.0);
    setState(() {
      _quoteIdx = (_quoteIdx + 1) % _quotes.length;
      _showQuote = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showQuote = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed-height Speech Bubble
        SizedBox(
          height: 38,
          child: Center(
            child: AnimatedOpacity(
              opacity: _showQuote ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0CE11D48), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Text(
                  _quotes[_quoteIdx],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Interactive Mascot with Orbiting Stars & Hearts
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _tapMascot,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatController, _bounceController, _orbitController]),
              builder: (context, child) {
                final orbitAngle = _orbitController.value * 2 * math.pi;
                final orbitX = math.cos(orbitAngle) * 58;
                final orbitY = math.sin(orbitAngle) * 30;

                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Orbiting Sparkle Star
                      Positioned(
                        left: (135 / 2) + orbitX - 10,
                        top: (135 / 2) + orbitY - 10,
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFFBBF24),
                          size: 18,
                        ),
                      ),

                      // Joyful Buddy Orb
                      Transform.scale(
                        scale: _bounceAnim.value,
                        child: Container(
                          width: 135,
                          height: 135,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF43F5E), Color(0xFFFB7185), Color(0xFFFDBA74)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF43F5E).withAlpha(80),
                                blurRadius: 28,
                                spreadRadius: 3,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            size: const Size(60, 60),
                            painter: _StarFacePainter(),
                          ),
                        ),
                      ),

                      // Floating Golden Star
                      Positioned(
                        right: 8,
                        top: 10,
                        child: Transform.scale(
                          scale: _starPulseAnim.value,
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFDE047),
                            size: 30,
                            shadows: [
                              Shadow(color: Color(0x66F59E0B), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),

                      // Floating Heart Sparkle
                      Positioned(
                        left: 8,
                        top: 20,
                        child: Transform.scale(
                          scale: _starPulseAnim.value,
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFFFE4E6),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StarFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = Colors.white;
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()..color = const Color(0xFFFFB4A2).withAlpha(160);

    // Big happy sparkling eyes with star glints
    canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.40), 5.0, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.67, size.height * 0.40), 5.0, eyePaint);

    final shinePaint = Paint()..color = const Color(0xFFE11D48);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.41), 2.0, shinePaint);
    canvas.drawCircle(Offset(size.width * 0.69, size.height * 0.41), 2.0, shinePaint);

    final glintPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.37), 1.6, glintPaint);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.37), 1.6, glintPaint);

    // Rosy Cheeks
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.54), 4.0, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.54), 4.0, blushPaint);

    // Joyful Open Smile
    final mouth = Path()
      ..moveTo(size.width * 0.38, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.74, size.width * 0.62, size.height * 0.58);
    canvas.drawPath(mouth, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingSlideData {
  final String title;
  final String subtitle;
  final List<Color> bgGradient;
  final Color badgeColor;

  const _OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.bgGradient,
    required this.badgeColor,
  });
}
