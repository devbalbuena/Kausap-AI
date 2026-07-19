import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../auth/login_screen.dart';
import 'client_signup_step2_screen.dart';

/// Client Signup — Step 1: Basic Information
/// Figma: "Client Signup - Step 1"
/// Fields: First name, Last name, Email, Phone, Birthday, Gender, Password, Confirm Password
class ClientSignupStep1Screen extends StatefulWidget {
  const ClientSignupStep1Screen({super.key});

  @override
  State<ClientSignupStep1Screen> createState() => _ClientSignupStep1ScreenState();
}

class _ClientSignupStep1ScreenState extends State<ClientSignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
    'Other',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _birthdayController.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClientSignupStep2Screen(
        step1Data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'birthday': _birthdayController.text.trim(),
          'gender': _selectedGender!,
          'password': _passwordController.text,
        },
      ),
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
                            // Progress dots + back row
                            _ProgressRow(
                              currentStep: 1,
                              totalSteps: 3,
                              onBack: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 20),

                            // Header
                            Text('Create your account', style: AppTextStyles.heading1),
                            const SizedBox(height: 4),
                            Text('Basic Information', style: AppTextStyles.subheading),
                            const SizedBox(height: 24),

                            // First Name
                            _FieldLabel('First name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _firstNameController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(hintText: 'John'),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'First name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Last Name
                            _FieldLabel('Last name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _lastNameController,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(hintText: 'Doe'),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Last name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _FieldLabel('Email'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              style: AppTextStyles.inputText,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration:
                                  const InputDecoration(hintText: 'john.doe@gmail.com'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Email is required';
                                if (!v.contains('@'))
                                  return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone
                            _FieldLabel('Phone number'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              style: AppTextStyles.inputText,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  hintText: '+63 0123 456 7890'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Phone number is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Birthday
                            _FieldLabel('Birthday'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _birthdayController,
                              style: AppTextStyles.inputText,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'mm/dd/yyyy',
                                suffixIcon: Icon(Icons.calendar_today_outlined,
                                    size: 18, color: AppColors.textSecondary),
                              ),
                              onTap: _pickBirthday,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Birthday is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Gender
                            _FieldLabel('Gender'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              style: AppTextStyles.inputText,
                              decoration: const InputDecoration(
                                  hintText: 'Select Gender'),
                              items: _genderOptions
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedGender = v),
                              validator: (v) =>
                                  v == null ? 'Please select a gender' : null,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            _FieldLabel('Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              style: AppTextStyles.inputText,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Password is required';
                                if (v.length < 8)
                                  return 'Password must be at least 8 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            _FieldLabel('Confirm password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              style: AppTextStyles.inputText,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Please confirm your password';
                                if (v != _passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Next button
                            ElevatedButton(
                              onPressed: _next,
                              child: const Text('Next'),
                            ),
                            const SizedBox(height: 12),

                            // Sign In link
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context)
                                    .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (r) => false,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary),
                                    children: [
                                      const TextSpan(
                                          text: 'Already have an account? '),
                                      TextSpan(
                                          text: 'Sign In',
                                          style: AppTextStyles.link),
                                    ],
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
      ),
    );
  }
}

/// Step progress dots + back button — Figma "Progress & Back"
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
          child: Row(
            children: [
              const Icon(Icons.chevron_left, size: 18, color: AppColors.textSecondary),
              Text('Back', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            ],
          ),
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
                color: active ? AppColors.primary : AppColors.divider,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Reusable field label widget
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.label);
}
