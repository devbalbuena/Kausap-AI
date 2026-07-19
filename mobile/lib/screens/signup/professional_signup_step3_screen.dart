import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'professional_pending_screen.dart';

class ProfessionalSignupStep3Screen extends StatefulWidget {
  final Map<String, dynamic> signupData;
  const ProfessionalSignupStep3Screen({super.key, required this.signupData});

  @override
  State<ProfessionalSignupStep3Screen> createState() =>
      _ProfessionalSignupStep3ScreenState();
}

class _ProfessionalSignupStep3ScreenState
    extends State<ProfessionalSignupStep3Screen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final bday = _parseBirthday(widget.signupData['birthday']);

      final payload = {
        'role': 'professional',
        'email': widget.signupData['email'],
        'password': widget.signupData['password'],
        'first_name': widget.signupData['first_name'],
        'last_name': widget.signupData['last_name'],
        'phone_number': widget.signupData['phone_number'],
        'birthday': bday,
        'gender': widget.signupData['gender'],
        
        // Professional fields
        'profession': widget.signupData['profession'],
        'prc_license_number': widget.signupData['prc_license_number'],
        'specialization': widget.signupData['specialization'],
        'years_of_experience': widget.signupData['years_of_experience'],
        'is_accepting_clients': widget.signupData['is_accepting_clients'],
        'location': widget.signupData['location'],
      };

      if (widget.signupData['license_url'] != null) {
        payload['license_url'] = widget.signupData['license_url'];
      }
      if (widget.signupData['professional_bio'] != null) {
        payload['professional_bio'] = widget.signupData['professional_bio'];
      }

      await authProvider.register(payload);

      if (!mounted) return;

      // Unverified professionals go to Pending screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfessionalPendingScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

                          Text('Review your profile',
                              style: AppTextStyles.heading1),
                          const SizedBox(height: 4),
                          Text('Make sure your professional info is correct',
                              style: AppTextStyles.subheading),
                          const SizedBox(height: 24),

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
                                _SummaryRow('Profession', d['profession']),
                                _SummaryRow('License', d['prc_license_number']),
                                _SummaryRow('Specialty', d['specialization']),
                                _SummaryRow('Experience',
                                    '${d['years_of_experience']} years'),
                                _SummaryRow('Location', d['location']),
                                _SummaryRow('Accepting',
                                    d['is_accepting_clients'] ? 'Yes' : 'No'),
                              ],
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.errorBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: AppTextStyles.body.copyWith(
                                            color: AppColors.error)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : const Text('Submit Application'),
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
            child: Text(value, style: AppTextStyles.body),
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
