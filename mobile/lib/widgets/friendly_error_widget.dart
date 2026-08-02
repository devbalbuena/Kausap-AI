import 'package:flutter/material.dart';

/// A friendly, branded error widget that replaces the standard "Red Screen of Death"
/// or ugly grey boxes when a Flutter rendering or state error occurs.
class FriendlyErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  
  const FriendlyErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Friendly Illustration (using an icon as placeholder for a real asset)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: const Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Oops, something went wrong!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              
              const Text(
                'We ran into an unexpected issue. Don\'t worry, it\'s not you—it\'s us. Try refreshing the page or restarting the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Force a rebuild/restart in a real app, or pop if it's a route
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      // Attempting a simple rebuild trick or state reset isn't easy here, 
                      // but giving a button provides better UX than nothing.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please restart the app if the issue persists.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // In debug mode, show the actual error at the bottom so developers can still see it
              if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Debug Error Info:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
