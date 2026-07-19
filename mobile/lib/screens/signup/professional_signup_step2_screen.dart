import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'professional_signup_step3_screen.dart';

class ProfessionalSignupStep2Screen extends StatefulWidget {
  final Map<String, dynamic> step1Data;
  const ProfessionalSignupStep2Screen({super.key, required this.step1Data});

  @override
  State<ProfessionalSignupStep2Screen> createState() =>
      _ProfessionalSignupStep2ScreenState();
}

class _ProfessionalSignupStep2ScreenState
    extends State<ProfessionalSignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();

  final _prcController = TextEditingController();
  final _licenseUrlController = TextEditingController(); // Placeholder for upload
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedProfession;
  bool _isAcceptingClients = true;

  static const List<String> _professionOptions = [
    'Psychiatrist',
    'Psychologist',
    'Counselor',
    'Social Worker',
    'Other',
  ];

  @override
  void dispose() {
    _prcController.dispose();
    _licenseUrlController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    final allData = {
      ...widget.step1Data,
      'profession': _selectedProfession,
      'prc_license_number': _prcController.text.trim(),
      'license_url': _licenseUrlController.text.trim().isEmpty
          ? null
          : _licenseUrlController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'years_of_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
      'professional_bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      'is_accepting_clients': _isAcceptingClients,
      'location': _locationController.text.trim(),
    };

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfessionalSignupStep3Screen(signupData: allData),
    ));
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
                              currentStep: 2,
                              totalSteps: 3,
                              onBack: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 20),

                            Text('Professional Profile',
                                style: AppTextStyles.heading1),
                            const SizedBox(height: 4),
                            Text('Tell us about your practice',
                                style: AppTextStyles.subheading),
                            const SizedBox(height: 24),

                            _FieldLabel('Profession'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedProfession,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'Select your profession'),
                              items: _professionOptions
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedProfession = v),
                              validator: (v) =>
                                  v == null ? 'Please select a profession' : null,
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('PRC License Number'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _prcController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'Enter license number'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'License number is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('License Document URL (Optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _licenseUrlController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'https://link-to-license.com'),
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('Specialization'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _specializationController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. Clinical Psychology'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Specialization is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('Years of Experience'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _experienceController,
                              style: AppTextStyles.inputText,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(hintText: 'e.g. 5'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Experience is required';
                                if (int.tryParse(v.trim()) == null)
                                  return 'Must be a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('Location / Clinic Address'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _locationController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. Makati Medical Center'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Location is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('Professional Bio (Optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bioController,
                              style: AppTextStyles.inputText,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Describe your approach...',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 24),

                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primary,
                              title: const Text('Accepting New Clients'),
                              subtitle: const Text(
                                  'Display your profile to clients looking for support.'),
                              value: _isAcceptingClients,
                              onChanged: (v) =>
                                  setState(() => _isAcceptingClients = v),
                            ),
                            const SizedBox(height: 28),

                            ElevatedButton(
                              onPressed: _next,
                              child: const Text('Next'),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.label);
}
