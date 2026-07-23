import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'role_selection_screen.dart';
import '../home/home_screen.dart';
import '../professional/professional_base_screen.dart';
import '../signup/client_signup_step1_screen.dart';
import '../signup/professional_signup_step1_screen.dart';
import 'forgot_password_screen.dart';

/// Unified Login Screen — matches Figma "Unified Login" + "Login Error State" frames.
///
/// Error states from Figma:
///   - Field-level: "No account found with this email." under email field
///   - Field-level: "Incorrect password. Try again." under password field
///   - Banner: "Unable to sign in. Please check your credentials and try again, or reset your password."
///     (shown when the backend doesn't distinguish which field failed)
class LoginScreen extends StatefulWidget {
  final String? defaultRole;
  const LoginScreen({super.key, this.defaultRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Error state — mirrors Figma "Login Error State" frame
  String? _emailError;
  String? _passwordError;
  String? _bannerError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _bannerError = null;
    });
  }

  Future<void> _handleLogin() async {
    _clearErrors();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Navigate based on role
      final user = authProvider.currentUser;
      if (user != null) {
        if (user['role'] == 'professional') {
          final profile = user['professional_profile'];
          if (profile != null && profile['is_verified'] == true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ProfessionalBaseScreen()),
              (route) => false,
            );
          } else {
            // Unverified professional — let main.dart AuthWrapper handle it or route directly
            // For now, if unverified, just let AuthWrapper decide by popping to root, or push pending screen directly.
            // Since login is pushed over AuthWrapper, we need to push to pending screen directly.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), // A simple hack is to just pop and let main.dart rebuild
              (route) => false,
            );
          }
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
            (route) => false,
          );
        }
      }
    } on ApiException catch (e) {
      _parseApiError(e);
    } catch (e) {
      setState(() => _bannerError =
          'Unable to sign in. Please check your credentials and try again, or reset your password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseApiError(ApiException e) {
    final detail = e.message.toLowerCase();

    if (e.statusCode == 401 || e.statusCode == 400) {
      // Try to match field-level errors from Figma
      if (detail.contains('email') || detail.contains('not found') || detail.contains('no account')) {
        setState(() => _emailError = 'No account found with this email.');
      } else if (detail.contains('password') || detail.contains('incorrect')) {
        setState(() => _passwordError = 'Incorrect password. Try again.');
      } else {
        // Generic banner from Figma "Error Banner"
        setState(() => _bannerError =
            'Unable to sign in. Please check your credentials and try again, or reset your password.');
      }
    } else {
      setState(() => _bannerError =
          'Unable to sign in. Please check your credentials and try again, or reset your password.');
    }
  }

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
          child: Form(
            key: _formKey,
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
                        // Header
                        Text('Welcome back!', style: AppTextStyles.heading1),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your Kausap AI account',
                          style: AppTextStyles.subheading,
                        ),
                        const SizedBox(height: 28),

                        // Email field
                        Text('Email', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            errorText: _emailError,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                          onChanged: (_) => _clearErrors(),
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        Text('Password', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            return null;
                          },
                          onChanged: (_) => _clearErrors(),
                        ),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              'FORGOT PASSWORD?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // Error banner (Figma "Error Banner")
                        if (_bannerError != null) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(message: _bannerError!),
                        ],

                        const SizedBox(height: 8),

                        // Divider — "or" section from Figma
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('or', style: AppTextStyles.subheading),
                            ),
                            Expanded(child: Divider(color: AppColors.divider)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Sign In button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Sign In'),
                        ),

                        const SizedBox(height: 16),

                        // Social Sign-in Buttons
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: AppColors.inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', width: 24, height: 24),
                              const SizedBox(width: 12),
                              Text('Sign in with Google', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: AppColors.inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network('https://upload.wikimedia.org/wikipedia/commons/0/05/Facebook_Logo_%282019%29.png', width: 24, height: 24),
                              const SizedBox(width: 12),
                              Text('Sign in with Facebook', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign Up link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Widget nextScreen;
                              if (widget.defaultRole == 'client') {
                                nextScreen = const ClientSignupStep1Screen();
                              } else if (widget.defaultRole == 'professional') {
                                nextScreen = const ProfessionalSignupStep1Screen();
                              } else {
                                nextScreen = const RoleSelectionScreen();
                              }
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => nextScreen),
                                (route) => false,
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(text: 'Sign Up', style: AppTextStyles.link),
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
      ),
    ),
  ),
);
}
}

/// Error banner — matches the "Error Banner" frame in Figma Login Error State.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
