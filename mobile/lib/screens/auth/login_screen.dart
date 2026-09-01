import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
/// Features interactive Peek-a-boo mascot animations, institutional FSUU email helper,
/// prefix input icons, remember-me persistence, and seamless role routing.
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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;

  // Error state
  String? _emailError;
  String? _passwordError;
  String? _bannerError;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();

    // Listen to focus changes to trigger mascot emotions & eye gestures
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _mascotKey.currentState?.setEmailFocus(true);
      } else {
        _mascotKey.currentState?.setEmailFocus(false);
      }
    });

    _passwordFocusNode.addListener(() {
      _mascotKey.currentState?.setPasswordFocus(
        focused: _passwordFocusNode.hasFocus,
        isVisible: !_obscurePassword,
      );
    });
  }

  Future<void> _loadSavedEmail() async {
    try {
      final savedEmail = await _storage.read(key: 'saved_login_email');
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
      _mascotKey.currentState?.triggerMoodBoost(customMessage: "Please check the form! ✍️");
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

      if (_rememberMe) {
        await _storage.write(key: 'saved_login_email', value: _emailController.text.trim());
      } else {
        await _storage.delete(key: 'saved_login_email');
      }

      if (!mounted) return;

      // Auto-detect role and active status and route
      final user = authProvider.currentUser;
      if (user != null) {
        HapticService.success();
        _mascotKey.currentState?.triggerMoodBoost(customMessage: "Welcome back! 🎉✨");

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
      _mascotKey.currentState?.triggerMoodBoost(customMessage: "Let's try again, you can do it! 💙");
    } catch (e) {
      HapticService.error();
      setState(() => _bannerError =
          'Unable to sign in. Please check your credentials and try again, or reset your password.');
      _mascotKey.currentState?.triggerMoodBoost(customMessage: "Connection error. Let's retry! 🌿");
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
    _mascotKey.currentState?.triggerMoodBoost(customMessage: "Connecting to $provider! 🚀");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in is ready for single sign-on (SSO).'),
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
                    const SizedBox(height: 28),

                    // ── Animated Mascot with Peek-a-boo reactions ──
                    KausapBuddyMascot(key: _mascotKey),
                    const SizedBox(height: 20),

                    // ── Login Card ──
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
                            const SizedBox(height: 22),

                            // Email field with Mail Icon & Institutional Hint
                            Text('Email', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: 'yourname@urios.edu.ph',
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 20,
                                ),
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

                            // Password Input with Lock Icon & Peek-a-boo Trigger
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 20,
                                ),
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
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                    _mascotKey.currentState?.setPasswordFocus(
                                      focused: _passwordFocusNode.hasFocus,
                                      isVisible: !_obscurePassword,
                                    );
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

                            const SizedBox(height: 12),

                            // ── Remember Me Checkbox ──
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      HapticService.lightTap();
                                      setState(() => _rememberMe = val ?? true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    HapticService.lightTap();
                                    setState(() => _rememberMe = !_rememberMe);
                                  },
                                  child: const Text(
                                    'Remember me on this device',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Error banner
                            if (_bannerError != null) ...[
                              const SizedBox(height: 12),
                              AccessibleErrorWidget(message: _bannerError!),
                            ],

                            const SizedBox(height: 18),

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

                            // Divider
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GoogleBrandLogo(size: 19),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FacebookBrandLogo(size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sign in with Facebook',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Don't have an account? Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: AppTextStyles.body.copyWith(fontSize: 13)),
                        GestureDetector(
                          onTap: () {
                            HapticService.lightTap();
                            Navigator.of(context).push(
                              slideRoute(const ClientSignupStep1Screen()),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
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
