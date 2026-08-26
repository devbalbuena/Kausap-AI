import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'client_signup_step3_screen.dart';

/// Client Signup — Step 2: About You
/// Figma: "Client Signup - Step 2"
/// Fields: Occupation (dropdown), Address (optional), Bio (optional)
class ClientSignupStep2Screen extends StatefulWidget {
  final Map<String, dynamic> step1Data;
  const ClientSignupStep2Screen({super.key, required this.step1Data});

  @override
  State<ClientSignupStep2Screen> createState() =>
      _ClientSignupStep2ScreenState();
}

class _ClientSignupStep2ScreenState extends State<ClientSignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedOccupation = 'Student';
  String _selectedNationality = 'Filipino';
  final List<String> _selectedHobbies = ['📚 Reading', '🎵 Music'];

  static const List<String> _occupationOptions = [
    'Student',
    'Employed',
    'Self-employed',
    'Unemployed',
    'Other',
  ];

  static const List<String> _nationalityOptions = [
    'Filipino',
    'Dual Citizen',
    'International Student',
    'Other',
  ];

  static const List<String> _availableHobbies = [
    '📚 Reading',
    '🎵 Music',
    '🎮 Gaming',
    '🏃 Sports & Fitness',
    '🎨 Art & Drawing',
    '✍️ Journaling',
    '🧘 Meditation',
    '🍳 Cooking',
    '🌿 Nature & Outdoors',
    '🎬 Movies & Series',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final allData = {
      ...widget.step1Data,
      'occupation': _selectedOccupation,
      'nationality': _selectedNationality,
      'hobbies': _selectedHobbies.isNotEmpty ? _selectedHobbies.join(', ') : null,
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    };
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClientSignupStep3Screen(signupData: allData),
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

                            Text('About You', style: AppTextStyles.heading1),
                            const SizedBox(height: 4),
                            Text('Tell us a bit more about yourself',
                                style: AppTextStyles.subheading),
                            const SizedBox(height: 24),

                            // Occupation
                            _FieldLabel('I am a...'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedOccupation,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'Select your occupation'),
                              items: _occupationOptions
                                  .map((o) => DropdownMenuItem(
                                      value: o, child: Text(o)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedOccupation = v),
                              validator: (v) =>
                                  v == null ? 'Please select your occupation' : null,
                            ),
                            const SizedBox(height: 16),

                            // Nationality
                            _FieldLabel('Nationality'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedNationality,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'Select your nationality'),
                              items: _nationalityOptions
                                  .map((n) => DropdownMenuItem(
                                      value: n, child: Text(n)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedNationality = v ?? 'Filipino'),
                            ),
                            const SizedBox(height: 16),

                            // Hobbies & Coping Outlets
                            _FieldLabel('Hobbies & Coping Outlets'),
                            const SizedBox(height: 4),
                            Text('Select activities that help you unwind (used for personalized AI coping metaphors)',
                                style: AppTextStyles.caption.copyWith(fontSize: 11)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _availableHobbies.map((hobby) {
                                final isSelected = _selectedHobbies.contains(hobby);
                                return FilterChip(
                                  label: Text(hobby),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedHobbies.add(hobby);
                                      } else {
                                        _selectedHobbies.remove(hobby);
                                      }
                                    });
                                  },
                                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                                  checkmarkColor: AppColors.primary,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  labelStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : const Color(0xFF334155),
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Address (optional)
                            _FieldLabel('Address (optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. Butuan City, Philippines'),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),

                            // Bio (optional)
                            _FieldLabel('Bio (optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bioController,
                              style: AppTextStyles.inputText,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText:
                                    'Tell us a little about yourself...',
                                alignLabelWithHint: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
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
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.label);
}
