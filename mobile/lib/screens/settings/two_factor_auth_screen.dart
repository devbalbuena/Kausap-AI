import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen>
    with TickerProviderStateMixin {
  // Multi-step: 0 = Intro, 1 = QR Code scan, 2 = Verify code, 3 = Success
  int _step = 0;
  bool _isVerifying = false;
  String? _verifyError;

  // The six digit code controllers
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (_) => FocusNode());

  // Mock dynamic TOTP secret & QR data
  static const String _mockSecret = 'JBSWY3DPEHPK3PXP';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredCode =>
      _codeControllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    if (_enteredCode.length < 6) {
      setState(() => _verifyError = 'Please enter all 6 digits.');
      return;
    }

    setState(() { _isVerifying = true; _verifyError = null; });
    // Simulate network verification — accepts any 6-digit code as demo
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // In a real app, verify against backend TOTP validation
      setState(() { _isVerifying = false; _step = 3; });
    }
  }

  void _onCodeDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_codeFocusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_codeFocusNodes[index - 1]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0 && _step < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                onPressed: () => setState(() => _step--),
                color: Theme.of(context).colorScheme.onSurface,
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.pop(context),
                color: Theme.of(context).colorScheme.onSurface,
              ),
        title: Text(
          'Two-Factor Authentication',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 17,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) =>
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: FadeTransition(opacity: anim, child: child),
            ),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildQrStep();
      case 2:
        return _buildVerifyStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withAlpha(200), AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Secure Your Account',
            style: AppTextStyles.heading1.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Two-Factor Authentication adds an extra layer of security. Each time you log in, you\'ll need a 6-digit code from your authenticator app.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildInfoRow(Icons.smartphone_rounded, 'Install an authenticator app like Google Authenticator or Authy'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.qr_code_scanner_rounded, 'Scan the QR code we provide with your authenticator app'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.pin_rounded, 'Enter the 6-digit code to verify and activate 2FA'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrStep() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('Step 1: Scan QR Code', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'Open your authenticator app and scan the QR code below.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Mock QR Code visual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6))],
            ),
            child: Column(
              children: [
                // QR grid mock
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(painter: _MockQrPainter()),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Can\'t scan? Enter code manually',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Secret key card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Secret Key', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        _mockSecret,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: _mockSecret));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Secret key copied!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'I\'ve Scanned the Code',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('Step 2: Verify Code', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'Enter the 6-digit code shown in your authenticator app to confirm setup.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // 6-digit code input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 46,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _codeControllers[i].text.isNotEmpty
                        ? AppColors.primary
                        : Theme.of(context).dividerColor,
                    width: _codeControllers[i].text.isNotEmpty ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _codeControllers[i],
                  focusNode: _codeFocusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _onCodeDigitChanged(v, i),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          if (_verifyError != null)
            Text(_verifyError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Verify & Activate',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              for (final c in _codeControllers) {
                c.clear();
              }
              setState(() {});
            },
            child: const Text('Clear code', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      key: const ValueKey(3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 28),
            Text('2FA Activated!', style: AppTextStyles.heading1.copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            const Text(
              'Two-Factor Authentication is now active on your account. You\'ll need your authenticator app each time you log in.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

// Draws a mock QR code pattern using Canvas
class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E293B);
    final cellSize = size.width / 21;

    // Simplified QR pattern for UI demo purposes
    final List<List<int>> pattern = [
      [1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0],
      [0,1,0,1,1,0,1,1,0,0,1,0,1,1,0,1,1,0,1,0,1],
      [1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,0,1,1,0,1,0],
      [0,1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,0,0,1,0,1],
      [1,0,1,0,1,1,0,0,1,0,1,0,1,1,0,1,1,0,0,1,0],
      [0,1,0,1,0,0,1,1,0,0,1,0,0,0,1,0,0,1,0,0,1],
      [0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0,1,0],
      [1,1,1,1,1,1,1,0,0,1,0,1,0,0,0,1,0,1,0,0,1],
      [1,0,0,0,0,0,1,0,1,0,1,0,1,1,0,0,1,0,1,1,0],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,1,0,1,0,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,0,0,1,0,1,0,0],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,1,1,0,0,1,0,1,0],
      [1,0,0,0,0,0,1,0,1,0,1,0,0,0,0,1,1,0,1,0,1],
      [1,1,1,1,1,1,1,0,0,1,0,1,0,1,1,0,0,1,0,1,0],
    ];

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
