import 'package:flutter/material.dart';
import 'package:models/models.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A small fretboard chord diagram on a peach card.
///
/// Looks the chord up in [ChordShapes] for [instrumentSlug] and draws it with a
/// [CustomPaint] fretboard (allowed: this is a diagram, not an icon). Unknown
/// chords render the name plus a small "no diagram" note instead of crashing.
class ChordDiagram extends StatelessWidget {
  const ChordDiagram({
    super.key,
    required this.chord,
    required this.instrumentSlug,
    this.width = 64,
    this.showLabel = true,
  });

  /// The chord symbol to draw (e.g. `C`, `Am7`, `G/B`).
  final String chord;

  /// Instrument slug (`ukulele` / `guitar`) that selects the shape table.
  final String instrumentSlug;

  /// Card width; height is derived from it.
  final double width;

  /// Whether to show the chord name above the fretboard. The library needs it to
  /// label each card; the picker hides it because the result card already names
  /// the chord (avoids the repeated title).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final shape = ChordShapes.lookup(chord, instrumentSlug);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardPeach,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              chord,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (shape == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'no diagram',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            )
          else
            CustomPaint(
              size: Size(width - AppSpacing.md, (width - AppSpacing.md) * 1.25),
              painter: _FretboardPainter(shape),
            ),
        ],
      ),
    );
  }
}

/// Draws a [ChordShape] as a small vertical fretboard.
class _FretboardPainter extends CustomPainter {
  _FretboardPainter(this.shape);

  final ChordShape shape;

  static const int _fretsShown = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final strings = shape.frets.length;
    if (strings < 2) return;

    final grid = Paint()
      ..color = AppColors.rust
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = AppColors.orange;

    final left = 0.0;
    final right = size.width;
    final top = 6.0;
    final bottom = size.height - 4.0;
    final colGap = (right - left) / (strings - 1);
    final rowGap = (bottom - top) / _fretsShown;

    // Vertical string lines.
    for (var s = 0; s < strings; s++) {
      final x = left + s * colGap;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), grid);
    }
    // Horizontal fret lines (the nut, row 0, is drawn thicker).
    for (var f = 0; f <= _fretsShown; f++) {
      final y = top + f * rowGap;
      final p = Paint()
        ..color = AppColors.rust
        ..strokeWidth = (f == 0 && shape.baseFret == 1) ? 3.0 : 1.2;
      canvas.drawLine(Offset(left, y), Offset(right, y), p);
    }

    // Finger dots + open/muted markers above the nut.
    for (var s = 0; s < strings; s++) {
      final x = left + s * colGap;
      final fret = shape.frets[s];
      final relative = fret - (shape.baseFret - 1);
      if (fret <= 0) {
        // Open (o) or muted (x) marker above the nut.
        final marker = fret == 0 ? 'o' : 'x';
        final tp = TextPainter(
          text: TextSpan(
            text: marker,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, top - tp.height - 1));
      } else if (relative >= 1 && relative <= _fretsShown) {
        final y = top + (relative - 0.5) * rowGap;
        canvas.drawCircle(Offset(x, y), colGap * 0.28, dot);
      }
    }

    // Fret-position label, set just OFF the top-right of the grid (a small gap to
    // the right) and aligned to the top fret line. No gutter, so the grid keeps
    // its full size.
    if (shape.baseFret > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${shape.baseFret}fr',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(right + 3, top - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter old) =>
      old.shape.name != shape.name || old.shape.frets != shape.frets;
}
