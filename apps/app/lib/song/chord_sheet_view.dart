import 'package:flutter/material.dart';
import 'package:models/models.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Renders a parsed [ChordSheet] as chords-over-lyrics with monospace
/// alignment. Each lyric segment stacks its chord (transposed by the caller)
/// directly above the syllable where the chord changes.
class ChordSheetView extends StatelessWidget {
  const ChordSheetView({
    super.key,
    required this.sheet,
    this.transpose = 0,
    this.songKey,
  });

  /// The parsed sheet to render.
  final ChordSheet sheet;

  /// Semitone offset applied to every chord at render time.
  final int transpose;

  /// The song's key, used to bias enharmonic spelling when transposing.
  final String? songKey;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    for (final line in sheet.lines) {
      switch (line.kind) {
        case ChordLineKind.blank:
          lines.add(const SizedBox(height: AppSpacing.md));
        case ChordLineKind.section:
          lines.add(
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                '[${line.label}]',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        case ChordLineKind.comment:
          lines.add(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                line.label ?? '',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        case ChordLineKind.lyrics:
          lines.add(
            _LyricLine(
              segments: line.segments,
              transpose: transpose,
              songKey: songKey,
            ),
          );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }
}

/// One lyric line: a wrapping row of [_Segment]s, each a chord stacked over its
/// lyric run. Wrapping keeps a chord glued to its syllable.
class _LyricLine extends StatelessWidget {
  const _LyricLine({
    required this.segments,
    required this.transpose,
    required this.songKey,
  });

  final List<ChordSegment> segments;
  final int transpose;
  final String? songKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (final seg in segments)
            _Segment(segment: seg, transpose: transpose, songKey: songKey),
        ],
      ),
    );
  }
}

const TextStyle _lyricStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Courier New', 'Courier', 'monospace'],
  color: AppColors.textDark,
  height: 1.2,
  fontSize: 14,
);

const TextStyle _chordStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Courier New', 'Courier', 'monospace'],
  color: AppColors.orange,
  fontWeight: FontWeight.bold,
  height: 1.2,
  fontSize: 13,
);

class _Segment extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.transpose,
    required this.songKey,
  });

  final ChordSegment segment;
  final int transpose;
  final String? songKey;

  @override
  Widget build(BuildContext context) {
    final chord = segment.chord;
    final transposed = (chord == null || chord.isEmpty)
        ? null
        : Transposer.transposeChord(chord, transpose, key: songKey);
    // A standalone chord (no lyric) still needs a space so successive chords
    // do not collide.
    final lyric = segment.lyric.isEmpty && transposed != null
        ? ' '
        : segment.lyric;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chord row: reserve the same height even when empty so lyric baselines
        // line up across segments.
        Text(transposed ?? '​', style: _chordStyle),
        Text(lyric.isEmpty ? '​' : lyric, style: _lyricStyle),
      ],
    );
  }
}
