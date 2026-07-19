import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';
import '../signup/client_signup_step1_screen.dart';
import '../signup/professional_signup_step1_screen.dart';

/// Role Selection — matches Figma "Role Selection" frame.
/// Two role cards: Client / Patient and Professional.
/// "Already have an account? Sign In" link at the bottom.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const KausapHeader(),
              const SizedBox(height: 24),
              AuthCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back!', style: AppTextStyles.heading1),
                      const SizedBox(height: 24),

                      // Client card
                      _RoleCard(
                        icon: Icons.favorite_rounded,
                        title: 'I need support',
                        subtitle: 'Client / Patient',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ClientSignupStep1Screen(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Professional card
                      _RoleCard(
                        icon: Icons.psychology_rounded,
                        title: "I'm a Professional",
                        subtitle: 'Counselor / Psychologist / Social Worker',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfessionalSignupStep1Screen(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Sign In link
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              children: [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: AppTextStyles.link,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const AuthFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single role selection card.
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF0FDF4) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed ? AppColors.primary : AppColors.inputBorder,
            width: _pressed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: AppTextStyles.subheading.copyWith(fontSize: 13),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Temporary placeholder for signup flows — replaced in next phase.
class _SignupPlaceholder extends StatelessWidget {
  final String role;
  const _SignupPlaceholder({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$role Sign Up', style: AppTextStyles.heading2),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role == 'Client' ? Icons.favorite_rounded : Icons.psychology_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text('$role Sign Up', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text(
              'Coming in next phase.',
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      ),
    );
  }
}
