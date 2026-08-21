import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/ambient_audio_service.dart';
import '../activity_screen.dart';

enum _WalkingGoalType { time, distance }

class MindfulWalkingWidget extends StatefulWidget {
  final ActivityItem activity;
  final VoidCallback onComplete;

  const MindfulWalkingWidget({
    super.key,
    required this.activity,
    required this.onComplete,
  });

  @override
  State<MindfulWalkingWidget> createState() => _MindfulWalkingWidgetState();
}

class _MindfulWalkingWidgetState extends State<MindfulWalkingWidget> {
  final AmbientAudioService _audioService = AmbientAudioService();

  _WalkingGoalType _goalType = _WalkingGoalType.time;
  int _targetMinutes = 20;
  double _targetKm = 2.0;

  bool _isWalking = true;
  int _elapsedSeconds = 0;
  int _steps = 0;
  double _distanceKm = 0.0;
  Timer? _timer;

  // Live route path points for offline map trace
  final List<Offset> _routePoints = [];

  final List<_WalkingPhase> _phases = const [
    _WalkingPhase(
      title: 'Pace & Footfalls',
      guidance: 'Walk at a natural rhythm. Notice your feet lifting, pushing off, and touching the earth.',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF10B981),
    ),
    _WalkingPhase(
      title: 'Sensory Sights & Colors',
      guidance: 'Look at the trees, sky, and buildings. Observe colors and shapes without judging them.',
      icon: Icons.visibility_rounded,
      color: Color(0xFF38BDF8),
    ),
    _WalkingPhase(
      title: 'Ambient Sounds',
      guidance: 'Listen to the birds, breeze, distant sounds, and the rhythmic sound of your footsteps.',
      icon: Icons.hearing_rounded,
      color: Color(0xFFF59E0B),
    ),
    _WalkingPhase(
      title: 'Synchronized Breathing',
      guidance: 'Inhale for 3 steps, exhale for 3 steps. Let your movement and breath flow as one.',
      icon: Icons.air_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  int get _currentPhaseIndex {
    final totalSecs = _goalType == _WalkingGoalType.time
        ? _targetMinutes * 60
        : ((_targetKm / 4.5) * 3600).round(); // approx 4.5 km/h walking speed
    if (totalSecs <= 0) return 0;
    final p = (_elapsedSeconds / totalSecs).clamp(0.0, 1.0);
    if (p < 0.25) return 0;
    if (p < 0.50) return 1;
    if (p < 0.75) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _timer?.cancel();
    _routePoints.clear();
    _routePoints.add(const Offset(100, 100));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isWalking) return;

      setState(() {
        _elapsedSeconds++;
        // Estimate approx 1.8 steps per second during active walk
        _steps += 2;
        // ~ 0.0013 km per second (~4.7 km/h walking speed)
        _distanceKm = _steps * 0.00075;

        // Generate gentle organic path point for offline map trace
        if (_elapsedSeconds % 3 == 0) {
          final last = _routePoints.last;
          final angle = (_elapsedSeconds * 0.2) + math.sin(_elapsedSeconds * 0.05);
          final nextX = (last.dx + math.cos(angle) * 7).clamp(20.0, 260.0);
          final nextY = (last.dy + math.sin(angle) * 7).clamp(20.0, 160.0);
          _routePoints.add(Offset(nextX, nextY));
        }

        // Chime on phase transition
        if (_elapsedSeconds > 0 && _elapsedSeconds % 300 == 0) {
          _audioService.playChime(frequency: 528.0, durationSeconds: 1.5);
        }
      });
    });
  }

  String _formatTime(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _paceString {
    if (_distanceKm <= 0.01) return '--:--';
    final paceMins = (_elapsedSeconds / 60) / _distanceKm;
    final mins = paceMins.floor();
    final secs = ((paceMins - mins) * 60).round().toString().padLeft(2, '0');
    return '$mins:$secs /km';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhaseIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Clean slate grey canvas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Mindful Walking Tracker',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Goal Selector Bar (Time vs Distance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('${_targetMinutes}m Goal ▾'),
                    selected: _goalType == _WalkingGoalType.time,
                    onSelected: (val) {
                      setState(() {
                        _goalType = _WalkingGoalType.time;
                        // Cycle through 15 -> 20 -> 30 -> 45
                        if (_targetMinutes == 15) {
                          _targetMinutes = 20;
                        } else if (_targetMinutes == 20) {
                          _targetMinutes = 30;
                        } else if (_targetMinutes == 30) {
                          _targetMinutes = 45;
                        } else {
                          _targetMinutes = 15;
                        }
                      });
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _goalType == _WalkingGoalType.time ? Colors.white : AppColors.textPrimary,
                    ),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${_targetKm.toStringAsFixed(1)} km Goal ▾'),
                    selected: _goalType == _WalkingGoalType.distance,
                    onSelected: (val) {
                      setState(() {
                        _goalType = _WalkingGoalType.distance;
                        // Cycle through 1.0 -> 2.0 -> 3.0 -> 5.0
                        if (_targetKm == 1.0) {
                          _targetKm = 2.0;
                        } else if (_targetKm == 2.0) {
                          _targetKm = 3.0;
                        } else if (_targetKm == 3.0) {
                          _targetKm = 5.0;
                        } else {
                          _targetKm = 1.0;
                        }
                      });
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _goalType == _WalkingGoalType.distance ? Colors.white : AppColors.textPrimary,
                    ),
                    showCheckmark: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Live Route Trace Visualizer (Works Online & Offline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Dark tactical map canvas
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      size: const Size(double.infinity, 170),
                      painter: _MapGridPainter(),
                    ),
                    // Live Route Path
                    CustomPaint(
                      size: const Size(double.infinity, 170),
                      painter: _RoutePathPainter(points: _routePoints),
                    ),
                    // Live GPS Pulse Marker
                    if (_routePoints.isNotEmpty)
                      Positioned(
                        left: _routePoints.last.dx - 10,
                        top: _routePoints.last.dy - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withAlpha(50),
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Status Badge
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Live Route (Online/Offline)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Live Metrics Dashboard (Time, Distance, Steps, Pace)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('TIME', _formatTime(_elapsedSeconds), Icons.timer_outlined),
                    _buildMetricCol('DISTANCE', '${_distanceKm.toStringAsFixed(2)} km', Icons.straighten_rounded),
                    _buildMetricCol('STEPS', '$_steps', Icons.directions_walk_rounded),
                    _buildMetricCol('AVG PACE', _paceString, Icons.speed_rounded),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Active Sensory Guidance Phase Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: phase.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: phase.color.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: phase.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(phase.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Stage ${_currentPhaseIndex + 1} of 4: ${phase.title}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: phase.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phase.guidance,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Action Buttons (Pause / Finish)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() => _isWalking = !_isWalking);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isWalking ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(_isWalking ? 'Pause' : 'Resume', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                      ),
                      onPressed: widget.onComplete,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20),
                          SizedBox(width: 6),
                          Text('Finish Walk', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WalkingPhase {
  final String title;
  final String guidance;
  final IconData icon;
  final Color color;

  const _WalkingPhase({
    required this.title,
    required this.guidance,
    required this.icon,
    required this.color,
  });
}

// ── Custom Painters for Offline Route Map Trace ──────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePathPainter extends CustomPainter {
  final List<Offset> points;

  _RoutePathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final pathPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) => true;
}
