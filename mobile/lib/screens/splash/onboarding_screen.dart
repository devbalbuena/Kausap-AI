import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      icon: Icons.psychology_rounded,
      iconGradient: [Color(0xFF7B61FF), Color(0xFF00C9E8)],
      title: 'Your AI Companion',
      subtitle: 'Talk freely with Kausap AI anytime. Our AI listens, understands, and guides you through every mood.',
      illustrationColor: Color(0xFFEDE9FF),
    ),
    _OnboardingSlide(
      icon: Icons.spa_rounded,
      iconGradient: [Color(0xFF10B981), Color(0xFF34D399)],
      title: 'Mindfulness & Activities',
      subtitle: 'Practice guided breathing, daily journaling, and wellness exercises designed for students.',
      illustrationColor: Color(0xFFE6FFF5),
    ),
    _OnboardingSlide(
      icon: Icons.favorite_rounded,
      iconGradient: [Color(0xFFEC4899), Color(0xFFF97316)],
      title: 'Track Your Wellness',
      subtitle: 'Log your daily mood, view your emotional journey over time, and celebrate every step of your growth.',
      illustrationColor: Color(0xFFFFF0F7),
    ),
  ];

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 12),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(slide);
                },
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage ? AppColors.primary : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _goToNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration circle
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: slide.illustrationColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: slide.iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: slide.iconGradient[0].withAlpha(60),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(slide.icon, color: Colors.white, size: 60),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: AppTextStyles.heading1.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final Color illustrationColor;

  const _OnboardingSlide({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.illustrationColor,
  });
}
