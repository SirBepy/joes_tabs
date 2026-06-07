/// Presentational tuner gauge: a continuous chromatic ruler that scrolls under a
/// fixed, color-coded center pointer, with the big target-note letter + cents
/// readout and an in-tune glow+pulse. Driven entirely by props - no business
/// logic.
///
/// The ruler is one long chromatic strip (not a fixed window that re-centers), so
/// moving between notes/strings slides smoothly past the pointer instead of
/// snapping. Its scroll position is a continuous pitch-class coordinate
/// (note + cents); octave changes never yank it because position is unwrapped to
/// the nearest equivalent of the previous position (always the short way around).
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

const List<String> _names = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Pixels between adjacent semitone labels (one semitone == 100 cents).
const double _semitonePx = 74;

/// Note labels rendered on each side of the center (window is virtualized, so
/// this just needs to exceed what is visible).
const int _windowHalf = 7;

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

  /// The note the ruler centers on when in tune (a bare letter, e.g. 'G').
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

  /// Continuous, unwrapped chromatic position the ruler is scrolled to.
  double? _pos;

  int get _pitchClass => _names.indexOf(widget.centerNote);

  /// Target scroll position = pitch class + cents, chosen as the octave
  /// equivalent nearest the previous position so a string/octave change slides
  /// the short way instead of jumping across the ruler.
  double _resolveTarget() {
    final pc = _pitchClass;
    if (pc < 0) return _pos ?? 0;
    final raw = pc + (widget.active ? widget.cents / 100.0 : 0.0);
    final prev = _pos;
    if (prev == null) return raw;
    var best = raw;
    var bestDist = (raw - prev).abs();
    for (final k in const [-24, -12, 12, 24]) {
      final cand = raw + k;
      final d = (cand - prev).abs();
      if (d < bestDist) {
        bestDist = d;
        best = cand;
      }
    }
    return best;
  }

  @override
  void didUpdateWidget(TunerGauge old) {
    super.didUpdateWidget(old);
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
    final centsLabel = !widget.active
        ? '--'
        : '${widget.cents >= 0 ? '+' : ''}${widget.cents.round()}¢';
    final target = _resolveTarget();
    _pos = target;
    final pc = _pitchClass;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big target-note letter with a single glow+pulse on lock.
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
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
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _muted,
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
        // The ruler: a continuous chromatic strip scrolling under a fixed pointer.
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 96,
            color: _peach2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final centerX = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    // Green detent band marking the +/-5 cent in-tune zone.
                    Positioned(
                      left: centerX - (5 / 100) * _semitonePx,
                      width: (2 * 5 / 100) * _semitonePx,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.12),
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: _green.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The scrolling chromatic labels (virtualized window).
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: target),
                      duration: const Duration(milliseconds: 130),
                      curve: Curves.easeOut,
                      builder: (context, pos, _) {
                        final base = pos.round();
                        final labels = <Widget>[];
                        for (
                          var i = base - _windowHalf;
                          i <= base + _windowHalf;
                          i++
                        ) {
                          final x = centerX + (i - pos) * _semitonePx;
                          final name = _names[((i % 12) + 12) % 12];
                          final isSharp = name.contains('#');
                          final isTarget =
                              widget.active && pc >= 0 && ((i - pc) % 12) == 0;
                          labels.add(
                            Positioned(
                              left: x - _semitonePx / 2,
                              width: _semitonePx,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isTarget
                                        ? FontWeight.w800
                                        : (isSharp
                                              ? FontWeight.w500
                                              : FontWeight.w600),
                                    fontSize: isSharp ? 13 : 20,
                                    color: isTarget
                                        ? color
                                        : (isSharp
                                              ? _muted
                                              : _ink.withValues(alpha: 0.55)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Stack(children: labels);
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
                );
              },
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
