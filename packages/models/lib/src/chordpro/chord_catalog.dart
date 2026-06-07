/// Chord families and the ordered quality catalog that drives the chord picker
/// and the "browse all" library. The `kChordQualities` list is GENERATED from
/// the same chords-db master table as the voicings (see
/// `tool/gen_chord_shapes.dart`); this file owns the public types and re-exports
/// the generated list.
library;

import 'chord_qualities_data.dart';

export 'chord_qualities_data.dart' show kChordQualities;

/// The six chord families, in display order. Each maps to a strip chip.
enum ChordFamily {
  major('Major'),
  minor('Minor'),
  dominant('Dominant'),
  suspended('Suspended'),
  diminished('Diminished'),
  augmented('Augmented');

  const ChordFamily(this.label);

  /// Human label shown on the Family strip.
  final String label;
}

/// One selectable chord quality (the "Type" within a family).
///
/// [suffix] is appended to a root to form a chord symbol resolvable by
/// `ChordShapes.lookup` (e.g. root `C` + suffix `m7` -> `Cm7`; the major triad
/// has an empty suffix). [label] is the chip text. [extended] is true for
/// qualities only shown when "Maximal chords" is on.
class ChordQuality {
  const ChordQuality({
    required this.suffix,
    required this.family,
    required this.label,
    required this.extended,
  });

  final String suffix;
  final ChordFamily family;
  final String label;
  final bool extended;
}

/// The balanced (default) qualities: everything not gated behind maximal mode.
List<ChordQuality> get kBalancedQualities =>
    kChordQualities.where((q) => !q.extended).toList();

/// Qualities for [family], filtered to the balanced tier unless [maximal].
List<ChordQuality> qualitiesFor(ChordFamily family, {required bool maximal}) =>
    kChordQualities
        .where((q) => q.family == family && (maximal || !q.extended))
        .toList();
