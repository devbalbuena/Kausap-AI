import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  String _scaleLabel(double value) {
    if (value <= 0.85) return 'Small (85%)';
    if (value <= 1.05) return 'Default (100%)';
    if (value <= 1.25) return 'Large (120%)';
    if (value <= 1.45) return 'Extra Large (140%)';
    return 'Maximum (160%)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Accessibility & Comfort',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final scale = themeProvider.textScaleFactor;
          final highContrast = themeProvider.highContrast;
          final reduceMotion = themeProvider.reduceMotion;
          final haptics = themeProvider.hapticsEnabled;
          final dyslexia = themeProvider.dyslexiaSpacing;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.accessibility_new_rounded, color: Color(0xFF16A34A), size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Personalize your sensory, reading, and visual comfort settings for a calming experience.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: Color(0xFF166534),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 1. Visual & Reading Comfort ────────────────────────────
                  _sectionLabel('VISUAL & READING COMFORT'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Preview Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preview Text Size',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: dyslexia ? 1.0 : 0.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This is how your daily affirmations, journal reflections, and AI conversations will look.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5 * scale,
                                  color: const Color(0xFF475569),
                                  height: dyslexia ? 1.8 : 1.4,
                                  letterSpacing: dyslexia ? 0.6 : 0.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Slider Row
                        Row(
                          children: [
                            const Text('A', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: scale,
                                min: 0.8,
                                max: 1.6,
                                divisions: 8,
                                activeColor: AppColors.primary,
                                inactiveColor: const Color(0xFFE2E8F0),
                                onChanged: (val) {
                                  HapticService.selectionChanged();
                                  themeProvider.setTextScaleFactor(val);
                                },
                              ),
                            ),
                            const Text('A', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scaleLabel(scale),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                HapticService.mediumTap();
                                themeProvider.setTextScaleFactor(1.0);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Display toggles card
                  _card([
                    _buildToggleRow(
                      icon: Icons.contrast_rounded,
                      iconColor: const Color(0xFF0F172A),
                      label: 'High Contrast Mode',
                      subtitle: 'Darkens text and outlines for low-vision clarity',
                      value: highContrast,
                      onChanged: (v) {
                        HapticService.mediumTap();
                        themeProvider.setHighContrast(v);
                      },
                    ),
                    _divider(),
                    _buildToggleRow(
                      icon: Icons.format_line_spacing_rounded,
                      iconColor: const Color(0xFF0284C7),
                      label: 'Enhanced Reading Spacing',
                      subtitle: 'Increases line and letter spacing (Dyslexia support)',
                      value: dyslexia,
                      onChanged: (v) {
                        HapticService.mediumTap();
                        themeProvider.setDyslexiaSpacing(v);
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── 2. Sensory & Calming Motion ───────────────────────────
                  _sectionLabel('SENSORY & CALMING MOTION'),
                  const SizedBox(height: 8),
                  _card([
                    _buildToggleRow(
                      icon: Icons.animation_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      label: 'Reduce Motion',
                      subtitle: 'Calms page transitions and stops intensive animations',
                      value: reduceMotion,
                      onChanged: (v) {
                        HapticService.mediumTap();
                        themeProvider.setReduceMotion(v);
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── 3. Tactile & Haptics ──────────────────────────────────
                  _sectionLabel('TACTILE & HAPTICS'),
                  const SizedBox(height: 8),
                  _card([
                    _buildToggleRow(
                      icon: Icons.vibration_rounded,
                      iconColor: const Color(0xFFEA580C),
                      label: 'Haptic Feedback',
                      subtitle: 'Vibrations on button taps and breathing exercise cues',
                      value: haptics,
                      onChanged: (v) {
                        HapticService.mediumTap();
                        themeProvider.setHapticsEnabled(v);
                      },
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.7,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value == true,
            activeTrackColor: AppColors.primaryLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 64, color: Color(0x12000000));
  }
}
