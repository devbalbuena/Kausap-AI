import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/accessible_error_widget.dart';
import '../../utils/app_validators.dart';
import '../home/home_screen.dart';
import '../signup/client_signup_step1_screen.dart';
import 'forgot_password_screen.dart';
import 'deactivated_account_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../counselor/counselor_dashboard_screen.dart';

/// Clean, Generic Login Screen for Students and Administrators.
/// Automatically detects Admin accounts on successful login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<KausapBuddyMascotState> _mascotKey = GlobalKey<KausapBuddyMascotState>();
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
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      return;
    }

    setState(() => _isLoading = true);
    HapticService.mediumTap();

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Auto-detect role and active status and route
      final user = authProvider.currentUser;
      if (user != null) {
        HapticService.success();
        if (user['is_active'] == false) {
          Navigator.of(context).pushAndRemoveUntil(
            slideRoute(DeactivatedAccountScreen(userProfile: user)),
            (route) => false,
          );
        } else if (user['role'] == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            slideRoute(const AdminDashboardScreen()),
            (route) => false,
          );
        } else if (user['role'] == 'counselor') {
          Navigator.of(context).pushAndRemoveUntil(
            slideRoute(const CounselorDashboardScreen()),
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
      HapticService.error();
      _parseApiError(e);
    } catch (e) {
      HapticService.error();
      setState(() => _bannerError =
          'Unable to sign in. Please check your credentials and try again, or reset your password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseApiError(ApiException e) {
    final detail = e.message.toLowerCase();

    if (e.statusCode == 403 && (detail.contains('deleted') || detail.contains('archived'))) {
      setState(() => _bannerError = 'This account has been archived. Please contact the Guidance Office for restoration.');
    } else if (e.statusCode == 401 || e.statusCode == 400) {
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

  void _handleSocialAuth(String provider) {
    HapticService.lightTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in is ready for institutional single sign-on (SSO).'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    const SizedBox(height: 32),
                    KausapBuddyMascot(key: _mascotKey),
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
                            const SizedBox(height: 24),

                            // Email field
                            Text('Email', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: 'you@example.com',
                                errorText: _emailError,
                              ),
                              validator: AppValidators.email,
                              onChanged: (val) {
                                _clearErrors();
                                if (val.isNotEmpty) {
                                  _mascotKey.currentState?.triggerMoodBoost(isTyping: true);
                                }
                              },
                            ),

                            const SizedBox(height: 18),

                            // Password Label Row with Inline "Forgot password?" Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text('Password', style: AppTextStyles.label, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    HapticService.lightTap();
                                    Navigator.of(context).push(
                                      slideRoute(const ForgotPasswordScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
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
                                  onPressed: () {
                                    HapticService.lightTap();
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: AppValidators.password,
                              onChanged: (val) {
                                _clearErrors();
                                if (val.isNotEmpty) {
                                  _mascotKey.currentState?.triggerMoodBoost(isTyping: true);
                                }
                              },
                            ),

                            // Error banner
                            if (_bannerError != null) ...[
                              const SizedBox(height: 12),
                              AccessibleErrorWidget(message: _bannerError!),
                            ],

                            const SizedBox(height: 20),

                            // Sign In button (Primary Action)
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

                            const SizedBox(height: 20),

                            // Divider (Separating Email/Password from Social Sign-Ins)
                            const Row(
                              children: [
                                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Social Sign-in: Google
                            OutlinedButton(
                              onPressed: () => _handleSocialAuth('Google'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleBrandLogo(size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Social Sign-in: Facebook
                            OutlinedButton(
                              onPressed: () => _handleSocialAuth('Facebook'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FacebookBrandLogo(size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Facebook',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Sign Up link
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  HapticService.lightTap();
                                  Navigator.of(context).push(
                                    slideRoute(const ClientSignupStep1Screen()),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.body.copyWith(color: const Color(0xFF64748B), fontSize: 13),
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
                    const SizedBox(height: 28),
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
