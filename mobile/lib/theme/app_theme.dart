import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kausap AI Design System
/// Colors, text styles, and shared widget helpers extracted from Figma.
class AppColors {
  // Primary brand — Figma: #0077B6
  static const Color primary = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF005F92);

  // Accent colors from Figma
  static const Color accentGreen = Color(0xFF519C6B);   // Start Activity button
  static const Color accentOrange = Color(0xFFFE8235);  // Book a Session button
  static const Color sessionCard = Color(0xFF00B4D8);   // Upcoming Session card bg
  static const Color bookSessionCard = Color(0xFFFDECDF); // Book Session card bg
  static const Color bookSessionText = Color(0xFF573926); // Brown text

  // Backgrounds
  static const Color background = Color(0xFFFBF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text — Figma: #3D405B
  static const Color textPrimary = Color(0xFF3D405B);
  static const Color textSecondary = Color(0xFF717680);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Input
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color inputBorderFocused = Color(0xFF0077B6);
  static const Color inputBorderError = Color(0xFFEF4444);
  static const Color inputBackground = Color(0xFFFFFFFF);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFCA5A5);

  // Divider
  static const Color divider = Color(0xFFE5E7EB);

  // Link / accent
  static const Color link = Color(0xFF0077B6);

  // Navbar bar background tint
  static const Color streakTrack = Color(0xFFECEDF5);
  static const Color checkinIcon = Color(0xFFFEE9E7);   // heart icon bg
  static const Color chatbotIcon = Color(0xFFE4F9FF);   // robot icon bg
  static const Color activityIcon = Color(0xFFE7FEEE);  // barbell icon bg
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
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorderFocused, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorderError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorderError, width: 1.5),
          ),
          hintStyle: AppTextStyles.hint,
          labelStyle: AppTextStyles.label,
          errorStyle: AppTextStyles.errorText,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            textStyle: AppTextStyles.button,
          ),
        ),
      );
}
