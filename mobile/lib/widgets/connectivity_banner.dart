import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Wraps any child widget with a global "No Internet Connection" banner.
/// The banner animates in from the top when the device goes offline,
/// and slides away when connection is restored.
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
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConnectivityChange(bool isOnline) {
    if (!isOnline && !_wasOffline) {
      // Just went offline — slide banner down
      _wasOffline = true;
      _showRestored = false;
      _controller.forward();
    } else if (isOnline && _wasOffline) {
      // Just came back online — briefly show "Restored" then hide
      _wasOffline = false;
      _showRestored = true;
      setState(() {});
      Future.delayed(const Duration(seconds: 2), () {
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
        // React to connectivity changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleConnectivityChange(connectivity.isOnline);
        });

        return Stack(
          children: [
            widget.child,
            // Animated banner overlay
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
                        ? _RestoredBanner()
                        : _OfflineBanner(),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off_rounded, color: Color(0xFFFFB703), size: 18),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'No Internet Connection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
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

class _RestoredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF2D6A4F),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_rounded, color: Color(0xFF95D5B2), size: 18),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Connection Restored ✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
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
