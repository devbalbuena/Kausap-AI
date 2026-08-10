import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium friendly error widget that replaces Flutter's red "Screen of Death".
/// - In release mode: shows a clean, branded recovery screen
/// - In debug mode: also exposes the exception & stack trace for developers
class FriendlyErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const FriendlyErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFF),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Illustration
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFDDD6FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  size: 68,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 36),

              // Title
              const Text(
                'Oops, something went wrong!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "We ran into an unexpected issue. Don't worry — it's not you. Try going back or restarting the app.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 40),

              // Go Back button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    try {
                      Navigator.of(context, rootNavigator: true).pop();
                    } catch (_) {
                      // Can't pop — show a snackbar fallback
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Copy error button (debug only)
              if (!const bool.fromEnvironment('dart.vm.product'))
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: details.exceptionAsString()),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Error'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                  ),
                ),

              const Spacer(),

              // Debug error details panel
              if (!const bool.fromEnvironment('dart.vm.product')) ...[
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),
                const Text(
                  '🛠  Debug Info',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
