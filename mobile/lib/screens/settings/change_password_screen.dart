import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../widgets/rate_app_dialog.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/accessible_error_widget.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Password strength: 0–4
  int _strengthScore = 0;

  @override
  void initState() {
    super.initState();
    _newPasswordCtrl.addListener(_evaluateStrength);
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _evaluateStrength() {
    final pwd = _newPasswordCtrl.text;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (pwd.contains(RegExp(r'[A-Z]'))) score++;
    if (pwd.contains(RegExp(r'[0-9]'))) score++;
    if (pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    setState(() => _strengthScore = score.clamp(0, 4));
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 0:
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF3B82F6);
      case 4:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final currentPwd = _currentPasswordCtrl.text.trim();
    final newPwd = _newPasswordCtrl.text.trim();
    final confirmPwd = _confirmPasswordCtrl.text.trim();

    if (currentPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }
    if (newPwd != confirmPwd) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }
    if (newPwd.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (_strengthScore < 2) {
      setState(() => _errorMessage = 'Please choose a stronger password.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiClient().put(ApiConfig.changePassword, body: {
        'old_password': currentPwd,
        'new_password': newPwd,
      });
      if (mounted) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully! 🎉'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        await RateAppDialog.show(context);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('ApiException: 400 - ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          'Change Password',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Choose a strong password with uppercase letters, numbers, and symbols.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Error banner — accessible (icon + shape, not just color)
              if (_errorMessage != null) ...[
                AccessibleErrorWidget(message: _errorMessage!),
                const SizedBox(height: 16),
              ],

              _buildLabel('Current Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _currentPasswordCtrl,
                hint: 'Enter current password',
                isVisible: _currentVisible,
                onToggle: () => setState(() => _currentVisible = !_currentVisible),
              ),
              const SizedBox(height: 20),

              _buildLabel('New Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _newPasswordCtrl,
                hint: 'Enter new password',
                isVisible: _newVisible,
                onToggle: () => setState(() => _newVisible = !_newVisible),
              ),
              const SizedBox(height: 12),

              // Strength Meter
              if (_newPasswordCtrl.text.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(4, (i) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i < _strengthScore ? _strengthColor : const Color(0xFFE2E8F0),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _strengthLabel,
                        key: ValueKey(_strengthLabel),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _strengthColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRequirementRow('At least 8 characters', _newPasswordCtrl.text.length >= 8),
                _buildRequirementRow('Contains uppercase letter', _newPasswordCtrl.text.contains(RegExp(r'[A-Z]'))),
                _buildRequirementRow('Contains number', _newPasswordCtrl.text.contains(RegExp(r'[0-9]'))),
                _buildRequirementRow('Contains special character', _newPasswordCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))),
                const SizedBox(height: 12),
              ],

              _buildLabel('Confirm New Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordCtrl,
                hint: 'Re-enter new password',
                isVisible: _confirmVisible,
                onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _strengthScore >= 3 ? AppColors.primary : AppColors.primary.withAlpha(150),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Update Password',
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
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20, color: AppColors.textSecondary),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met ? const Color(0xFF22C55E) : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? const Color(0xFF22C55E) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
