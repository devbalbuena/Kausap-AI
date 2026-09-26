import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentAccent = themeProvider.accentColor;
    final currentThemeMode = themeProvider.themeMode;
    final isDark = themeProvider.isDarkMode;

    final colorOptions = [
      {
        'name': 'Ocean Calm',
        'subtitle': 'Focus & Serenity',
        'color': const Color(0xFF0077B6),
        'gradient': const [Color(0xFF0077B6), Color(0xFF0284C7)],
      },
      {
        'name': 'Emerald Forest',
        'subtitle': 'Balance & Renewal',
        'color': const Color(0xFF10B981),
        'gradient': const [Color(0xFF059669), Color(0xFF10B981)],
      },
      {
        'name': 'Serenity Lavender',
        'subtitle': 'Peace & Rest',
        'color': const Color(0xFF8B5CF6),
        'gradient': const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      },
      {
        'name': 'Sunset Bloom',
        'subtitle': 'Warmth & Compassion',
        'color': const Color(0xFFF43F5E),
        'gradient': const [Color(0xFFE11D48), Color(0xFFF43F5E)],
      },
      {
        'name': 'Golden Sunrise',
        'subtitle': 'Energy & Positivity',
        'color': const Color(0xFFF59E0B),
        'gradient': const [Color(0xFFD97706), Color(0xFFF59E0B)],
      },
    ];

    return Scaffold(
      backgroundColor: KausapColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: KausapColors.cardBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: KausapColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance & Theme',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: KausapColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ── 1. Live Interactive Preview Card ───────────────────────────
              _buildLivePreviewCard(context, currentAccent, isDark),
              const SizedBox(height: 24),

              // ── 2. Theme Mode Selection ────────────────────────────────────
              _sectionLabel(context, 'THEME MODE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildThemeModeCard(
                      context: context,
                      icon: Icons.light_mode_rounded,
                      label: 'Light',
                      isSelected: currentThemeMode == ThemeMode.light,
                      accentColor: currentAccent,
                      onTap: () {
                        HapticService.mediumTap();
                        themeProvider.setThemeMode(ThemeMode.light);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildThemeModeCard(
                      context: context,
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark',
                      isSelected: currentThemeMode == ThemeMode.dark,
                      accentColor: currentAccent,
                      onTap: () {
                        HapticService.mediumTap();
                        themeProvider.setThemeMode(ThemeMode.dark);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildThemeModeCard(
                      context: context,
                      icon: Icons.smartphone_rounded,
                      label: 'System',
                      isSelected: currentThemeMode == ThemeMode.system,
                      accentColor: currentAccent,
                      onTap: () {
                        HapticService.mediumTap();
                        themeProvider.setThemeMode(ThemeMode.system);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── 3. Therapeutic Wellness Color Palettes ─────────────────────
              _sectionLabel(context, 'WELLNESS ACCENT PALETTES'),
              const SizedBox(height: 4),
              Text(
                'Personalize the primary highlight color of buttons, mood rings, and icons.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: KausapColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 12),

              ...colorOptions.map((opt) {
                final color = opt['color'] as Color;
                final name = opt['name'] as String;
                final subtitle = opt['subtitle'] as String;
                final isSelected = currentAccent.toARGB32() == color.toARGB32();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      HapticService.selectionChanged();
                      themeProvider.setAccentColor(color);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: KausapColors.cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : KausapColors.border(context),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? color.withAlpha(25) : Colors.black.withAlpha(isDark ? 0 : 8),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(70),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 14,
                                    color: KausapColors.textPrimary(context),
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: KausapColors.textMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(BuildContext context, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 10 : 8), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.palette_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Live Appearance Preview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: KausapColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inner preview widget
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KausapColors.subtleBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: KausapColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🌿 "Peace begins with a deep breath."',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: KausapColors.textPrimary(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Calm',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Primary Action Button',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = KausapColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withAlpha(isDark ? 40 : 18)
              : KausapColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : KausapColors.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? accentColor : KausapColors.textMuted(context),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? accentColor : KausapColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.7,
          color: KausapColors.textMuted(context),
        ),
      ),
    );
  }
}

