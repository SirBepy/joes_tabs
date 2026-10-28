import 'package:flutter/material.dart';

/// Brand palette for the ukulele-tabs.com client: their logo's sky blue as
/// the accent, its hibiscus yellow for highlights, on pale blue surfaces.
///
/// The constant names are the original warm palette's (orange, peach, ...) so
/// every screen picks the new tones up unchanged; read them as roles, not hues.
/// Exact tones get tuned with the owner from screenshots.
abstract final class AppColors {
  /// Primary accent: sky blue, used for the header band, headings, and primary
  /// actions.
  static const Color orange = Color(0xFF29A3DC);

  /// A deeper blue for pressed/secondary accents.
  static const Color rust = Color(0xFF1B7DB0);

  /// Pale hibiscus yellow for panels and highlights.
  static const Color peach = Color(0xFFFFF1B8);

  /// Near-white blue app background.
  static const Color cream = Color(0xFFF3FAFE);

  /// Soft blue card fill (song panels, cards).
  static const Color cardPeach = Color(0xFFE2F2FB);

  static const Color textDark = Color(0xFF12324A);
  static const Color textMuted = Color(0xFF5F7C8F);
  static const Color white = Color(0xFFFFFFFF);

  // Dark theme palette: keeps the sky-blue accent on deep navy surfaces.

  /// Deep navy app background (dark counterpart to [cream]).
  static const Color darkBackground = Color(0xFF0E1C27);

  /// Slightly lifted navy surface for panels/sheets (counterpart to [peach]).
  static const Color darkSurface = Color(0xFF162A3A);

  /// Navy card fill (counterpart to [cardPeach]).
  static const Color darkCard = Color(0xFF1E3649);

  /// Off-white body text for dark surfaces (counterpart to [textDark]); keeps
  /// chord-sheet text readable.
  static const Color darkText = Color(0xFFE9F4FB);

  /// Muted blue-grey for secondary text on dark surfaces.
  static const Color darkTextMuted = Color(0xFF9AB4C6);
}
