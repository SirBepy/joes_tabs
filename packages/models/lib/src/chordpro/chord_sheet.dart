/// Structured representation of a parsed ChordPro document.
///
/// Pure Dart, no Flutter dependency, so it can be unit-tested directly. The
/// renderer (chords-over-lyrics) walks [ChordSheet.lines]; each line is an
/// ordered list of [ChordSegment]s.
library;

/// A contiguous run of lyric text, optionally preceded by a chord change.
///
/// A segment with a [chord] but empty [lyric] is a standalone chord (e.g. an
/// intro line `[A] [A] [F#m]`). A segment with a null [chord] and non-empty
/// [lyric] is plain lyric text with no chord above it.
class ChordSegment {
  const ChordSegment({this.chord, this.lyric = ''});

  /// The chord symbol that sounds at the start of [lyric] (e.g. `G`, `Am7`,
  /// `G/B`), or null when this run carries no chord change.
  final String? chord;

  /// The lyric text under/after [chord]. May be empty for a standalone chord.
  final String lyric;

  ChordSegment copyWith({String? chord, String? lyric}) =>
      ChordSegment(chord: chord ?? this.chord, lyric: lyric ?? this.lyric);

  @override
  bool operator ==(Object other) =>
      other is ChordSegment && other.chord == chord && other.lyric == lyric;

  @override
  int get hashCode => Object.hash(chord, lyric);

  @override
  String toString() =>
      'ChordSegment(chord: $chord, lyric: ${lyric.isEmpty ? '∅' : '"$lyric"'})';
}

/// The kind of a parsed [ChordLine].
enum ChordLineKind {
  /// A normal lyric/chord line built from [ChordSegment]s.
  lyrics,

  /// A blank separator line (preserve vertical spacing).
  blank,

  /// A section label such as `[Verse 1]` / `[Chorus]`, derived from a comment
  /// or a section directive. The label sits in [ChordLine.label].
  section,

  /// A comment line (`# ...`) that is not a section label.
  comment,
}

/// One rendered line of a [ChordSheet].
class ChordLine {
  const ChordLine({
    required this.kind,
    this.segments = const <ChordSegment>[],
    this.label,
  });

  /// Builds a lyrics line from [segments].
  const ChordLine.lyrics(this.segments)
    : kind = ChordLineKind.lyrics,
      label = null;

  /// A blank separator line.
  const ChordLine.blank()
    : kind = ChordLineKind.blank,
      segments = const <ChordSegment>[],
      label = null;

  /// A section heading line carrying [label] (e.g. `Verse 1`).
  const ChordLine.section(this.label)
    : kind = ChordLineKind.section,
      segments = const <ChordSegment>[];

  final ChordLineKind kind;

  /// Segments for a [ChordLineKind.lyrics] line; empty otherwise.
  final List<ChordSegment> segments;

  /// Section/comment text for [ChordLineKind.section] /
  /// [ChordLineKind.comment]; null otherwise.
  final String? label;

  @override
  String toString() => 'ChordLine($kind, segments: $segments, label: $label)';
}

/// A fully parsed ChordPro document: known directives plus rendered lines.
class ChordSheet {
  const ChordSheet({
    this.title,
    this.artist,
    this.key,
    this.capo,
    this.directives = const <String, String>{},
    this.lines = const <ChordLine>[],
  });

  /// `{title: ...}` value, if present.
  final String? title;

  /// `{artist: ...}` value, if present.
  final String? artist;

  /// `{key: ...}` value, if present (the song's written key).
  final String? key;

  /// `{capo: N}` value, if present and numeric.
  final int? capo;

  /// All raw directives keyed by their (lower-cased, canonical) name. Lets the
  /// UI read anything not promoted to a typed field above.
  final Map<String, String> directives;

  /// The document body, in source order.
  final List<ChordLine> lines;

  /// Every distinct chord symbol used in the body, in first-seen order.
  List<String> get chordsUsed {
    final seen = <String>{};
    final result = <String>[];
    for (final line in lines) {
      for (final seg in line.segments) {
        final c = seg.chord;
        if (c != null && c.isNotEmpty && seen.add(c)) result.add(c);
      }
    }
    return result;
  }
}
