import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/accessible_error_widget.dart';
import '../home/home_screen.dart';
import '../settings/privacy_screen.dart';

/// Client Signup — Step 3: Summary & Submit
/// Figma: "Client Signup - Step 3"
/// Shows a summary of entered data, then submits to /auth/register
class ClientSignupStep3Screen extends StatefulWidget {
  final Map<String, dynamic> signupData;
  const ClientSignupStep3Screen({super.key, required this.signupData});

  @override
  State<ClientSignupStep3Screen> createState() =>
      _ClientSignupStep3ScreenState();
}

class _ClientSignupStep3ScreenState extends State<ClientSignupStep3Screen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _error;

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      setState(() => _error = 'Please accept the Terms of Service & Privacy Policy to create your account.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Parse birthday from mm/dd/yyyy to yyyy-mm-dd for backend
      final bday = _parseBirthday(widget.signupData['birthday']);

      await authProvider.register({
        'role': 'client',
        'email': widget.signupData['email'],
        'password': widget.signupData['password'],
        'first_name': widget.signupData['first_name'],
        'last_name': widget.signupData['last_name'],
        'phone_number': widget.signupData['phone_number'],
        'birthday': bday,
        'gender': widget.signupData['gender'],
        'nationality': widget.signupData['nationality'] ?? 'Filipino',
        if (widget.signupData['hobbies'] != null)
          'hobbies': widget.signupData['hobbies'],
        'occupation': widget.signupData['occupation'],
        if (widget.signupData['address'] != null)
          'address': widget.signupData['address'],
        if (widget.signupData['bio'] != null) 'bio': widget.signupData['bio'],
      });

      if (!mounted) return;

      final user = authProvider.currentUser;
      if (user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Converts "mm/dd/yyyy" → "yyyy-mm-dd"
  String _parseBirthday(String input) {
    final parts = input.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.signupData;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const KausapHeader(),
                  const SizedBox(height: 20),
                  AuthCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProgressRow(
                              currentStep: 3,
                              totalSteps: 3,
                              onBack: () => Navigator.pop(context)),
                          const SizedBox(height: 20),

                          Text('Review your info',
                              style: AppTextStyles.heading1),
                          const SizedBox(height: 4),
                          Text('Make sure everything looks correct',
                              style: AppTextStyles.subheading),
                          const SizedBox(height: 24),

                          // Summary box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              children: [
                                _SummaryRow('Name',
                                    '${d['first_name']} ${d['last_name']}'),
                                _SummaryRow('Email', d['email']),
                                _SummaryRow('Phone', d['phone_number']),
                                _SummaryRow('Birthday', d['birthday']),
                                _SummaryRow('Gender', d['gender']),
                                _SummaryRow(
                                    'Occupation', d['occupation'] ?? '—'),
                                if (d['address'] != null)
                                  _SummaryRow('Address', d['address']),
                                if (d['bio'] != null)
                                  _SummaryRow('Bio', d['bio']),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Terms of Service & Privacy Policy Consent
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'I agree to the ',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                                                  ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                                                  ),
                                          ),
                                          const TextSpan(
                                            text: ', and understand that Kausap AI is an AI wellness companion, not a clinical psychiatric or emergency medical service.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            AccessibleErrorWidget(message: _error!),
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_agreedToTerms) ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFE2E8F0),
                                disabledForegroundColor: const Color(0xFF94A3B8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  const _ProgressRow(
      {required this.currentStep,
      required this.totalSteps,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Row(children: [
            const Icon(Icons.chevron_left,
                size: 18, color: AppColors.textSecondary),
            Text('Back',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        Row(
          children: List.generate(totalSteps, (i) {
            final active = i + 1 == currentStep;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.primary : AppColors.divider),
            );
          }),
        ),
      ],
    );
  }
}
