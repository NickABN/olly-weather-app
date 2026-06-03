import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _primarySeed = Color(0xFF1B3022);
  static const _secondary = Color(0xFF8A9A5B);
  static const _tertiary = Color(0xFF5D4037);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final cs = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: _secondary,
      onSecondary: Colors.white,
      tertiary: _tertiary,
      onTertiary: Colors.white,
    );

    final baseText = base.textTheme;
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.ebGaramond(textStyle: baseText.displayLarge),
      displayMedium: GoogleFonts.ebGaramond(textStyle: baseText.displayMedium),
      displaySmall: GoogleFonts.ebGaramond(textStyle: baseText.displaySmall),
      headlineLarge: GoogleFonts.ebGaramond(textStyle: baseText.headlineLarge),
      headlineMedium: GoogleFonts.ebGaramond(textStyle: baseText.headlineMedium),
      headlineSmall: GoogleFonts.ebGaramond(textStyle: baseText.headlineSmall),
      titleLarge: GoogleFonts.plusJakartaSans(textStyle: baseText.titleLarge),
      titleMedium: GoogleFonts.plusJakartaSans(textStyle: baseText.titleMedium),
      titleSmall: GoogleFonts.plusJakartaSans(textStyle: baseText.titleSmall),
      bodyLarge: GoogleFonts.plusJakartaSans(textStyle: baseText.bodyLarge),
      bodyMedium: GoogleFonts.plusJakartaSans(textStyle: baseText.bodyMedium),
      bodySmall: GoogleFonts.plusJakartaSans(textStyle: baseText.bodySmall),
      labelLarge: GoogleFonts.plusJakartaSans(textStyle: baseText.labelLarge),
      labelMedium: GoogleFonts.plusJakartaSans(textStyle: baseText.labelMedium),
      labelSmall: GoogleFonts.plusJakartaSans(textStyle: baseText.labelSmall),
    );

    return base.copyWith(
      colorScheme: cs,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.secondary, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      ),
    );
  }
}
