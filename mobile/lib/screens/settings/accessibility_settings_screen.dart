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
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.accessibility_new_rounded,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
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

              // Text Size Section
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
                                  color: AppColors.textPrimary,
                                )),
                            const SizedBox(height: 4),
                            Text('This is how your text will appear across the app.',
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
                        const Text('A', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Expanded(
                          child: Semantics(
                            label: 'Text size slider, current: ${_scaleLabel(scale)}',
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
                        const Text('A', style: TextStyle(fontSize: 22, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              const SizedBox(height: 24),

              // Reset button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticService.mediumTap();
                    themeProvider.setTextScaleFactor(1.0);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset to Default'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
