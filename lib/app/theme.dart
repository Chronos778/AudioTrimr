import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── GRAYSCALE + BLUE ACCENT COLOR SYSTEM ──────────────────────────────────
  // Clean, minimal palette. One accent color (blue) for all interactive highlights.
  static const Color bgPrimary = Color(0xFFFFFFFF);    // Pure white background
  static const Color bgSurface = Color(0xFFF5F5F5);    // Subtle gray for card/panel backgrounds
  static const Color bgElevated = Color(0xFFECECEC);   // Darker gray for elevation
  static const Color bgPanel = Color(0xFFF5F5F5);      // Panel background same as surface
  static const Color borderColor = Color(0xFFD4D4D4);  // Light gray borders
  static const Color borderStrong = Color(0xFFB8B8B8); // Darker gray for stronger borders
  static const Color accentBlue = Color(0xFF0066FF);   // The ONE accent color - blue
  static const Color accentPrimary = Color(0xFF0066FF); // Alias for semantic clarity
  static const Color accentRed = Color(0xFFFF3333);    // Error/destructive red
  static const Color textPrimary = Color(0xFF1A1A1A);  // Almost black for text
  static const Color textMuted = Color(0xFF666666);    // Mid gray for secondary text
  static const Color waveformBase = Color(0xFFE8E8E8); // Light gray waveform base
  static const Color waveformActive = Color(0xFF0066FF); // Blue waveform when active
  static const Color focusRing = Color(0xFF0066FF);    // Blue focus ring
  static const Color successTint = Color(0xFF00CC44);  // Green for success states
  static const Color errorTint = Color(0xFFFFEEEE);    // Light pink for error backgrounds

  // ─── SHAPE / MOTION TOKENS ───────────────────────────────────
  // Clean minimal aesthetic: small rounded corners for emphasis
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;

  // Motion system - fixed for smooth, performant animations
  // All animations use transform + opacity only. No layout shifts.
  static const Duration instantDuration = Duration(milliseconds: 0);
  static const Duration microDuration = Duration(milliseconds: 100);
  static const Duration standardDuration = Duration(milliseconds: 200);
  static const Duration expressiveDuration = Duration(milliseconds: 400);

  static const Curve easeOutSmooth = Curves.easeOut;
  static const Curve easeInOutSmooth = Curves.easeInOut;
  static Curve get springCurve => const Cubic(0.34, 1.56, 0.64, 1);

  static BorderRadius get panelRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get pillRadius => BorderRadius.circular(radiusXl);

  static BoxDecoration panelDecoration({
    Color? tint,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: tint ?? bgSurface,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: borderColor,
        width: 1.0,
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
          : const [],
    );
  }

  static BoxDecoration ambientBackdropDecoration() {
    return const BoxDecoration(
      color: bgPrimary,
      // Clean white background. No gradient noise.
    );
  }

  // ─── TEXT STYLES ─────────────────────────────────────────────
  // Light theme typography. Manrope for primary, Space Mono for labels/data only.
  static TextStyle monoDisplay = GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle monoLabel = GoogleFonts.spaceMono(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 1.5,
  );

  static TextStyle monoValue = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.0,
  );

  static TextStyle monoTimestamp = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: accentBlue,
    letterSpacing: 0.0,
  );

  static TextStyle bodyText = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.5,
  );

  static TextStyle buttonText = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: bgPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle titleText = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  // ─── THEME DATA ──────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: const ColorScheme.light(
          surface: bgSurface,
          primary: accentBlue,
          secondary: accentBlue,
          error: accentRed,
          tertiary: accentBlue,
          onSurface: textPrimary,
          onPrimary: bgPrimary,
          onSecondary: bgPrimary,
          onError: bgPrimary,
        ),
        fontFamily: GoogleFonts.manrope().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: bgPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.1,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        dividerColor: borderColor,
        cardColor: bgSurface,
        useMaterial3: true,
        textTheme: TextTheme(
          headlineLarge: monoDisplay,
          titleLarge: titleText,
          titleMedium: bodyText.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: bodyText,
          bodyMedium: bodyText,
          bodySmall: bodySmall,
          labelLarge: buttonText,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: bgPrimary,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
            elevation: 0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgPrimary,
            foregroundColor: textPrimary,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
            side: const BorderSide(color: borderColor, width: 1.0),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
            side: const BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentBlue,
            textStyle: buttonText.copyWith(color: accentBlue),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bgPrimary,
          disabledColor: bgSurface,
          selectedColor: accentBlue,
          secondarySelectedColor: accentBlue,
          labelStyle: bodySmall.copyWith(color: textPrimary),
          secondaryLabelStyle: bodySmall.copyWith(color: bgPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: borderColor),
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: bodySmall.copyWith(color: textMuted),
          hintStyle: bodySmall.copyWith(color: textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: borderColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: borderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: focusRing, width: 2.0),
          ),
        ),
      );
}
