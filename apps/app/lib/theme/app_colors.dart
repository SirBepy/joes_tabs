import 'package:flutter/material.dart';

/// Brand palette for the ukulele-tabs.com client: their logo's sky blue as
/// the header band, a deeper blue for text and actions, its hibiscus yellow
/// for highlights, on pale blue surfaces with white cards.
///
/// The constant names are the original warm palette's (orange, peach, ...) so
/// every screen picks the new tones up unchanged; read them as roles, not hues.
abstract final class AppColors {
  /// Brand sky blue: the header band, large decorative fills (diagram dots,
  /// mascot). White text on it is only 2.85:1, so text on it uses [textDark]
  /// and small text or buttons use [rust] instead.
  static const Color orange = Color(0xFF29A3DC);

  /// Deep blue for text, links, icons and filled buttons on light surfaces:
  /// 5.2:1 on [cream], and white on it is 5.4:1.
  static const Color rust = Color(0xFF176FA0);

  /// The logo's hibiscus yellow: the active tab indicator. Navy on it, never
  /// white.
  static const Color hibiscus = Color(0xFFFFCF3A);

  /// Pale hibiscus yellow for chips, the source credit and placeholders.
  static const Color peach = Color(0xFFFFF1B8);

  /// Near-white blue app background.
  static const Color cream = Color(0xFFF3FAFE);

  /// Soft blue fill for small tiles that sit on white cards (row icons).
  static const Color cardPeach = Color(0xFFE2F2FB);

  /// Light blue hairline around white cards and between rows.
  static const Color hairline = Color(0xFFDCEBF4);

  static const Color textDark = Color(0xFF12324A);
  static const Color textMuted = Color(0xFF5F7C8F);
  static const Color white = Color(0xFFFFFFFF);

  // Dark theme palette: keeps the sky-blue accent on deep navy surfaces.

  /// Deep navy app background (dark counterpart to [cream]).
  static const Color darkBackground = Color(0xFF0E1C27);

  /// Slightly lifted navy surface for panels/sheets (counterpart to [peach]).
  static const Color darkSurface = Color(0xFF162A3A);

  /// Navy card fill (counterpart to the light theme's white cards).
  static const Color darkCard = Color(0xFF1E3649);

  /// Off-white body text for dark surfaces (counterpart to [textDark]); keeps
  /// chord-sheet text readable.
  static const Color darkText = Color(0xFFE9F4FB);

  /// Muted blue-grey for secondary text on dark surfaces.
  static const Color darkTextMuted = Color(0xFF9AB4C6);
}
