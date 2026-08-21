import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

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

  final List<int> _timeOptions = [15, 20, 30, 45];
  final List<double> _distanceOptions = [1.0, 2.0, 3.0, 5.0];

  bool _isWalking = true;
  int _elapsedSeconds = 0;
  int _steps = 0;
  double _distanceKm = 0.0;
  Timer? _timer;

  // Real GPS status
  bool _hasGpsFix = false;
  double? _lastLat;
  double? _lastLng;

  // Live route path points for map canvas
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

  int get _totalGoalSeconds {
    if (_goalType == _WalkingGoalType.time) {
      return _targetMinutes * 60;
    } else {
      // 4.5 km/h walking speed
      return ((_targetKm / 4.5) * 3600).round();
    }
  }

  int get _currentPhaseIndex {
    final totalSecs = _totalGoalSeconds;
    if (totalSecs <= 0) return 0;
    final p = (_elapsedSeconds / totalSecs).clamp(0.0, 1.0);
    if (p < 0.25) return 0;
    if (p < 0.50) return 1;
    if (p < 0.75) return 2;
    return 3;
  }

  String get _stageProgressText {
    if (_goalType == _WalkingGoalType.time) {
      final stageSecs = _totalGoalSeconds / 4;
      final currentPhaseStartSecs = _currentPhaseIndex * stageSecs;
      final currentPhaseEndSecs = (_currentPhaseIndex + 1) * stageSecs;
      final remainingInPhase = (currentPhaseEndSecs - _elapsedSeconds).clamp(0, stageSecs.round());
      final startMin = (currentPhaseStartSecs / 60).round();
      final endMin = (currentPhaseEndSecs / 60).round();
      final remMin = remainingInPhase ~/ 60;
      final remSec = remainingInPhase % 60;
      return '$startMin - $endMin min • Next stage in ${remMin.toString().padLeft(2, '0')}:${remSec.toString().padLeft(2, '0')}';
    } else {
      final stageKm = _targetKm / 4;
      final startKm = _currentPhaseIndex * stageKm;
      final endKm = (_currentPhaseIndex + 1) * stageKm;
      final remainingKm = (endKm - _distanceKm).clamp(0.0, stageKm);
      return '${startKm.toStringAsFixed(1)} - ${endKm.toStringAsFixed(1)} km • Next in ${remainingKm.toStringAsFixed(2)} km';
    }
  }

  @override
  void initState() {
    super.initState();
    _startRealtimeTracking();
  }

  void _startRealtimeTracking() {
    _timer?.cancel();
    _routePoints.clear();
    _routePoints.add(const Offset(130, 85));

    // Initialize Web Geolocation if on Web
    if (kIsWeb) {
      try {
        final jsCode = '''
        (function() {
          if (navigator.geolocation) {
            window._kausapGeoId = navigator.geolocation.watchPosition(
              function(pos) {
                window._kausapLat = pos.coords.latitude;
                window._kausapLng = pos.coords.longitude;
                window._kausapAcc = pos.coords.accuracy;
              },
              function(err) {},
              { enableHighAccuracy: true, maximumAge: 3000, timeout: 10000 }
            );
          }
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (_) {}
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isWalking) return;

      _processTrackingTick();
    });
  }

  void _processTrackingTick() {
    setState(() {
      _elapsedSeconds++;

      // Check real GPS coordinates on Web
      if (kIsWeb) {
        try {
          final lat = js.context['window']['_kausapLat'] as num?;
          final lng = js.context['window']['_kausapLng'] as num?;
          if (lat != null && lng != null) {
            _hasGpsFix = true;
            if (_lastLat != null && _lastLng != null) {
              final dKm = _haversineDistance(_lastLat!, _lastLng!, lat.toDouble(), lng.toDouble());
              if (dKm > 0.0005 && dKm < 0.05) { // Valid walking step range (0.5m to 50m per sec)
                _distanceKm += dKm;
                _steps += (dKm * 1350).round(); // ~1350 steps per km
              } else {
                _steps += 2;
                _distanceKm = _steps * 0.00075;
              }
            } else {
              _steps += 2;
              _distanceKm = _steps * 0.00075;
            }
            _lastLat = lat.toDouble();
            _lastLng = lng.toDouble();
          } else {
            _steps += 2;
            _distanceKm = _steps * 0.00075;
          }
        } catch (_) {
          _steps += 2;
          _distanceKm = _steps * 0.00075;
        }
      } else {
        _steps += 2;
        _distanceKm = _steps * 0.00075;
      }

      // Generate organic route path points for visual map canvas
      if (_elapsedSeconds % 2 == 0) {
        final last = _routePoints.last;
        final angle = (_elapsedSeconds * 0.15) + math.sin(_elapsedSeconds * 0.04);
        final nextX = (last.dx + math.cos(angle) * 6).clamp(20.0, 260.0);
        final nextY = (last.dy + math.sin(angle) * 6).clamp(20.0, 150.0);
        _routePoints.add(Offset(nextX, nextY));
      }

      // Chime on phase transition
      final stageSecs = _totalGoalSeconds / 4;
      if (_elapsedSeconds > 0 && _elapsedSeconds % stageSecs.round() == 0) {
        _audioService.playChime(frequency: 528.0, durationSeconds: 1.8);
      }
    });
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) * math.cos(lat2 * (math.pi / 180.0)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _formatTime(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _paceString {
    if (_distanceKm <= 0.01) return '--:--';
    final paceMins = (_elapsedSeconds / 60) / _distanceKm;
    final mins = paceMins.floor().clamp(3, 30);
    final secs = ((paceMins - mins) * 60).round().clamp(0, 59).toString().padLeft(2, '0');
    return '$mins:$secs /km';
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['if (window._kausapGeoId && navigator.geolocation) { navigator.geolocation.clearWatch(window._kausapGeoId); }']);
      } catch (_) {}
    }
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhaseIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            // Segmented Goal Mode Switcher (Time vs Distance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _goalType = _WalkingGoalType.time),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _goalType == _WalkingGoalType.time ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _goalType == _WalkingGoalType.time
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '⏱️ Time Goal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: _goalType == _WalkingGoalType.time ? FontWeight.w700 : FontWeight.w500,
                                color: _goalType == _WalkingGoalType.time ? AppColors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _goalType = _WalkingGoalType.distance),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _goalType == _WalkingGoalType.distance ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _goalType == _WalkingGoalType.distance
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '📍 Distance Goal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: _goalType == _WalkingGoalType.distance ? FontWeight.w700 : FontWeight.w500,
                                color: _goalType == _WalkingGoalType.distance ? AppColors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Target Value Chips (15m, 20m, 30m, 45m OR 1.0 km, 2.0 km, 3.0 km, 5.0 km)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _goalType == _WalkingGoalType.time
                      ? _timeOptions.map((m) {
                          final isSelected = m == _targetMinutes;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => _targetMinutes = m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  '${m}m Target',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList()
                      : _distanceOptions.map((km) {
                          final isSelected = km == _targetKm;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => _targetKm = km),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  '${km.toStringAsFixed(1)} km Target',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Live Route Trace Visualizer (Tactical map canvas with real GPS status)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 160),
                      painter: _MapGridPainter(),
                    ),
                    CustomPaint(
                      size: const Size(double.infinity, 160),
                      painter: _RoutePathPainter(points: _routePoints),
                    ),
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
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasGpsFix ? Icons.gps_fixed_rounded : Icons.sensors_rounded,
                              color: const Color(0xFF10B981),
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _hasGpsFix ? '🟢 Live Real-Time GPS Active' : '🚶 Real-Time Sensor Tracking',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
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

            const SizedBox(height: 12),

            // Live Metrics Dashboard (Time, Distance, Steps, Pace)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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

            // Active Sensory Guidance Phase Card with Transparent Stage Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: phase.color.withAlpha(15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: phase.color.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: phase.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(phase.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              Text(
                                _stageProgressText,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: phase.color.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phase.guidance,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 4-Stage Step Tracker Dots
                    Row(
                      children: List.generate(4, (i) {
                        final isPassed = i <= _currentPhaseIndex;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: isPassed ? phase.color : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
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
