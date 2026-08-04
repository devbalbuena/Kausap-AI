import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_service.dart';

class InAppNotificationService {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show({
    required String title,
    required String message,
    IconData icon = Icons.chat_bubble_rounded,
    Color iconColor = const Color(0xFF2563EB),
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (navigatorKey.currentContext == null) return;
    
    // Remove existing
    _currentEntry?.remove();
    _timer?.cancel();

    _currentEntry = OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        onTap: () {
          _currentEntry?.remove();
          _currentEntry = null;
          _timer?.cancel();
          if (onTap != null) onTap();
        },
      ),
    );

    Overlay.of(navigatorKey.currentContext!).insert(_currentEntry!);
    HapticService.lightTap();

    _timer = Timer(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _InAppNotificationWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _offsetAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  widget.onTap(); // dismiss on swipe up
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x15000000), blurRadius: 16, offset: Offset(0, 8)),
                    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
        ),
      ),
    );
  }
}
