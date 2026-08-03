import 'package:flutter/material.dart';
import '../../services/pin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

/// Modes for this screen
enum AppLockMode {
  setup,   // Setting a new PIN
  confirm, // Confirming the new PIN
  change,  // Changing existing PIN (requires old PIN first)
  verify,  // Verifying the existing PIN (for disable)
}

/// App Lock Setup Screen — allows users to set a secure 4-digit PIN.
/// Beautiful custom PIN pad with animated dot indicators.
class AppLockSetupScreen extends StatefulWidget {
  final AppLockMode mode;
  const AppLockSetupScreen({super.key, this.mode = AppLockMode.setup});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPin = '';
  AppLockMode _currentMode = AppLockMode.setup;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticService.light();
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _handleComplete);
    }
  }

  void _removeDigit() {
    if (_enteredPin.isEmpty) return;
    HapticService.light();
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  Future<void> _handleComplete() async {
    if (_isLoading) return;

    if (_currentMode == AppLockMode.setup) {
      // Save first PIN and move to confirm
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _currentMode = AppLockMode.confirm;
      });
    } else if (_currentMode == AppLockMode.confirm) {
      if (_enteredPin == _firstPin) {
        setState(() => _isLoading = true);
        await PinService.setPin(_enteredPin);
        if (mounted) {
          HapticService.success();
          Navigator.pop(context, true); // Return true = PIN set successfully
        }
      } else {
        _showError('PINs do not match. Please try again.');
      }
    } else if (_currentMode == AppLockMode.verify) {
      setState(() => _isLoading = true);
      final valid = await PinService.verifyPin(_enteredPin);
      if (mounted) {
        if (valid) {
          HapticService.success();
          Navigator.pop(context, true);
        } else {
          _showError('Incorrect PIN. Please try again.');
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    HapticService.error();
    setState(() {
      _errorMessage = msg;
      _enteredPin = '';
      _firstPin = '';
      if (_currentMode == AppLockMode.confirm) _currentMode = AppLockMode.setup;
    });
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  String get _title {
    switch (_currentMode) {
      case AppLockMode.setup:
        return 'Create PIN';
      case AppLockMode.confirm:
        return 'Confirm PIN';
      case AppLockMode.verify:
        return 'Enter Current PIN';
      case AppLockMode.change:
        return 'Change PIN';
    }
  }

  String get _subtitle {
    switch (_currentMode) {
      case AppLockMode.setup:
        return 'Choose a 4-digit PIN to lock the app';
      case AppLockMode.confirm:
        return 'Re-enter your PIN to confirm';
      case AppLockMode.verify:
        return 'Enter your current PIN to continue';
      case AppLockMode.change:
        return 'Enter your new 4-digit PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Back / Cancel button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
                    ),
                    child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 24),

                  // Title & Subtitle
                  Text(
                    _title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // PIN Dot Indicators with shake animation
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final dx = _shakeAnim.value > 0
                          ? (12 * (0.5 - _shakeAnim.value)).abs() * ((_shakeAnim.value * 10).toInt().isEven ? 1 : -1)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: filled ? AppColors.primary : Colors.white38,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Error message
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _errorMessage != null ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5858).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage ?? '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFFFF8A80),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Number Pad
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: SizedBox()), // empty
                      Expanded(child: _buildDigitButton('0')),
                      Expanded(
                        child: GestureDetector(
                          onTap: _removeDigit,
                          child: Container(
                            height: 64,
                            color: Colors.transparent,
                            child: const Icon(
                              Icons.backspace_outlined,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      children: digits.map((d) => Expanded(child: _buildDigitButton(d))).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
