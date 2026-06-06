/// Chord-shape (fingering) dataset for ukulele and guitar. Pure Dart data, no
/// Flutter dependency, so it can be unit-tested directly. The diagram widget in
/// the app turns a [ChordShape] into a fretboard drawing.
library;

import 'chord_shapes_data.dart';
import 'transposer.dart';

/// A fretboard fingering for one chord on one instrument.
///
/// [frets] has one entry per string, low-to-high in the diagram's left-to-right
/// order. A value of `0` is an open string, `-1` is a muted/unplayed string,
/// and a positive number is the fret pressed. [baseFret] is the fret the
/// diagram starts at (1 for open chords; higher for barre shapes up the neck).
class ChordShape {
  const ChordShape({
    required this.name,
    required this.frets,
    this.baseFret = 1,
  });

  /// The chord this shape voices (e.g. `C`, `Am`, `G7`).
  final String name;

  /// One fret per string. `0` open, `-1` muted, positive = pressed fret.
  final List<int> frets;

  /// The lowest fret shown in the diagram window (>= 1).
  final int baseFret;

  /// Number of strings this shape spans.
  int get stringCount => frets.length;
}

/// Static lookup of chord shapes for the supported instruments.
///
/// The shape tables ([kUkuleleShapes], [kGuitarShapes]) are GENERATED from the
/// MIT-licensed `tombatossals/chords-db` dataset by `tool/gen_chord_shapes.dart`
/// and cover 12 roots x 11 qualities (major, minor, 7, m7, maj7, sus2, sus4, 6,
/// dim, aug, add9) per instrument. [lookup] resolves a chord symbol to a shape,
/// normalizing enharmonics and falling back through slash chords, and returns
/// null when no diagram is known (the UI then shows a "no diagram" note).
class ChordShapes {
  const ChordShapes._();

  /// `slug` values matching the `instruments` table.
  static const String ukulele = 'ukulele';
  static const String guitar = 'guitar';

  /// All chord names that have a shape for [instrumentSlug], sorted.
  static List<String> namesFor(String instrumentSlug) {
    final map = _mapFor(instrumentSlug);
    if (map == null) return const [];
    final names = map.keys.toList()..sort();
    return names;
  }

  static Map<String, ChordShape>? _mapFor(String instrumentSlug) {
    switch (instrumentSlug) {
      case ukulele:
        return kUkuleleShapes;
      case guitar:
        return kGuitarShapes;
      default:
        return null;
    }
  }

  /// Resolves [symbol] to a [ChordShape] for [instrumentSlug], or null if no
  /// diagram is known.
  ///
  /// Resolution order:
  /// 1. Exact match on the full symbol.
  /// 2. Match on the symbol's root + suffix after normalizing enharmonics
  ///    (e.g. `Db` resolves via `C#`).
  /// 3. Slash chords fall back to the main chord (`G/B` -> `G`).
  static ChordShape? lookup(String symbol, String instrumentSlug) {
    final map = _mapFor(instrumentSlug);
    if (map == null) return null;
    final trimmed = symbol.trim();
    if (trimmed.isEmpty) return null;

    // 1. Exact.
    final exact = map[trimmed];
    if (exact != null) {
      return ChordShape(
        name: trimmed,
        frets: exact.frets,
        baseFret: exact.baseFret,
      );
    }

    // 3. Slash chord -> main chord (try before enharmonic so the displayed name
    // keeps the slash bass).
    final slash = trimmed.indexOf('/');
    if (slash > 0) {
      final main = lookup(trimmed.substring(0, slash), instrumentSlug);
      if (main != null) {
        return ChordShape(
          name: trimmed,
          frets: main.frets,
          baseFret: main.baseFret,
        );
      }
    }

    // 2. Enharmonic normalization on the root.
    final m = RegExp(r'^([A-Ga-g][#b]*)(.*)$').firstMatch(trimmed);
    if (m != null) {
      final root = m.group(1)!;
      final suffix = m.group(2) ?? '';
      final idx = Transposer.noteIndex(root);
      if (idx != null) {
        // Try both sharp and flat spellings of this pitch class.
        for (final spelling in _spellings(idx)) {
          final candidate = map['$spelling$suffix'];
          if (candidate != null) {
            return ChordShape(
              name: trimmed,
              frets: candidate.frets,
              baseFret: candidate.baseFret,
            );
          }
        }
      }
    }

    return null;
  }

  static const List<String> _sharpNames = [
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
  static const List<String> _flatNames = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static List<String> _spellings(int idx) {
    final sharp = _sharpNames[idx];
    final flat = _flatNames[idx];
    return sharp == flat ? [sharp] : [sharp, flat];
  }
}
