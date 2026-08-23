import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Wraps any child widget with a global "No Internet Connection" banner.
/// The banner animates in from the top when the device goes offline,
/// and briefly shows a "Connection Restored" confirmation when back online.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  bool _wasOffline = false;
  bool _showRestored = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConnectivityChange(bool isOnline) {
    if (!isOnline && !_wasOffline) {
      _wasOffline = true;
      _showRestored = false;
      _controller.forward();
    } else if (isOnline && _wasOffline) {
      _wasOffline = false;
      _showRestored = true;
      setState(() {});
      Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
        if (mounted) {
          _controller.reverse().then((_) {
            if (mounted) setState(() => _showRestored = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleConnectivityChange(connectivity.isOnline);
        });

        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SafeArea(
                    bottom: false,
                    child: _showRestored
                        ? const _RestoredBanner()
                        : _OfflineBanner(
                            connectionType: connectivity.connectionType,
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final String connectionType;

  const _OfflineBanner({required this.connectionType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(35),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.cloud_off_rounded, color: Color(0xFFF59E0B), size: 15),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              "You're offline • Showing saved content",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Syncs when reconnected',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoredBanner extends StatelessWidget {
  const _RestoredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF065F46),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF6EE7B7).withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF6EE7B7), size: 15),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Connection restored ✓ • Syncing data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
