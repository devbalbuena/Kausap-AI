import 'package:flutter/material.dart';
import '../auth/role_selection_screen.dart';
import 'onboarding_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    const storage = FlutterSecureStorage();
    final seenOnboarding = await storage.read(key: 'seen_onboarding');

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) =>
            seenOnboarding == 'true' ? const RoleSelectionScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B4FE9), Color(0xFF7B61FF), Color(0xFF00C9E8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withAlpha(60), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 28),
                // Animated text
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, child) => FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(position: _textSlide, child: child),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Kausap AI',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your Mental Health Companion',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // Bottom tagline
                FadeTransition(
                  opacity: _textOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'Made with ❤️ for Filipinos',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withAlpha(160),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
