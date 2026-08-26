import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/ambient_audio_service.dart';
import '../../utils/haptic_service.dart';
import 'crisis_resources_sheet.dart';
import 'emergency_contacts_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  bool _isSendingAlert = false;
  DateTime? _lastAlertSentAt;

  // 4-7-8 Breathing & Grounding State
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  Timer? _countdownTimer;
  int _currentSecondsLeft = 4;
  int _currentPhaseIndex = 0; // 0: Inhale (4s), 1: Hold (7s), 2: Exhale (8s)
  bool _isBreathingActive = false;
  int _selectedGroundingTab = 0; // 0: 4-7-8 Breathing, 1: 5-4-3-2-1 Grounding
  bool _isGroundingExpanded = true; // Collapsible toggle
  bool _isSoundMuted = false; // Sound mute/on toggle

  final List<(String, int, String, Color)> _breathingPhases = [
    ('Inhale slowly through your nose...', 4, 'INHALE', Color(0xFF0284C7)),
    ('Gently hold your breath...', 7, 'HOLD', Color(0xFF7C3AED)),
    ('Exhale completely through mouth...', 8, 'EXHALE', Color(0xFF059669)),
  ];

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _playPhaseChime(int phaseIndex) {
    if (_isSoundMuted) return;
    HapticService.lightTap();
    if (kIsWeb) {
      AmbientAudioService.instance.playChime(phaseIndex);
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _startBreathingCycle() {
    setState(() {
      _isBreathingActive = true;
      _currentPhaseIndex = 0;
      _currentSecondsLeft = _breathingPhases[0].$2;
    });
    _playPhaseChime(0);
    _runCurrentPhase();
  }

  void _pauseBreathingCycle() {
    _countdownTimer?.cancel();
    _breathingController.stop();
    setState(() {
      _isBreathingActive = false;
    });
    HapticService.lightTap();
  }

  void _runCurrentPhase() {
    _countdownTimer?.cancel();
    final phase = _breathingPhases[_currentPhaseIndex];
    _currentSecondsLeft = phase.$2;
    _playPhaseChime(_currentPhaseIndex);

    if (_currentPhaseIndex == 0) {
      _breathingController.duration = Duration(seconds: phase.$2);
      _breathingController.forward(from: 0.0);
    } else if (_currentPhaseIndex == 1) {
      // Hold breath at peak
      _breathingController.stop();
    } else {
      // Exhale back to relaxed size
      _breathingController.duration = Duration(seconds: phase.$2);
      _breathingController.reverse(from: 1.0);
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentSecondsLeft > 1) {
        setState(() {
          _currentSecondsLeft--;
        });
      } else {
        timer.cancel();
        // Advance to next phase
        setState(() {
          _currentPhaseIndex = (_currentPhaseIndex + 1) % _breathingPhases.length;
        });
        _runCurrentPhase();
      }
    });
  }

  Future<void> _sendSosAlert(BuildContext context) async {
    if (_lastAlertSentAt != null && DateTime.now().difference(_lastAlertSentAt!).inSeconds < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An emergency alert was already dispatched recently. Guidance team is notified.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.crisis_alert_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Send Crisis Distress Alert?',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will immediately dispatch a high-priority distress alert to the campus guidance administration and log an emergency crisis flag.\n\nAre you in need of urgent assistance?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Send Alert', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSendingAlert = true);
    HapticService.heavyTap();

    try {
      // 1. Create an emergency chat session
      final session = await ApiClient().post('/chat/sessions');
      final sessionId = session['id'];

      // 2. Post high-priority distress message that triggers immediate crisis flag
      await ApiClient().post(
        '/chat/sessions/$sessionId/messages',
        body: {
          'content': '🚨 EMERGENCY SOS DISTRESS ALERT: Student requested immediate guidance crisis support. I feel hopeless and in need of urgent help.'
        },
      );
      _lastAlertSentAt = DateTime.now();
      if (!mounted) return;
      
      showDialog(
        context: this.context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
              SizedBox(width: 10),
              Text(
                'Alert Dispatched',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'Your emergency distress alert has been received by the guidance network with highest priority.\n\nPlease stay calm. You can also dial the 24/7 toll-free NCMH hotline at 1553 or 911 right now.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('OK', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert. Please call 1553 directly: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingAlert = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text(
          'Crisis & Emergency Support',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Color(0xFF991B1B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF991B1B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // ── Hero Encouragement Banner ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    boxShadow: const [BoxShadow(color: Color(0x08DC2626), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Color(0xFFDC2626), size: 36),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You are not alone.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Color(0xFF991B1B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Reaching out takes immense courage. Immediate support is available to guide you through this moment.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFF7F1D1D),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── 🚨 1-Tap Campus Distress Alert Button ──────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x30DC2626), blurRadius: 14, offset: Offset(0, 6))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _isSendingAlert ? null : () => _sendSosAlert(context),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isSendingAlert
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Request Guidance Alert (SOS)',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Dispatches immediate priority flag to campus guidance center',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Color(0xFFFEE2E2),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── 🌿 Interactive 4-7-8 Breathing & Grounding Widget ──────────
                _buildBreathingGroundingSection(),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'EMERGENCY RESOURCES & CONTACTS',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.7,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Crisis Hotlines Tile
                _buildActionTile(
                  context,
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFFDC2626),
                  title: '24/7 Crisis Hotlines',
                  subtitle: 'National Center for Mental Health (1553), Hopeline & 911',
                  onTap: () {
                    HapticService.lightTap();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CrisisResourcesSheet(),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Emergency Contacts Tile
                _buildActionTile(
                  context,
                  icon: Icons.contact_phone_rounded,
                  color: const Color(0xFFD97706),
                  title: 'Trusted Emergency Contacts',
                  subtitle: 'Reach out directly to your pre-saved trusted contacts',
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Return to Safety Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticService.lightTap();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF991B1B),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text(
                      'I am safe, return to Home',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingGroundingSection() {
    final phase = _breathingPhases[_currentPhaseIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collapsible Card Header ──
          InkWell(
            onTap: () {
              HapticService.lightTap();
              setState(() {
                _isGroundingExpanded = !_isGroundingExpanded;
                if (!_isGroundingExpanded && _isBreathingActive) {
                  _pauseBreathingCycle();
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.self_improvement_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Grounding Exercises',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isGroundingExpanded
                              ? '4-7-8 Breathing & 5-4-3-2-1 Sensory Grounding'
                              : 'Tap to expand breathing & grounding tools',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sound Mute Toggle Button
                  IconButton(
                    tooltip: _isSoundMuted ? 'Sound Off (Tap to Unmute)' : 'Sound On (Tap to Mute)',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isSoundMuted ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isSoundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        size: 17,
                        color: _isSoundMuted ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                      ),
                    ),
                    onPressed: () {
                      HapticService.lightTap();
                      setState(() {
                        _isSoundMuted = !_isSoundMuted;
                      });
                      if (!_isSoundMuted) {
                        _playPhaseChime(0);
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  // Expand / Collapse Chevron
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isGroundingExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Content Body ──
          if (_isGroundingExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Technique Switcher Pill
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleBtn('4-7-8 Breath', 0),
                          _buildToggleBtn('5-4-3-2-1 Grounding', 1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_selectedGroundingTab == 0) ...[
                    // 4-7-8 Breathing Guide
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _isBreathingActive ? phase.$1 : 'Slow down your heart rate and regulate your nervous system.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: _isBreathingActive ? FontWeight.w600 : FontWeight.w400,
                              color: _isBreathingActive ? phase.$4 : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),

                          // Animated Breathing Circle
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isBreathingActive ? phase.$4.withAlpha(25) : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: _isBreathingActive ? phase.$4 : const Color(0xFFCBD5E1),
                                  width: _isBreathingActive ? 3 : 1.5,
                                ),
                                boxShadow: _isBreathingActive
                                    ? [
                                        BoxShadow(
                                          color: phase.$4.withAlpha(50),
                                          blurRadius: 20,
                                          spreadRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isBreathingActive ? phase.$3 : 'BREATHE',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 1.2,
                                        color: _isBreathingActive ? phase.$4 : const Color(0xFF475569),
                                      ),
                                    ),
                                    if (_isBreathingActive) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_currentSecondsLeft s',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 24,
                                          color: phase.$4,
                                        ),
                                      ),
                                    ] else
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Icon(Icons.play_arrow_rounded, color: Color(0xFF64748B), size: 24),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Controls Row with Start/Pause + Sound Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isBreathingActive ? _pauseBreathingCycle : _startBreathingCycle,
                                icon: Icon(_isBreathingActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                                label: Text(_isBreathingActive ? 'Pause Exercise' : 'Start 4-7-8 Breathing'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  backgroundColor: _isBreathingActive ? const Color(0xFF0F172A) : const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: _isSoundMuted ? 'Sound Muted' : 'Sound On',
                                icon: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: _isSoundMuted ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _isSoundMuted ? const Color(0xFFCBD5E1) : const Color(0xFFBAE6FD)),
                                  ),
                                  child: Icon(
                                    _isSoundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    size: 18,
                                    color: _isSoundMuted ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                                  ),
                                ),
                                onPressed: () {
                                  HapticService.lightTap();
                                  setState(() {
                                    _isSoundMuted = !_isSoundMuted;
                                  });
                                  if (!_isSoundMuted) {
                                    _playPhaseChime(0);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 5-4-3-2-1 Sensory Grounding Guide
                    const Text(
                      'Ground yourself in this physical moment:',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    _buildSensoryItem('👁️ 5 Things You See', 'A pen, the wall texture, a clock, your shoes, sunlight.'),
                    _buildSensoryItem('✋ 4 Things You Feel', 'Your feet on floor, your clothes on skin, chair back, phone.'),
                    _buildSensoryItem('👂 3 Things You Hear', 'Room air, distant voices, your own gentle breath.'),
                    _buildSensoryItem('👃 2 Things You Smell', 'Coffee, laundry, fresh paper, or your shirt collar.'),
                    _buildSensoryItem('💭 1 Positive Truth', '"I am safe in this room right now. This feeling will pass."'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, int index) {
    final isSelected = _selectedGroundingTab == index;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() {
          _selectedGroundingTab = index;
          if (index != 0 && _isBreathingActive) {
            _pauseBreathingCycle();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSensoryItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF334155), height: 1.3),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  TextSpan(text: subtitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
