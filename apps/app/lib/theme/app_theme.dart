import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// The app's [ThemeData]. Wireframe fidelity only: a warm peach/cream surface
/// with an orange accent and a rounded, friendly heading style. Widgets must
/// reference this theme rather than hardcoding colors.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      secondary: AppColors.rust,
      surface: AppColors.cream,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: _textTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: AppColors.cardPeach,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  /// The dark counterpart to [light]. Keeps the same orange accent and the
  /// rounded bubble headings + pill buttons, but on deep warm charcoal-brown
  /// surfaces with light, readable text. Wireframe-level only.
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      secondary: AppColors.rust,
      surface: AppColors.darkSurface,
      brightness: Brightness.dark,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: _textTheme(base.textTheme, bodyColor: AppColors.darkText),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  /// Headings use the bundled [_brandFont] (Fredoka): a chunky rounded "bubble"
  /// face matching the mockups, at a heavy 600-700 weight. Body / chord-sheet
  /// text deliberately stays the default readable sans. Display, headline, and
  /// title styles all render orange (the brand accent) and are shared across
  /// light and dark; only the body text color differs (defaults to the light
  /// theme's [AppColors.textDark]).
  ///
  /// NOTE(design): the exact brand display font is still TBD with Joe; Fredoka
  /// is the stand-in (see pubspec.yaml).
  static const String _brandFont = 'Fredoka';

  static TextTheme _textTheme(TextTheme base, {Color? bodyColor}) {
    final body = bodyColor ?? AppColors.textDark;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w700,
        color: AppColors.orange,
        letterSpacing: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w700,
        color: AppColors.orange,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
        color: AppColors.orange,
      ),
      // Section headers ("SAVED TABS", "TRENDING") render orange in the mockups,
      // not near-black.
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
        color: AppColors.orange,
        letterSpacing: 0.5,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: body),
    );
  }
}
