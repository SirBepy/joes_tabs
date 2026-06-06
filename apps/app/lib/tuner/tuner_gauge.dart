/// Presentational tuner gauge: a sliding chromatic note ribbon under a fixed,
/// color-coded center pointer, with the big target-note letter + cents readout
/// and an in-tune glow+pulse. Driven entirely by props - no business logic.
library;

import 'package:flutter/material.dart';

import 'pitch.dart';

// Tuner zone colors (design spec; tweakable later with Joe).
const Color _green = Color(0xFF3FA34D);
const Color _amber = Color(0xFFE8B23C);
const Color _red = Color(0xFFD9534F);
const Color _ink = Color(0xFF3A2E27);
const Color _muted = Color(0xFFB8A99D);
const Color _peach2 = Color(0xFFF6E2D4);

Color _colorFor(TuneZone z) => switch (z) {
  TuneZone.green => _green,
  TuneZone.amber => _amber,
  TuneZone.red => _red,
};

/// How many chromatic neighbors show on each side of the center note.
const int _perSide = 3;

/// Pixels between adjacent semitone labels (one semitone == 100 cents).
const double _semitonePx = 74;

class TunerGauge extends StatefulWidget {
  const TunerGauge({
    super.key,
    required this.centerNote,
    required this.cents,
    required this.zone,
    required this.isInTune,
    required this.active,
    this.octave = 0,
  });

  /// The note the ribbon is centered on (a bare letter, e.g. 'G').
  final String centerNote;

  /// Scientific octave of the note sounding (e.g. 3 for G3); shown as a small
  /// superscript on the big note. Ignored when 0 / inactive.
  final int octave;

  /// Smoothed signed cents from the target (negative = flat).
  final double cents;

  /// Color bucket for the pointer / note / cents.
  final TuneZone zone;

  /// Whether the reading is within the in-tune window (drives the glow/pulse).
  final bool isInTune;

  /// False when nothing is locked (listening / silence): shows a muted state.
  final bool active;

  @override
  State<TunerGauge> createState() => _TunerGaugeState();
}

class _TunerGaugeState extends State<TunerGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(TunerGauge old) {
    super.didUpdateWidget(old);
    // Fire the celebration on the rising edge of in-tune.
    if (widget.isInTune && widget.active && !(old.isInTune && old.active)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? _colorFor(widget.zone) : _muted;
    final notes = chromaticRibbon(widget.centerNote, _perSide);
    final centsLabel = !widget.active
        ? '--'
        : '${widget.cents >= 0 ? '+' : ''}${widget.cents.round()}¢';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big target-note letter with a single glow+pulse on lock.
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // Triangle 0->1->0 over 300ms: swell to 1.12x then settle to 1.0.
            final scale = widget.isInTune
                ? 1 + 0.12 * (1 - (2 * _pulse.value - 1).abs())
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: widget.centerNote),
                if (widget.active && widget.octave > 0)
                  TextSpan(
                    text: '${widget.octave}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      // Raise it to sit as a superscript.
                      textBaseline: TextBaseline.alphabetic,
                      height: 2.4,
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: color,
              shadows: widget.isInTune
                  ? [const Shadow(color: _green, blurRadius: 18)]
                  : null,
            ),
          ),
        ),
        Text(
          centsLabel,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        // The gauge: fixed center pointer + sliding ribbon + detent band.
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 96,
            color: _peach2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Green detent band marking the +/-5 cent in-tune zone.
                Container(
                  width: (2 * 5 / 100) * _semitonePx,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: _green.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                // Sliding ribbon: translate by -cents within the semitone.
                TweenAnimationBuilder<double>(
                  tween: Tween(end: widget.active ? widget.cents : 0),
                  duration: const Duration(milliseconds: 90),
                  builder: (context, animCents, _) {
                    final dx = -(animCents / 100) * _semitonePx;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      // The full chromatic row is wider than the gauge; let it
                      // overflow its parent (the ClipRRect clips the excess)
                      // instead of tripping a RenderFlex overflow.
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final n in notes)
                              SizedBox(
                                width: _semitonePx,
                                child: Center(
                                  child: Text(
                                    n,
                                    style: TextStyle(
                                      fontWeight: n == widget.centerNote
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: n.contains('#') ? 13 : 20,
                                      color: n == widget.centerNote
                                          ? _ink
                                          : (n.contains('#')
                                                ? _muted
                                                : _ink.withValues(alpha: 0.7)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Fixed center pointer (downward triangle), colored by zone.
                Align(
                  alignment: Alignment.topCenter,
                  child: CustomPaint(
                    size: const Size(18, 13),
                    painter: _PointerPainter(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.color != color;
}
