import 'package:flutter/material.dart';
import '../../utils/app_routes.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/accessible_error_widget.dart';
import '../../utils/app_validators.dart';
import '../home/home_screen.dart';
import '../signup/client_signup_step1_screen.dart';
import 'forgot_password_screen.dart';
import '../admin/admin_dashboard_screen.dart';

/// Clean, Generic Login Screen for Students and Users.
/// Automatically detects Admin accounts on successful login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Error state
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

      // Auto-detect role and route
      final user = authProvider.currentUser;
      if (user != null) {
        if (user['role'] == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            slideRoute(const AdminDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            slideRoute(HomeScreen(user: user)),
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
      if (detail.contains('email') || detail.contains('not found') || detail.contains('no account')) {
        setState(() => _emailError = 'No account found with this email.');
      } else if (detail.contains('password') || detail.contains('incorrect')) {
        setState(() => _passwordError = 'Incorrect password. Try again.');
      } else {
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
                            Text('Welcome to Kausap AI', style: AppTextStyles.heading1),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue',
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
                              validator: AppValidators.email,
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
                              validator: AppValidators.password,
                              onChanged: (_) => _clearErrors(),
                            ),

                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    slideRoute(const ForgotPasswordScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
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

                            // Error banner
                            if (_bannerError != null) ...[
                              const SizedBox(height: 8),
                              AccessibleErrorWidget(message: _bannerError!),
                            ],

                            const SizedBox(height: 8),

                            // Divider
                            const Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.divider)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                                side: const BorderSide(color: AppColors.inputBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFDDDDDD)),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontFamily: 'Arial',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: const BorderSide(color: AppColors.inputBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1877F2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'f',
                                        style: TextStyle(
                                          fontFamily: 'Arial',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Facebook',
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Sign Up link
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    slideRoute(const ClientSignupStep1Screen()),
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
