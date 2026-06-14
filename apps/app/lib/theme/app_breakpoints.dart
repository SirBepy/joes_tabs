/// Responsive breakpoints and width caps for the wide-screen layout pass.
///
/// The app is mobile-first against the 390x844 mockups; these constants gate the
/// additive desktop behavior described in `docs/desktop-layout-language.md`.
/// Below [kBreakpointMedium] every screen renders its untouched mobile layout.
library;

/// Phone -> large phone / small tablet. Below this width the layout is the
/// untouched mobile layout; griddy screens only switch to a grid at/above it.
const double kBreakpointMedium = 600;

/// Tablet -> desktop.
const double kBreakpointExpanded = 1024;

/// Max width for single-column reading / form screens. Extra width becomes
/// margin, not longer line lengths.
const double kReadingMaxWidth = 600;

/// Outer cap for griddy screens, so ultra-wide windows do not stretch content
/// edge to edge.
const double kPageMaxWidth = 1100;

/// How many columns of at least [minTileWidth] fit in [width], clamped to >= 1.
/// Screens use this so column count scales with available width rather than
/// hardcoding a desktop column count.
int gridColumnsForWidth(double width, {required double minTileWidth}) {
  final columns = (width / minTileWidth).floor();
  return columns < 1 ? 1 : columns;
}
