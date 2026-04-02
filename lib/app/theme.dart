import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── COLOR TOKENS ────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF090A0C);
  static const Color bgSurface = Color(0xFF111317);
  static const Color bgElevated = Color(0xFF171A1F);
  static const Color bgPanel = Color(0xFF14171C);
  static const Color borderColor = Color(0xFF2A2F36);
  static const Color borderStrong = Color(0xFF3A404A);
  static const Color accentElec = Color(0xFFD9A441);
  static const Color accentGreen = Color(0xFF79C98C);
  static const Color accentRed = Color(0xFFE46A5E);
  static const Color accentInk = Color(0xFFF2E3C1);
  static const Color textPrimary = Color(0xFFF3F5F7);
  static const Color textMuted = Color(0xFFA0A8B3);
  static const Color waveformBase = Color(0xFF3C434D);
  static const Color waveformActive = Color(0xFFD9A441);
  static const Color focusRing = Color(0xFFE7C26C);
  static const Color successTint = Color(0xFF18251D);
  static const Color errorTint = Color(0xFF2A1918);

  // ─── SHAPE / MOTION TOKENS ───────────────────────────────────
  static const double radiusSm = 14;
  static const double radiusMd = 22;
  static const double radiusLg = 30;
  static const double radiusXl = 42;

  static const Duration quickDuration = Duration(milliseconds: 180);
  static const Duration mediumDuration = Duration(milliseconds: 280);
  static const Duration slowDuration = Duration(milliseconds: 420);

  static const Curve emphasisCurve = Curves.easeOutCubic;
  static const Curve revealCurve = Curves.easeOutQuart;

  static BorderRadius get panelRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get pillRadius => BorderRadius.circular(radiusXl);

  static BoxDecoration panelDecoration({
    Color? tint,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: tint ?? (elevated ? bgElevated : bgSurface),
      borderRadius: panelRadius,
      border: Border.all(
        color: elevated ? borderStrong : borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: elevated ? 0.35 : 0.22),
          blurRadius: elevated ? 28 : 18,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static BoxDecoration ambientBackdropDecoration() {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-0.82, -0.88),
        radius: 1.35,
        colors: [
          Color(0xFF13161B),
          bgPrimary,
        ],
        stops: [0.0, 1.0],
      ),
    );
  }

  // ─── TEXT STYLES ─────────────────────────────────────────────
  static TextStyle monoDisplay = GoogleFonts.cormorantGaramond(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.35,
  );

  static TextStyle monoLabel = GoogleFonts.spaceMono(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 1.4,
  );

  static TextStyle monoValue = GoogleFonts.spaceMono(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle monoTimestamp = GoogleFonts.spaceMono(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: accentElec,
    letterSpacing: 0.5,
  );

  static TextStyle bodyText = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.45,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textMuted,
    height: 1.4,
  );

  static TextStyle buttonText = GoogleFonts.spaceMono(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: bgPrimary,
    letterSpacing: 1.3,
  );

  static TextStyle titleText = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  // ─── THEME DATA ──────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: const ColorScheme.dark(
          surface: bgSurface,
          primary: accentElec,
          secondary: accentGreen,
          error: accentRed,
          tertiary: accentInk,
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
            backgroundColor: accentElec,
            foregroundColor: bgPrimary,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgElevated,
            foregroundColor: textPrimary,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: const StadiumBorder(),
            side: const BorderSide(color: borderColor, width: 1.2),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: const StadiumBorder(),
            side: const BorderSide(color: borderColor, width: 1.2),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentElec,
            textStyle: buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: const StadiumBorder(),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bgPanel,
          disabledColor: bgPanel,
          selectedColor: accentElec.withValues(alpha: 0.16),
          secondarySelectedColor: accentElec.withValues(alpha: 0.16),
          labelStyle: bodySmall.copyWith(color: textPrimary),
          secondaryLabelStyle: bodySmall.copyWith(color: textPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const StadiumBorder(
            side: BorderSide(color: borderColor),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgPanel,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: bodySmall.copyWith(color: textMuted),
          hintStyle: bodySmall.copyWith(color: textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: focusRing, width: 1.6),
          ),
        ),
      );
}
