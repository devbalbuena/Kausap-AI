import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quick Escape Screen — disguised as a neutral "Weather" app
/// Activated via the panic button in the home screen header.
/// Tap 3 times rapidly anywhere to return to the app.
class QuickEscapeScreen extends StatefulWidget {
  const QuickEscapeScreen({super.key});

  @override
  State<QuickEscapeScreen> createState() => _QuickEscapeScreenState();
}

class _QuickEscapeScreenState extends State<QuickEscapeScreen> {
  int _tapCount = 0;
  DateTime? _firstTapTime;

  void _handleTap() {
    final now = DateTime.now();
    if (_firstTapTime == null || now.difference(_firstTapTime!).inSeconds > 3) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    if (_tapCount >= 3) {
      _tapCount = 0;
      _firstTapTime = null;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lock orientation to portrait in panic mode for consistency
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D47A1),
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return PopScope(
      // Block back button in panic mode
      canPop: false,
      child: GestureDetector(
        onTap: _handleTap,
        child: Scaffold(
          backgroundColor: const Color(0xFF0D47A1),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manila, Philippines',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Thursday',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.cloud_rounded, color: Colors.white, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: const [
                      Text(
                        '28°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Partly Cloudy',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeatherCell(time: 'Now', icon: Icons.wb_sunny_rounded, temp: '28°'),
                      _WeatherCell(time: '1 PM', icon: Icons.cloud_rounded, temp: '26°'),
                      _WeatherCell(time: '2 PM', icon: Icons.cloud_rounded, temp: '25°'),
                      _WeatherCell(time: '3 PM', icon: Icons.wb_cloudy_rounded, temp: '24°'),
                      _WeatherCell(time: '4 PM', icon: Icons.umbrella_rounded, temp: '22°'),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'Tap 3 times anywhere to return',
                    style: TextStyle(
                      color: Colors.white.withAlpha(40),
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherCell extends StatelessWidget {
  final String time;
  final IconData icon;
  final String temp;

  const _WeatherCell({required this.time, required this.icon, required this.temp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(temp, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ],
    );
  }
}
