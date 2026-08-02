import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/retry_service.dart';

/// Wraps the app to display a "Retrying..." banner when network requests fail and retry.
class RetryBanner extends StatefulWidget {
  final Widget child;
  const RetryBanner({super.key, required this.child});

  @override
  State<RetryBanner> createState() => _RetryBannerState();
}

class _RetryBannerState extends State<RetryBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  
  bool _isVisible = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRetryChange(bool isRetrying, String message) {
    if (isRetrying && !_isVisible) {
      _isVisible = true;
      _message = message;
      _controller.forward();
    } else if (isRetrying && _isVisible) {
      setState(() => _message = message);
    } else if (!isRetrying && _isVisible) {
      _isVisible = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetryService>(
      builder: (context, retryService, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleRetryChange(retryService.isRetrying, retryService.retryMessage);
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
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE63946),
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
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _message.isNotEmpty ? _message : 'Retrying...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
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
      },
    );
  }
}
