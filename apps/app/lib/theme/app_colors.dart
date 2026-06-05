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
}
