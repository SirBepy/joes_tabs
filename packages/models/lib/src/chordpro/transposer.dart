/// Chord transposition: shift a chord symbol by N semitones with correct
/// enharmonic spelling. Pure functions, no Flutter dependency.
library;

/// Transposes chord symbols by a number of semitones.
///
/// Handles a root note (with optional accidental), an arbitrary suffix
/// (`m`, `7`, `maj7`, `sus4`, `dim`, `add9`, ...), and an optional slash bass
/// note (`G/B`). Both the root and the bass are transposed; the suffix is
/// preserved verbatim. Unknown / unparseable symbols are returned unchanged.
class Transposer {
  const Transposer._();

  // Chromatic scale using sharps. Index 0 = C.
  static const List<String> _sharps = [
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

  // Chromatic scale using flats. Index 0 = C.
  static const List<String> _flats = [
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

  // Semitone offset of each natural note from C.
  static const Map<String, int> _naturals = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  /// Keys conventionally spelled with flats. Used to choose enharmonics when no
  /// explicit [preferSharps] is given.
  static const Set<String> _flatKeys = {
    'F',
    'Bb',
    'Eb',
    'Ab',
    'Db',
    'Gb',
    'Cb',
    'Dm',
    'Gm',
    'Cm',
    'Fm',
    'Bbm',
    'Ebm',
  };

  /// Returns the semitone index (0..11) of a note name like `C`, `C#`, `Db`,
  /// or null if it is not a valid note.
  static int? noteIndex(String note) {
    if (note.isEmpty) return null;
    final letter = note[0].toUpperCase();
    final base = _naturals[letter];
    if (base == null) return null;
    var value = base;
    for (var i = 1; i < note.length; i++) {
      final ch = note[i];
      if (ch == '#') {
        value += 1;
      } else if (ch == 'b' || ch == 'B') {
        // Lower-case b is a flat. (Upper-case B as an accidental never occurs
        // mid-token, but tolerate it.)
        value -= 1;
      } else {
        return null; // not an accidental -> not a pure note token
      }
    }
    return value % 12;
  }

  /// Transposes a single chord [symbol] by [semitones] (may be negative).
  ///
  /// [key] biases enharmonic spelling toward the conventional accidentals of
  /// that key (e.g. transposing into F prefers `Bb` over `A#`). [preferSharps]
  /// overrides that heuristic when non-null.
  static String transposeChord(
    String symbol,
    int semitones, {
    String? key,
    bool? preferSharps,
  }) {
    final trimmed = symbol.trim();
    if (trimmed.isEmpty) return symbol;

    final useSharps = preferSharps ?? !_flatKeys.contains(key);

    // Split on a slash bass note, if present.
    final slash = trimmed.indexOf('/');
    if (slash >= 0) {
      final main = trimmed.substring(0, slash);
      final bass = trimmed.substring(slash + 1);
      final tMain = transposeChord(
        main,
        semitones,
        key: key,
        preferSharps: useSharps,
      );
      final tBass = _transposeNote(bass, semitones, useSharps);
      return '$tMain/${tBass ?? bass}';
    }

    // Parse the root note (letter + optional accidentals).
    final match = RegExp(r'^([A-Ga-g])([#b]*)(.*)$').firstMatch(trimmed);
    if (match == null) return symbol;
    final root = '${match.group(1)}${match.group(2)}';
    final suffix = match.group(3) ?? '';

    final shifted = _transposeNote(root, semitones, useSharps);
    if (shifted == null) return symbol;
    return '$shifted$suffix';
  }

  /// Transposes a bare note name (root or bass) by [semitones]. Returns null if
  /// [note] is not a valid note token.
  static String? _transposeNote(String note, int semitones, bool useSharps) {
    final idx = noteIndex(note);
    if (idx == null) return null;
    final next = (idx + (semitones % 12) + 12) % 12;
    return (useSharps ? _sharps : _flats)[next];
  }

  /// Transposes a key name (e.g. `G`, `Am`, `Bb`) by [semitones], preserving a
  /// trailing minor `m`.
  static String transposeKey(String key, int semitones) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return key;
    final isMinor = trimmed.endsWith('m') && trimmed.length > 1;
    final root = isMinor ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    final useSharps = !_flatKeys.contains(trimmed);
    final shifted = _transposeNote(root, semitones, useSharps);
    if (shifted == null) return key;
    return isMinor ? '${shifted}m' : shifted;
  }
}
