import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic surface and text roles that differ between light and dark.
///
/// Widgets read these via `context.palette` instead of picking a raw
/// [AppColors] light constant, because a raw constant ignores the active
/// brightness (peach panels and dark-brown text become unreadable on the dark
/// theme). Brand orange/rust are identical in both themes and stay on
/// [AppColors].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.sheet,
    required this.card,
    required this.chip,
    required this.divider,
    required this.ink,
    required this.mutedInk,
  });

  /// Bars and bottom sheets that sit on top of the page background.
  final Color sheet;

  /// Song cards and chord-diagram tiles.
  final Color card;

  /// Filled controls and placeholders: chip fills, toggle tracks, mascot disc.
  final Color chip;

  /// Hairlines and borders between surfaces.
  final Color divider;

  /// Primary text.
  final Color ink;

  /// Secondary text and icons.
  final Color mutedInk;

  static const AppPalette light = AppPalette(
    sheet: AppColors.cream,
    card: AppColors.cardPeach,
    chip: AppColors.peach,
    divider: AppColors.peach,
    ink: AppColors.textDark,
    mutedInk: AppColors.textMuted,
  );

  static const AppPalette dark = AppPalette(
    sheet: AppColors.darkSurface,
    card: AppColors.darkCard,
    chip: AppColors.darkCard,
    divider: AppColors.darkCard,
    ink: AppColors.darkText,
    mutedInk: AppColors.darkTextMuted,
  );

  @override
  AppPalette copyWith({
    Color? sheet,
    Color? card,
    Color? chip,
    Color? divider,
    Color? ink,
    Color? mutedInk,
  }) {
    return AppPalette(
      sheet: sheet ?? this.sheet,
      card: card ?? this.card,
      chip: chip ?? this.chip,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      sheet: Color.lerp(sheet, other.sheet, t)!,
      card: Color.lerp(card, other.card, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette registered on the active theme. Falls back to the light
  /// palette for a bare `MaterialApp` in tests that skip [AppTheme].
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
