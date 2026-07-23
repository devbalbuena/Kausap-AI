import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim();
      final res = await context.read<AuthProvider>().verifyCode(widget.email, code);
      final resetToken = res['reset_token'];
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(resetToken: resetToken),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 12),
                                Text('Enter Verification Code', style: AppTextStyles.heading1),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please enter the 6-digit code sent to ${widget.email}.',
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.errorBorder),
                                ),
                                child: Text(_errorMessage!, style: AppTextStyles.body.copyWith(color: AppColors.error)),
                              ),
                            ],

                            // Code Field
                            TextFormField(
                              controller: _codeController,
                              style: AppTextStyles.heading1.copyWith(letterSpacing: 8, fontSize: 24),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              decoration: const InputDecoration(
                                hintText: '••••••',
                                hintStyle: TextStyle(letterSpacing: 8, fontSize: 24),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length != 6) {
                                  return 'Enter the 6-digit code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleVerify,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Verify Code'),
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
