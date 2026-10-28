import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

/// The app's [ThemeData]: pale blue surfaces with white cards, the sky-blue
/// brand band on top, deep-blue actions, and a rounded, friendly heading style.
/// Widgets must reference this theme rather than hardcoding colors.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      // Deep blue, not the brand sky blue: filled buttons carry white labels,
      // which only reach contrast on the deeper tone.
      primary: AppColors.rust,
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
      extensions: const [AppPalette.light],
      // White on the sky band is the brand look, though it measures 2.85:1.
      // 72 tall so the 46px search pill has room around it.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
      ),
      textTheme: _textTheme(base.textTheme, headingColor: AppColors.textDark),
      dividerTheme: const DividerThemeData(color: AppColors.hairline),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rust,
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

  /// The dark counterpart to [light]. Keeps the rounded bubble headings and
  /// pill buttons on deep navy surfaces; sky blue reads well on navy, so it
  /// stays the accent here.
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
      extensions: const [AppPalette.dark],
      // The browse app bar tracks the theme so dark mode darkens with the body
      // instead of keeping the bright sky band. It uses the same darkSurface
      // tone as the SectionHeader, so both top bars and the body are consistent
      // in dark mode.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
      ),
      textTheme: _textTheme(
        base.textTheme,
        bodyColor: AppColors.darkText,
        headingColor: AppColors.orange,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkCard),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rust,
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
  /// face at a heavy 600-700 weight. Body / chord-sheet text deliberately stays
  /// the default readable sans. Display, headline, and title styles render in
  /// [headingColor] (navy on light, where sky blue fails contrast; sky blue on
  /// dark); body text defaults to the light theme's [AppColors.textDark].
  ///
  /// NOTE(design): the exact brand display font is still TBD with Joe; Fredoka
  /// is the stand-in (see pubspec.yaml).
  static const String _brandFont = 'Fredoka';

  static TextTheme _textTheme(
    TextTheme base, {
    Color? bodyColor,
    required Color headingColor,
  }) {
    final body = bodyColor ?? AppColors.textDark;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w700,
        color: headingColor,
        letterSpacing: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
        color: headingColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
        color: headingColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
        color: headingColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: _brandFont,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: body),
    );
  }
}
