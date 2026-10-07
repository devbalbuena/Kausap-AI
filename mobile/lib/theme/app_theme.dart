import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kausap AI Design System
/// Colors, text styles, and shared widget helpers extracted from Figma.
class AppColors {
  // Primary brand — Figma: #0077B6
  static const Color primary = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF005F92);

  // Executive Charcoal (Flat 2.0 dark CTAs, matching reference design)
  static const Color charcoal = Color(0xFF0F172A);
  static const Color charcoalSurface = Color(0xFF1E293B);

  // Accent colors — refined, calm, desaturated
  static const Color accentGreen = Color(0xFF16A34A);   // Start Activity button
  static const Color accentOrange = Color(0xFFEA580C);  // Warm calm terracotta
  static const Color sessionCard = Color(0xFFF0F9FF);   // Upcoming Session card bg (soft sky wash)
  static const Color bookSessionCard = Color(0xFFFFF7ED); // Book Session card bg (soft peach wash)
  static const Color bookSessionText = Color(0xFFC2410C); // Terracotta text

  // Backgrounds — Flat 2.0 Slate-50 airy canvas
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text — High legibility Slate-900 & Slate-500
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Input — Flat 1px border
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputBorderFocused = Color(0xFF0077B6);
  static const Color inputBorderError = Color(0xFFEF4444);
  static const Color inputBackground = Color(0xFFFFFFFF);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFCA5A5);

  // Divider
  static const Color divider = Color(0xFFE2E8F0);

  // Link / accent
  static const Color link = Color(0xFF0284C7);

  // Navbar bar background tint & calm icons
  static const Color streakTrack = Color(0xFFF1F5F9);
  static const Color checkinIcon = Color(0xFFFEF2F2);   // soft rose icon bg
  static const Color chatbotIcon = Color(0xFFF0F9FF);   // soft sky icon bg
  static const Color streakCardBg = Color(0xFFFFF7ED);  // Soft peach wash
  static const Color streakCardBorder = Color(0xFFFFEDD5);
  static const Color streakCardText = Color(0xFFC2410C);
  static const Color streakCardTitle = Color(0xFF0F172A); // Dark slate title
  static const Color streakCardBody = Color(0xFF475569);  // Slate-600 body text

  // Activity tag colors — calm desaturated pastel washes
  static const Color tagGreenBg = Color(0xFFF0FDF4);
  static const Color tagGreenBorder = Color(0xFFDCFCE7);
  static const Color tagGreenText = Color(0xFF15803D);
  static const Color tagOrangeBg = Color(0xFFFFF7ED);
  static const Color tagOrangeText = Color(0xFFC2410C);
  static const Color tagBlueBg = Color(0xFFF0F9FF);
  static const Color tagBlueText = Color(0xFF0369A1);

  // Category pill (unselected)
  static const Color categoryChipBg = Color(0xFFF1F5F9);

  static const Color activityIcon = Color(0xFFF0FDF4);  // soft sage icon bg
}

/// Context-aware color utility — reads from the active MaterialApp theme.
/// Use this in widgets instead of hardcoded hex values so dark mode and
/// accent colour palette changes propagate automatically.
class KausapColors {
  /// Whether the app is currently in Dark Mode
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Whether the user has chosen a custom accent color (not the default Ocean Calm blue)
  static bool isCustomAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary.toARGB32() != const Color(0xFF0077B6).toARGB32();

  /// Card / sheet background (white in light, slate-dark in dark)
  static Color cardBg(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Scaffold / page background
  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Primary text colour (dark in light mode, near-white in dark mode)
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Secondary text colour (slate-600 in light mode, slate-300 in dark mode)
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

  /// Secondary / muted text colour (slate-500 in light mode, slate-400 in dark mode)
  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Very subtle muted text (hints, captions)
  static Color textHint(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  /// Border / divider colour (light slate in light, dark slate in dark)
  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  /// Subtle container / nested chip background
  static Color subtleBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  /// The user's chosen accent colour (Ocean Calm, Emerald Forest, etc.)
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Very subtle accent tint — for icon container backgrounds
  static Color accentSubtle(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withAlpha(isDark(context) ? 35 : 20);

  /// Slightly stronger accent tint — for selected/active item backgrounds
  static Color accentLight(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withAlpha(isDark(context) ? 50 : 30);

  /// Flat 2.0 neutral card shadow — soft and natural, avoiding neon colored glows
  static Color accentShadow(BuildContext context) =>
      isDark(context) ? Colors.black.withAlpha(25) : Colors.black.withAlpha(8);

  /// Input / form field fill colour
  static Color inputFill(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

  /// Primary CTA button background (brand accent blue / active theme)
  static Color primaryCta(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Text on primary CTA button
  static Color onPrimaryCta(BuildContext context) => Colors.white;

  // ── Flat 2.0 Desaturated Pastel Washes (For Bento Cards & Badges) ─────────

  /// Soft Sage wash (Activities, Mindfulness, Health)
  static Color pastelSageBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF142E1F) : const Color(0xFFF0FDF4);
  static Color pastelSageBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF166534) : const Color(0xFFDCFCE7);
  static Color pastelSageFg(BuildContext context) =>
      isDark(context) ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

  /// Soft Peach/Sand wash (Streaks, Energy, Motivation)
  static Color pastelPeachBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF2E1C14) : const Color(0xFFFFF7ED);
  static Color pastelPeachBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF9A3412) : const Color(0xFFFFEDD5);
  static Color pastelPeachFg(BuildContext context) =>
      isDark(context) ? const Color(0xFFFB923C) : const Color(0xFFC2410C);

  /// Soft Lilac wash (Journaling, Reflection, Insights)
  static Color pastelLilacBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF251A38) : const Color(0xFFFAF5FF);
  static Color pastelLilacBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF6B21A8) : const Color(0xFFF3E8FF);
  static Color pastelLilacFg(BuildContext context) =>
      isDark(context) ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);

  /// Soft Sky/Slate wash (AI Chat, Focus, Calm)
  static Color pastelSkyBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF132738) : const Color(0xFFF0F9FF);
  static Color pastelSkyBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF075985) : const Color(0xFFE0F2FE);
  static Color pastelSkyFg(BuildContext context) =>
      isDark(context) ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);

  /// Returns a rich 2-color gradient for the mascot / hero elements based on the active theme accent
  static List<Color> mascotGradient(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryValue = primary.toARGB32();

    // Ocean Calm
    if (primaryValue == const Color(0xFF0077B6).toARGB32()) {
      return const [Color(0xFF0077B6), Color(0xFF00B4D8)];
    }
    // Emerald Forest
    if (primaryValue == const Color(0xFF059669).toARGB32()) {
      return const [Color(0xFF059669), Color(0xFF34D399)];
    }
    // Lavender Mist
    if (primaryValue == const Color(0xFF7C3AED).toARGB32()) {
      return const [Color(0xFF7C3AED), Color(0xFFA78BFA)];
    }
    // Sunset Glow
    if (primaryValue == const Color(0xFFEA580C).toARGB32()) {
      return const [Color(0xFFEA580C), Color(0xFFFB923C)];
    }
    // Golden Amber
    if (primaryValue == const Color(0xFFD97706).toARGB32()) {
      return const [Color(0xFFD97706), Color(0xFFFBBF24)];
    }
    return [primary, primary.withAlpha(200)];
  }

  /// Track background for progress bars and chart empty slots
  static Color trackBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFECEDF5);

  /// Semantic success green (always green — used for streaks, completed quests)
  static const Color success = Color(0xFF16A34A);
  static Color successSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF16A34A).withAlpha(45) : const Color(0xFFDCFCE7);

  /// Semantic warning amber (always amber — used for status badges)
  static const Color warning = Color(0xFFD97706);
  static Color warningSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFFD97706).withAlpha(45) : const Color(0xFFFEF3C7);

  /// Semantic danger red (always red — SOS banner, error states)
  static const Color danger = Color(0xFFEF4444);
  static Color dangerSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFFEF4444).withAlpha(45) : const Color(0xFFFEE2E2);

  // ── Semantic mood colours — kept as-is, they are meaningful not decorative ─
  static const Color moodRough = Color(0xFFEF4444);
  static const Color moodLow   = Color(0xFFF97316);
  static const Color moodOkay  = Color(0xFFF59E0B);
  static const Color moodGood  = Color(0xFF10B981);
  static const Color moodGreat = Color(0xFF06B6D4);
}

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle subheading = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle hint = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.link,
    decoration: TextDecoration.none,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle errorText = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static TextStyle brandName = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.3,
  );
}

class AppTheme {
  /// Default static brand theme used for pre-auth flows (Sign In, Register, etc.)
  static ThemeData get defaultTheme => getTheme(AppColors.primary);

  static ThemeData getTheme(Color accentColor) => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: accentColor,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: accentColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorderError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorderError, width: 1.5),
          ),
          hintStyle: AppTextStyles.hint,
          labelStyle: AppTextStyles.label,
          errorStyle: AppTextStyles.errorText,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            disabledForegroundColor: const Color(0xFF94A3B8),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: AppTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            backgroundColor: Colors.white,
            side: BorderSide(color: accentColor.withAlpha(120), width: 1.2),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: AppTextStyles.button.copyWith(color: accentColor),
          ),
        ),
      );

  static ThemeData getDarkTheme(Color accentColor) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          // Ensure we override specific styles for dark mode if needed
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          surface: const Color(0xFF1E293B),
          onSurface: const Color(0xFFF8FAFC),
          error: AppColors.error,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorderError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorderError, width: 1.5),
          ),
          hintStyle: AppTextStyles.hint.copyWith(color: const Color(0xFF94A3B8)),
          labelStyle: AppTextStyles.label.copyWith(color: const Color(0xFFF8FAFC)),
          errorStyle: AppTextStyles.errorText,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF334155),
            disabledForegroundColor: const Color(0xFF64748B),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: AppTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF8FAFC),
            backgroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: Color(0xFF334155), width: 1.2),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: AppTextStyles.button.copyWith(color: const Color(0xFFF8FAFC)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: accentColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
          elevation: 0,
        ),
        dividerColor: const Color(0xFF334155),
      );

  /// High contrast theme — maximum legibility for low vision users.
  /// Uses pitch-black text on white, no subtle grays, 2px borders.
  static ThemeData getHighContrastTheme(Color accentColor) => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF000000)),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF000000)),
          bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF000000)),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF003F6B),       // deeper blue for contrast
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
          error: Color(0xFFCC0000),
          onError: Color(0xFFFFFFFF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF000000), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF000000), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF003F6B), width: 3),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCC0000), width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCC0000), width: 3),
          ),
          hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 14),
          labelStyle: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700, fontSize: 14),
          errorStyle: const TextStyle(color: Color(0xFFCC0000), fontWeight: FontWeight.w700, fontSize: 13),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003F6B),
            foregroundColor: const Color(0xFFFFFFFF),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF000000), width: 2),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF000000), width: 1.5),
          ),
        ),
        dividerColor: const Color(0xFF000000),
        iconTheme: const IconThemeData(color: Color(0xFF000000)),
      );
}

