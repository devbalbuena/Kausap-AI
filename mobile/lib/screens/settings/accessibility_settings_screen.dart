import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  String _scaleLabel(double value) {
    if (value <= 0.85) return 'Small';
    if (value <= 1.05) return 'Default';
    if (value <= 1.25) return 'Large';
    if (value <= 1.45) return 'Extra Large';
    return 'Huge';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          color: Theme.of(context).colorScheme.onSurface,
          tooltip: 'Go back',
        ),
        title: Text(
          'Accessibility',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final scale = themeProvider.textScaleFactor;
          final highContrast = themeProvider.highContrast;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.accessibility_new_rounded,
                        color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Adjust these settings to make Kausap AI easier to use for you.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Text Size ─────────────────────────────────────────────────
              Text('Text Size',
                  style: AppTextStyles.heading2.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview
                    Semantics(
                      label: 'Text size preview',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preview Text',
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                )),
                            const SizedBox(height: 4),
                            Text(
                                'This is how your text will appear across the app.',
                                style: TextStyle(
                                  fontSize: 13 * scale,
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('A',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Expanded(
                          child: Semantics(
                            label:
                                'Text size slider, current: ${_scaleLabel(scale)}',
                            slider: true,
                            child: Slider(
                              value: scale,
                              min: 0.8,
                              max: 1.6,
                              divisions: 8,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.primary.withAlpha(30),
                              onChanged: (value) {
                                HapticService.selectionChanged();
                                themeProvider.setTextScaleFactor(value);
                              },
                            ),
                          ),
                        ),
                        const Text('A',
                            style: TextStyle(
                                fontSize: 22,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _scaleLabel(scale),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    HapticService.mediumTap();
                    themeProvider.setTextScaleFactor(1.0);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset to Default'),
                ),
              ),

              const SizedBox(height: 24),

              // ── High Contrast Mode ────────────────────────────────────────
              Text('Display',
                  style: AppTextStyles.heading2.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000).withAlpha(12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF000000).withAlpha(30)),
                        ),
                        child: const Icon(Icons.contrast_rounded,
                            color: Color(0xFF000000), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('High Contrast Mode',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                )),
                            SizedBox(height: 3),
                            Text(
                              'Increases contrast of text and borders for low vision users.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label:
                            'High Contrast Mode toggle, currently ${highContrast ? "on" : "off"}',
                        child: Switch(
                          value: highContrast,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            HapticService.mediumTap();
                            themeProvider.setHighContrast(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // High contrast preview
              if (highContrast) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF000000), width: 2),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF003F6B), size: 22),
                      SizedBox(width: 10),
                      Text(
                        'High Contrast is ON',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
