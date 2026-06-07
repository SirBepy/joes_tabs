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
  });

  /// The chord symbol to draw (e.g. `C`, `Am7`, `G/B`).
  final String chord;

  /// Instrument slug (`ukulele` / `guitar`) that selects the shape table.
  final String instrumentSlug;

  /// Card width; height is derived from it.
  final double width;

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

    // Reserve a left gutter for the fret-position number on up-the-neck shapes,
    // so it sits beside the grid (with a gap) instead of painted over or past it.
    final gutter = shape.baseFret > 1 ? 20.0 : 0.0;
    final left = gutter;
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

    // Fret-position number, set in the left gutter and vertically centred on the
    // top fret line (the standard chord-chart convention), left-aligned so it
    // keeps a gap from the grid rather than crowding it.
    if (shape.baseFret > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${shape.baseFret}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, top - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter old) =>
      old.shape.name != shape.name || old.shape.frets != shape.frets;
}
