/// Chord-shape (fingering) dataset for ukulele and guitar. Pure Dart data, no
/// Flutter dependency, so it can be unit-tested directly. The diagram widget in
/// the app turns a [ChordShape] into a fretboard drawing.
library;

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

/// Static lookup of common chord shapes for the supported instruments.
///
/// The covered set is deliberately broad enough for the seeded public-domain
/// catalogue (C, D, E, G, A and their common m/7/maj7 variants, plus F, B7,
/// etc.). [lookup] resolves a chord symbol to a shape, transposing a known base
/// shape when an exact entry is missing where possible, and returns null when
/// no diagram is known (the UI then shows a "no diagram" note).
class ChordShapes {
  const ChordShapes._();

  /// `slug` values matching the `instruments` table.
  static const String ukulele = 'ukulele';
  static const String guitar = 'guitar';

  // Ukulele (GCEA), strings left-to-right G C E A.
  static const Map<String, List<int>> _ukulele = {
    'C': [0, 0, 0, 3],
    'C7': [0, 0, 0, 1],
    'Cmaj7': [0, 0, 0, 2],
    'Cm': [0, 3, 3, 3],
    'D': [2, 2, 2, 0],
    'D7': [2, 2, 2, 3],
    'Dm': [2, 2, 1, 0],
    'E': [4, 4, 4, 2],
    'E7': [1, 2, 0, 2],
    'Em': [0, 4, 3, 2],
    'F': [2, 0, 1, 0],
    'F7': [2, 3, 1, 0],
    'Fm': [1, 0, 1, 3],
    'G': [0, 2, 3, 2],
    'G7': [0, 2, 1, 2],
    'Gm': [0, 2, 3, 1],
    'A': [2, 1, 0, 0],
    'A7': [0, 1, 0, 0],
    'Am': [2, 0, 0, 0],
    'Am7': [0, 0, 0, 0],
    'B': [4, 3, 2, 2],
    'B7': [2, 3, 2, 2],
    'Bm': [4, 2, 2, 2],
    'Bb': [3, 2, 1, 1],
    'A#': [3, 2, 1, 1],
    'Dm7': [2, 2, 1, 3],
    'Em7': [0, 2, 0, 2],
    'Bm7': [2, 2, 2, 2],
    'Asus2': [2, 4, 5, 2],
    'Asus4': [2, 2, 0, 0],
    'Dsus4': [0, 2, 3, 0],
    'Esus4': [4, 4, 0, 0],
    'Csus2': [0, 2, 3, 3],
    'Gsus4': [0, 2, 3, 3],
    'C6': [0, 0, 0, 0],
    'G6': [0, 2, 0, 2],
    'Cadd9': [0, 2, 0, 3],
    'F#m': [2, 1, 2, 0],
    'C#m': [1, 2, 0, 0],
  };

  // Guitar (EADGBE), strings left-to-right low-E A D G B high-E.
  static const Map<String, List<int>> _guitar = {
    'C': [-1, 3, 2, 0, 1, 0],
    'C7': [-1, 3, 2, 3, 1, 0],
    'Cmaj7': [-1, 3, 2, 0, 0, 0],
    'Cm': [-1, 3, 5, 5, 4, 3],
    'D': [-1, -1, 0, 2, 3, 2],
    'D7': [-1, -1, 0, 2, 1, 2],
    'Dm': [-1, -1, 0, 2, 3, 1],
    'E': [0, 2, 2, 1, 0, 0],
    'E7': [0, 2, 0, 1, 0, 0],
    'Em': [0, 2, 2, 0, 0, 0],
    'Em7': [0, 2, 0, 0, 0, 0],
    'F': [1, 3, 3, 2, 1, 1],
    'Fmaj7': [-1, -1, 3, 2, 1, 0],
    'G': [3, 2, 0, 0, 0, 3],
    'G7': [3, 2, 0, 0, 0, 1],
    'Gm': [3, 5, 5, 3, 3, 3],
    'A': [-1, 0, 2, 2, 2, 0],
    'A7': [-1, 0, 2, 0, 2, 0],
    'Am': [-1, 0, 2, 2, 1, 0],
    'Am7': [-1, 0, 2, 0, 1, 0],
    'B': [-1, 2, 4, 4, 4, 2],
    'B7': [-1, 2, 1, 2, 0, 2],
    'Bm': [-1, 2, 4, 4, 3, 2],
    'Bb': [-1, 1, 3, 3, 3, 1],
    'A#': [-1, 1, 3, 3, 3, 1],
    'Dm7': [-1, -1, 0, 2, 1, 1],
    'Bm7': [-1, 2, 4, 2, 3, 2],
    'Asus2': [-1, 0, 2, 2, 0, 0],
    'Asus4': [-1, 0, 2, 2, 3, 0],
    'Dsus4': [-1, -1, 0, 2, 3, 2],
    'Esus4': [0, 2, 2, 2, 0, 0],
    'Csus2': [-1, 3, 0, 0, 3, 3],
    'Gsus4': [3, 3, 0, 0, 1, 3],
    'C6': [-1, 3, 2, 2, 1, 3],
    'G6': [3, 2, 0, 2, 0, 0],
    'Cadd9': [-1, 3, 2, 0, 3, 0],
    'Gadd9': [3, 2, 0, 0, 0, 3],
    'F#m': [2, 4, 4, 2, 2, 2],
    'C#m': [-1, 4, 6, 6, 5, 4],
  };

  /// All chord names that have a shape for [instrumentSlug], sorted.
  static List<String> namesFor(String instrumentSlug) {
    final map = _mapFor(instrumentSlug);
    if (map == null) return const [];
    final names = map.keys.toList()..sort();
    return names;
  }

  static Map<String, List<int>>? _mapFor(String instrumentSlug) {
    switch (instrumentSlug) {
      case ukulele:
        return _ukulele;
      case guitar:
        return _guitar;
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
    if (exact != null) return ChordShape(name: trimmed, frets: exact);

    // 3. Slash chord -> main chord (try before enharmonic so the displayed name
    // keeps the slash bass).
    final slash = trimmed.indexOf('/');
    if (slash > 0) {
      final main = lookup(trimmed.substring(0, slash), instrumentSlug);
      if (main != null) {
        return ChordShape(name: trimmed, frets: main.frets);
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
            return ChordShape(name: trimmed, frets: candidate);
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
