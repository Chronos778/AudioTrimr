import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── COLOR TOKENS ────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF0A0A0C);
  static const Color bgSurface = Color(0xFF111116);
  static const Color bgElevated = Color(0xFF1A1A22);
  static const Color borderColor = Color(0xFF2A2A35);
  static const Color accentElec = Color(0xFF00E5FF);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentRed = Color(0xFFFF3B5C);
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textMuted = Color(0xFF6B6B80);
  static const Color waveformBase = Color(0xFF2A2A40);
  static const Color waveformActive = Color(0xFF00E5FF);

  // ─── TEXT STYLES ─────────────────────────────────────────────
  static TextStyle monoDisplay = GoogleFonts.ibmPlexMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle monoLabel = GoogleFonts.ibmPlexMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 1.5,
  );

  static TextStyle monoValue = GoogleFonts.ibmPlexMono(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle monoTimestamp = GoogleFonts.ibmPlexMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: accentElec,
    letterSpacing: 0.5,
  );

  static TextStyle bodyText = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static TextStyle buttonText = GoogleFonts.ibmPlexMono(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: bgPrimary,
    letterSpacing: 1.2,
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
          onSurface: textPrimary,
          onPrimary: bgPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bgPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.ibmPlexMono(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: accentElec,
            letterSpacing: 2.0,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        dividerColor: borderColor,
        cardColor: bgSurface,
        useMaterial3: true,
      );
}
