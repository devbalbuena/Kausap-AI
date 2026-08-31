import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/ambient_audio_service.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/haptic_service.dart';
import '../../notifications/notifications_screen.dart';
import '../admin_profile_screen.dart';

class AdminHeaderActions extends StatefulWidget {
  final Future<void> Function()? onRefresh;

  const AdminHeaderActions({
    super.key,
    this.onRefresh,
  });

  @override
  State<AdminHeaderActions> createState() => _AdminHeaderActionsState();
}

class _AdminHeaderActionsState extends State<AdminHeaderActions> with SingleTickerProviderStateMixin {
  int _unreadCount = 0;
  final NotificationService _notificationService = NotificationService();
  late AnimationController _bellAnimController;
  late Animation<double> _bellRotationAnim;
  late Animation<double> _badgeScaleAnim;
  bool _hasPlayedEntryChime = false;

  @override
  void initState() {
    super.initState();
    _bellAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bellRotationAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.25).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: -0.25, end: 0.25).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.25, end: -0.18).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: -0.18, end: 0.18).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.18, end: -0.08).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: -0.08, end: 0.08).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.08, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
    ]).animate(_bellAnimController);

    _badgeScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.30).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.30, end: 0.90).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_bellAnimController);

    _fetchUnreadCount();
  }

  @override
  void dispose() {
    _bellAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
        if (count > 0) _ringBellAndChime();
      }
    } catch (_) {}
  }

  void _ringBellAndChime() {
    if (!mounted) return;
    _bellAnimController.forward(from: 0);
    if (!_hasPlayedEntryChime) {
      _hasPlayedEntryChime = true;
      AmbientAudioService.playNotificationChimeIfAllowed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Animated Notification Bell ──
        Semantics(
          label: _unreadCount > 0 ? '$_unreadCount unread administrative alerts' : 'Administrative notifications',
          button: true,
          child: GestureDetector(
            onTap: () async {
              HapticService.lightTap();
              await Navigator.push(context, slideRoute(const NotificationsScreen()));
              _fetchUnreadCount();
              if (widget.onRefresh != null) await widget.onRefresh!();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: AnimatedBuilder(
                animation: _bellAnimController,
                builder: (context, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RotationTransition(
                        turns: _bellRotationAnim,
                        child: Icon(
                          _unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                          color: _unreadCount > 0 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: -4,
                          top: -3,
                          child: Transform.scale(
                            scale: _bellAnimController.isAnimating ? _badgeScaleAnim.value : 1.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33EF4444),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _unreadCount > 9 ? '9+' : '$_unreadCount',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // ── 2. Refresh Button ──
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7), size: 21),
          onPressed: () async {
            HapticService.lightTap();
            _fetchUnreadCount();
            if (widget.onRefresh != null) await widget.onRefresh!();
          },
        ),

        // ── 3. Profile Avatar Circle ──
        Semantics(
          label: 'Administrator Profile & Settings',
          button: true,
          child: GestureDetector(
            onTap: () async {
              HapticService.lightTap();
              await Navigator.push(context, slideRoute(const AdminProfileScreen()));
              _fetchUnreadCount();
              if (widget.onRefresh != null) await widget.onRefresh!();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final user = auth.currentUser;
                  final name = user != null ? "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim() : 'Admin';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
                  final avatarUrl = user?['avatar_url'] as String?;
                  return CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF0284C7).withAlpha(30),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('data:'))
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('data:'))
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF0284C7),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
