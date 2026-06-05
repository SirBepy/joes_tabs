import 'package:flutter/material.dart';

/// Brand palette for Joes Tabs.
///
/// Wireframe-level only: peach/cream surfaces with a warm orange accent. Final
/// polish (exact tones, the mascot art) happens in a later pass with the owner.
abstract final class AppColors {
  /// Saturated warm orange used for the header band, headings, and primary
  /// actions.
  static const Color orange = Color(0xFFF5A623);

  /// A deeper rust orange for pressed/secondary accents.
  static const Color rust = Color(0xFFD9822B);

  /// Peach background fill for panels and the lighter drawer body.
  static const Color peach = Color(0xFFFFE6CC);

  /// Cream app background.
  static const Color cream = Color(0xFFFFF6EC);

  /// Soft peach card fill (saved-tab cards, etc.).
  static const Color cardPeach = Color(0xFFFFEFD9);

  static const Color textDark = Color(0xFF3D2B1F);
  static const Color textMuted = Color(0xFF8A7866);
  static const Color white = Color(0xFFFFFFFF);

  // Dark theme palette: keeps the warm orange brand accent but swaps the
  // peach/cream surfaces for deep warm charcoal-brown tones so the bubble
  // identity survives in dark mode.
  // TODO(design): dark palette to be refined with Joe.

  /// Deep warm charcoal-brown app background (dark counterpart to [cream]).
  static const Color darkBackground = Color(0xFF221A14);

  /// Slightly lifted warm brown surface for panels/sheets (counterpart to
  /// [peach]).
  static const Color darkSurface = Color(0xFF2E241C);

  /// Warm brown card fill (counterpart to [cardPeach]).
  static const Color darkCard = Color(0xFF3A2D22);

  /// Light warm off-white body text for dark surfaces (counterpart to
  /// [textDark]); keeps chord-sheet text readable.
  static const Color darkText = Color(0xFFF3E9DD);

  /// Muted warm tan for secondary text on dark surfaces.
  static const Color darkTextMuted = Color(0xFFB7A48E);
}
