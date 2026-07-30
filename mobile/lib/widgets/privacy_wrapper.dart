import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import '../screens/auth/role_selection_screen.dart';

class PrivacyWrapper extends StatefulWidget {
  final Widget child;
  const PrivacyWrapper({super.key, required this.child});

  @override
  State<PrivacyWrapper> createState() => _PrivacyWrapperState();
}

class _PrivacyWrapperState extends State<PrivacyWrapper> with WidgetsBindingObserver {
  bool _isHidden = false;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (!_isHidden) {
        setState(() => _isHidden = true);
        _backgroundTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isHidden) {
        setState(() => _isHidden = false);
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security_rounded, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Kausap AI is locked',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
