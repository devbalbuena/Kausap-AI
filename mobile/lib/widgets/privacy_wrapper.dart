import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/pin_service.dart';
import '../services/privacy_settings_service.dart';
import '../main.dart';
import '../screens/auth/role_selection_screen.dart';

/// Wraps the entire app and:
/// 1. Blurs app content when backgrounded (if Privacy Screen is enabled)
/// 2. Enforces Session Timeout (logout after 15 min background)
class PrivacyWrapper extends StatefulWidget {
  final Widget child;
  const PrivacyWrapper({super.key, required this.child});

  @override
  State<PrivacyWrapper> createState() => _PrivacyWrapperState();
}

class _PrivacyWrapperState extends State<PrivacyWrapper> with WidgetsBindingObserver {
  bool _isHidden = false;
  DateTime? _backgroundTime;

  // Settings loaded dynamically from secure storage
  bool _privacyScreenEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final privacyOn = await PrivacySettingsService.isPrivacyScreenEnabled();
    if (mounted) setState(() => _privacyScreenEnabled = privacyOn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_privacyScreenEnabled && !_isHidden) {
        setState(() => _isHidden = true);
        _backgroundTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isHidden) {
        setState(() => _isHidden = false);
        // Reload settings in case they changed
        _loadSettings();
      }

      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        if (diff.inMinutes >= 15) {
          _handleSessionTimeout();
        }
        _backgroundTime = null;
      }
    }
  }

  Future<void> _handleSessionTimeout() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      await auth.logout();
      await PinService.disablePin();
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isHidden)
          Positioned.fill(
            child: _PrivacyOverlay(),
          ),
      ],
    );
  }
}

/// Premium privacy overlay shown when the app is backgrounded.
class _PrivacyOverlay extends StatefulWidget {
  @override
  State<_PrivacyOverlay> createState() => _PrivacyOverlayState();
}

class _PrivacyOverlayState extends State<_PrivacyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A1628).withAlpha(230),
                const Color(0xFF0D2140).withAlpha(240),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon / lock indicator
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withAlpha(100),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kausap AI',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your session is private',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white38, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Protected by Privacy Screen',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
