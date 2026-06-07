// ignore_for_file: avoid_print
//
// Generator for `lib/src/chordpro/chord_shapes_data.dart`.
//
// Reads the vendored, pinned chords-db datasets in `tool/chords_db/` and emits a
// committed Dart data file holding one `const ChordShape` per
// root x quality, for ukulele and guitar. chords-db is MIT-licensed
// (see THIRD_PARTY_LICENSES.md). Pinned commit: df06fa7b425cf5fd29485ff6591236b3557e3fac.
//
// Run from the package root:
//   dart run tool/gen_chord_shapes.dart
//
// It also prints a validation pass (every voicing is checked against the
// position's shipped `midi` array) and a diff report of how the new voicings
// differ from the previously hand-audited shapes.
//
// chords-db stores frets RELATIVE to each position's baseFret; we store ABSOLUTE
// fret numbers (matching ChordShape), converting with: abs = baseFret + fret - 1
// for fret >= 1; 0 stays open; -1 stays muted.

import 'dart:convert';
import 'dart:io';

/// Canonical sharp-spelled roots in pitch-class order.
const List<(String, int)> _roots = [
  ('C', 0),
  ('C#', 1),
  ('D', 2),
  ('D#', 3),
  ('E', 4),
  ('F', 5),
  ('F#', 6),
  ('G', 7),
  ('G#', 8),
  ('A', 9),
  ('A#', 10),
  ('B', 11),
];

/// (our suffix, chords-db suffix, family enum name, label, extended?).
/// Balanced tier first; extended (maximal-only) after. Order within a family is
/// the on-screen Type-strip order.
const List<({String suffix, String db, String family, String label, bool extended})>
    _catalog = [
  // Major
  (suffix: '', db: 'major', family: 'major', label: 'Major', extended: false),
  (suffix: 'maj7', db: 'maj7', family: 'major', label: 'maj7', extended: false),
  (suffix: '6', db: '6', family: 'major', label: '6', extended: false),
  (suffix: 'add9', db: 'add9', family: 'major', label: 'add9', extended: false),
  (suffix: 'maj9', db: 'maj9', family: 'major', label: 'maj9', extended: true),
  (suffix: 'maj11', db: 'maj11', family: 'major', label: 'maj11', extended: true),
  (suffix: 'maj13', db: 'maj13', family: 'major', label: 'maj13', extended: true),
  (suffix: '69', db: '69', family: 'major', label: '6/9', extended: true),
  // Minor
  (suffix: 'm', db: 'minor', family: 'minor', label: 'Minor', extended: false),
  (suffix: 'm7', db: 'm7', family: 'minor', label: 'm7', extended: false),
  (suffix: 'm6', db: 'm6', family: 'minor', label: 'm6', extended: false),
  (suffix: 'madd9', db: 'madd9', family: 'minor', label: 'madd9', extended: false),
  (suffix: 'm9', db: 'm9', family: 'minor', label: 'm9', extended: true),
  (suffix: 'm11', db: 'm11', family: 'minor', label: 'm11', extended: true),
  (suffix: 'mmaj7', db: 'mmaj7', family: 'minor', label: 'mMaj7', extended: true),
  // Dominant
  (suffix: '7', db: '7', family: 'dominant', label: '7', extended: false),
  (suffix: '9', db: '9', family: 'dominant', label: '9', extended: false),
  (suffix: '11', db: '11', family: 'dominant', label: '11', extended: false),
  (suffix: '13', db: '13', family: 'dominant', label: '13', extended: false),
  (suffix: '7b5', db: '7b5', family: 'dominant', label: '7b5', extended: true),
  (suffix: '7b9', db: '7b9', family: 'dominant', label: '7b9', extended: true),
  (suffix: '7#9', db: '7#9', family: 'dominant', label: '7#9', extended: true),
  (suffix: '9b5', db: '9b5', family: 'dominant', label: '9b5', extended: true),
  (suffix: '7sus4', db: '7sus4', family: 'dominant', label: '7sus4', extended: true),
  // Suspended
  (suffix: 'sus2', db: 'sus2', family: 'suspended', label: 'sus2', extended: false),
  (suffix: 'sus4', db: 'sus4', family: 'suspended', label: 'sus4', extended: false),
  // Diminished
  (suffix: 'dim', db: 'dim', family: 'diminished', label: 'dim', extended: false),
  (suffix: 'dim7', db: 'dim7', family: 'diminished', label: 'dim7', extended: false),
  (suffix: 'm7b5', db: 'm7b5', family: 'diminished', label: 'm7b5', extended: false),
  // Augmented
  (suffix: 'aug', db: 'aug', family: 'augmented', label: 'aug', extended: false),
  (suffix: 'aug7', db: 'aug7', family: 'augmented', label: 'aug7', extended: false),
  (suffix: 'aug9', db: 'aug9', family: 'augmented', label: 'aug9', extended: true),
];

const Map<String, int> _noteToPc = {
  'C': 0,
  'C#': 1,
  'Db': 1,
  'D': 2,
  'D#': 3,
  'Eb': 3,
  'E': 4,
  'F': 5,
  'F#': 6,
  'Gb': 6,
  'G': 7,
  'G#': 8,
  'Ab': 8,
  'A': 9,
  'A#': 10,
  'Bb': 10,
  'B': 11,
};

/// Previously hand-audited shapes, kept only to print a diff report so the dev
/// can eyeball common-chord voicing changes. Frets are absolute, baseFret 1.
const Map<String, List<int>> _oldUkulele = {
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
  'C6': [0, 0, 0, 0],
  'G6': [0, 2, 0, 2],
  'Cadd9': [0, 2, 0, 3],
  'F#m': [2, 1, 2, 0],
  'C#m': [1, 2, 0, 0],
};
const Map<String, List<int>> _oldGuitar = {
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
  'C6': [-1, 3, 2, 2, 1, 3],
  'G6': [3, 2, 0, 2, 0, 0],
  'Cadd9': [-1, 3, 2, 0, 3, 0],
  'F#m': [2, 4, 4, 2, 2, 2],
  'C#m': [-1, 4, 6, 6, 5, 4],
};

int _noteNameToMidi(String s) {
  // e.g. "E2", "G#4". Last char(s) are the octave.
  final m = RegExp(r'^([A-G][#b]?)(-?\d+)$').firstMatch(s);
  if (m == null) throw FormatException('bad note: $s');
  final pc = _noteToPc[m.group(1)!]!;
  final octave = int.parse(m.group(2)!);
  return 12 * (octave + 1) + pc;
}

class _Shape {
  _Shape(this.frets, this.baseFret);
  final List<int> frets; // absolute
  final int baseFret;
}

/// Resolves one root x quality from a chords-db dataset, validates it against the
/// shipped midi array, and returns the absolute-fret shape. Throws on any
/// mismatch or missing entry so generation fails loudly.
_Shape _resolve(
  Map<String, dynamic> db,
  List<int> openMidi,
  Map<int, String> pcToGroupKey,
  int pc,
  String dbSuffix,
  String symbol,
) {
  final groupKey = pcToGroupKey[pc];
  if (groupKey == null) throw StateError('no group key for pc $pc ($symbol)');
  final list =
      (db['chords'] as Map<String, dynamic>)[groupKey] as List<dynamic>;
  final entry = list.cast<Map<String, dynamic>>().firstWhere(
    (c) => c['suffix'] == dbSuffix,
    orElse: () => throw StateError('missing $groupKey/$dbSuffix for $symbol'),
  );

  // chords-db's positions[0] is not always the friendliest (e.g. guitar Dm7's
  // first voicing sits at the 10th fret). Pick the most beginner-playable one:
  // lowest baseFret, then prefer non-barre, then more open strings, then fewer
  // fretted strings (fingers), then the lowest top fret. Muted strings are NOT
  // penalised - a partial voicing (e.g. xx3210 Fmaj7) is easier than a barre.
  // All candidates are human-designed dataset voicings.
  final positions = (entry['positions'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  int barreOf(Map<String, dynamic> p) =>
      (p['barres'] as List<dynamic>).isEmpty ? 0 : 1;
  int openOf(Map<String, dynamic> p) =>
      (p['frets'] as List<dynamic>).where((f) => f == 0).length;
  int frettedOf(Map<String, dynamic> p) =>
      (p['frets'] as List<dynamic>).where((f) => (f as int) > 0).length;
  int topFretOf(Map<String, dynamic> p) {
    final b = p['baseFret'] as int;
    return (p['frets'] as List<dynamic>)
        .cast<int>()
        .where((f) => f > 0)
        .map((f) => b + f - 1)
        .fold(0, (a, f) => f > a ? f : a);
  }

  final pos = positions.reduce((a, b) {
    int cmp(int x, int y) => x.compareTo(y);
    final byBase = cmp(a['baseFret'] as int, b['baseFret'] as int);
    if (byBase != 0) return byBase < 0 ? a : b;
    final byBarre = cmp(barreOf(a), barreOf(b)); // non-barre first
    if (byBarre != 0) return byBarre < 0 ? a : b;
    final byOpen = cmp(openOf(b), openOf(a)); // more open first
    if (byOpen != 0) return byOpen < 0 ? a : b;
    final byFretted = cmp(frettedOf(a), frettedOf(b)); // fewer fingers first
    if (byFretted != 0) return byFretted < 0 ? a : b;
    final byTop = cmp(topFretOf(a), topFretOf(b));
    return byTop <= 0 ? a : b;
  });

  final baseFret = pos['baseFret'] as int;
  final raw = (pos['frets'] as List<dynamic>).cast<int>();
  final abs = raw
      .map((f) => f <= 0 ? f : baseFret + f - 1)
      .toList(growable: false);

  // Validate against the shipped midi (sounding strings only, in string order).
  final expected = <int>[];
  for (var s = 0; s < raw.length; s++) {
    if (raw[s] == -1) continue;
    expected.add(openMidi[s] + abs[s]);
  }
  final midi = (pos['midi'] as List<dynamic>).cast<int>();
  if (expected.length != midi.length ||
      !List.generate(
        midi.length,
        (i) => expected[i] == midi[i],
      ).every((b) => b)) {
    throw StateError(
      'midi mismatch for $symbol ($groupKey/$dbSuffix): '
      'computed $expected vs shipped $midi (raw $raw baseFret $baseFret)',
    );
  }
  return _Shape(abs, baseFret);
}

Map<int, String> _pcToGroupKey(Map<String, dynamic> db) {
  final out = <int, String>{};
  for (final k in (db['chords'] as Map<String, dynamic>).keys) {
    final norm = k.replaceAll('sharp', '#');
    final pc = _noteToPc[norm];
    if (pc != null) out[pc] = k;
  }
  return out;
}

/// One quality that survived the completeness check and will be emitted into
/// both shape maps and the qualities catalog.
typedef _Emitted = ({
  String suffix,
  String db,
  String family,
  String label,
  bool extended,
});

/// Attempts to resolve [entry] for all 12 roots on [db]; returns true iff every
/// root resolves without throwing. Used by the completeness pre-pass.
bool _resolvesAll(
  _Emitted entry,
  Map<String, dynamic> db,
  List<int> openMidi,
) {
  final pcToGroupKey = _pcToGroupKey(db);
  for (final (root, pc) in _roots) {
    final symbol = '$root${entry.suffix}';
    try {
      _resolve(db, openMidi, pcToGroupKey, pc, entry.db, symbol);
    } catch (_) {
      return false;
    }
  }
  return true;
}

/// Builds the emitted catalog from `_catalog`, preserving order. Balanced
/// qualities MUST resolve for every root on both instruments (throws on a gap).
/// Extended qualities are included only when complete; incomplete ones are
/// dropped with a printed warning so the picker never offers an unrenderable
/// chord.
List<_Emitted> _buildEmitted(
  Map<String, dynamic> ukulele,
  List<int> ukeMidi,
  Map<String, dynamic> guitar,
  List<int> gtrMidi,
) {
  final out = <_Emitted>[];
  for (final c in _catalog) {
    final entry = (
      suffix: c.suffix,
      db: c.db,
      family: c.family,
      label: c.label,
      extended: c.extended,
    );
    final ukeOk = _resolvesAll(entry, ukulele, ukeMidi);
    final gtrOk = _resolvesAll(entry, guitar, gtrMidi);
    final complete = ukeOk && gtrOk;
    if (!c.extended) {
      if (!complete) {
        // Surface the precise failure for a balanced quality (hard error).
        final pcToGroupKey = _pcToGroupKey(ukeOk ? guitar : ukulele);
        final db = ukeOk ? guitar : ukulele;
        final midi = ukeOk ? gtrMidi : ukeMidi;
        for (final (root, pc) in _roots) {
          _resolve(db, midi, pcToGroupKey, pc, entry.db, '$root${entry.suffix}');
        }
        throw StateError(
          'balanced quality "${entry.label}" (db ${entry.db}) is incomplete '
          'on ${ukeOk ? 'guitar' : 'ukulele'} but no per-root throw surfaced',
        );
      }
      out.add(entry);
    } else if (complete) {
      out.add(entry);
    } else {
      final missing = <String>[
        if (!ukeOk) 'ukulele',
        if (!gtrOk) 'guitar',
      ].join('+');
      print(
        '  DROP extended "${entry.label}" (db ${entry.db}): '
        'incomplete coverage on $missing',
      );
    }
  }
  return out;
}

String _emitMap(
  String name,
  Map<String, dynamic> db,
  List<int> openMidi,
  List<_Emitted> emitted,
) {
  final pcToGroupKey = _pcToGroupKey(db);
  final buf = StringBuffer('const Map<String, ChordShape> $name = {\n');
  for (final (root, pc) in _roots) {
    for (final entry in emitted) {
      final symbol = '$root${entry.suffix}';
      final shape = _resolve(db, openMidi, pcToGroupKey, pc, entry.db, symbol);
      buf.writeln(
        "  '$symbol': ChordShape(name: '$symbol', "
        'frets: ${shape.frets}, baseFret: ${shape.baseFret}),',
      );
    }
  }
  buf.writeln('};');
  return buf.toString();
}

String _emitQualities(List<_Emitted> emitted) {
  final buf = StringBuffer()
    ..writeln('// GENERATED by tool/gen_chord_shapes.dart - DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// The ordered chord-quality catalog (family, tier, label) used by')
    ..writeln('// the chord picker. Source: chords-db master table in the generator.')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'chord_catalog.dart';")
    ..writeln()
    ..writeln('const List<ChordQuality> kChordQualities = [');
  for (final e in emitted) {
    buf.writeln(
      "  ChordQuality(suffix: '${e.suffix}', family: ChordFamily.${e.family}, "
      "label: '${e.label}', extended: ${e.extended}),",
    );
  }
  buf.writeln('];');
  return buf.toString();
}

void _diffReport(
  String label,
  Map<String, dynamic> db,
  List<int> openMidi,
  Map<String, List<int>> old,
) {
  final pcToGroupKey = _pcToGroupKey(db);
  final pcOf = {for (final (r, pc) in _roots) r: pc};
  // Map our display suffix -> chords-db suffix from the master catalog.
  final symSuffixOf = {for (final c in _catalog) c.db: c.suffix};
  // Reverse: our symbol -> (root, dbSuffix). Build from old keys we can parse.
  print('\n=== $label diff (old audited -> new chords-db) ===');
  var changed = 0;
  for (final sym in old.keys.toList()..sort()) {
    final m = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(sym)!;
    final root = m.group(1)!;
    final suffix = m.group(2)!;
    // Map our display suffix back to a chords-db suffix.
    final dbSuffix = symSuffixOf.entries
        .firstWhere(
          (e) => e.value == suffix,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    final pc = pcOf[root] ?? _noteToPc[root];
    if (dbSuffix.isEmpty && suffix.isNotEmpty)
      continue; // not in our quality set
    if (pc == null) continue;
    try {
      final neu = _resolve(db, openMidi, pcToGroupKey, pc, dbSuffix, sym);
      final same =
          neu.baseFret == 1 &&
          neu.frets.length == old[sym]!.length &&
          List.generate(
            neu.frets.length,
            (i) => neu.frets[i] == old[sym]![i],
          ).every((b) => b);
      if (!same) {
        changed++;
        print(
          '  $sym: ${old[sym]} -> ${neu.frets}'
          '${neu.baseFret > 1 ? ' (baseFret ${neu.baseFret})' : ''}',
        );
      }
    } catch (e) {
      print('  $sym: ERROR $e');
    }
  }
  print('  ($changed of ${old.length} previously-audited shapes changed)');
}

void main() {
  // Resolve paths relative to this script so it runs from any cwd.
  final toolDir = File.fromUri(Platform.script).parent.path;
  final dir = Directory(toolDir).parent.path; // package root (packages/models)
  final guitar =
      jsonDecode(File('$dir/tool/chords_db/guitar.json').readAsStringSync())
          as Map<String, dynamic>;
  final ukulele =
      jsonDecode(File('$dir/tool/chords_db/ukulele.json').readAsStringSync())
          as Map<String, dynamic>;

  List<int> openMidi(Map<String, dynamic> db) =>
      ((db['tunings'] as Map<String, dynamic>)['standard'] as List<dynamic>)
          .cast<String>()
          .map(_noteNameToMidi)
          .toList();

  final ukeMidi = openMidi(ukulele);
  final gtrMidi = openMidi(guitar);

  // Completeness pre-pass: balanced must resolve everywhere (throws on a gap),
  // extended is kept only when complete on both instruments.
  print('Building emitted catalog (completeness pre-pass)...');
  final emitted = _buildEmitted(ukulele, ukeMidi, guitar, gtrMidi);

  final ukeMap = _emitMap('kUkuleleShapes', ukulele, ukeMidi, emitted);
  final gtrMap = _emitMap('kGuitarShapes', guitar, gtrMidi, emitted);

  final out = StringBuffer()
    ..writeln(
      '// GENERATED by tool/gen_chord_shapes.dart - DO NOT EDIT BY HAND.',
    )
    ..writeln('//')
    ..writeln(
      '// Source: tombatossals/chords-db (MIT, see THIRD_PARTY_LICENSES.md),',
    )
    ..writeln('// pinned commit df06fa7b425cf5fd29485ff6591236b3557e3fac.')
    ..writeln('// Regenerate: dart run tool/gen_chord_shapes.dart')
    ..writeln('//')
    ..writeln(
      '// 12 roots x ${emitted.length} qualities per instrument. Frets are '
      'absolute fret',
    )
    ..writeln(
      '// numbers (0 open, -1 muted); baseFret is the diagram window start.',
    )
    ..writeln("library;")
    ..writeln()
    ..writeln("import 'chord_shapes.dart';")
    ..writeln()
    ..write(ukeMap)
    ..writeln()
    ..write(gtrMap);

  File(
    '$dir/lib/src/chordpro/chord_shapes_data.dart',
  ).writeAsStringSync(out.toString());

  File(
    '$dir/lib/src/chordpro/chord_qualities_data.dart',
  ).writeAsStringSync(_emitQualities(emitted));

  final shapeCount = _roots.length * emitted.length;
  final balanced = emitted.where((e) => !e.extended).length;
  final extended = emitted.where((e) => e.extended).length;
  print('OK: wrote lib/src/chordpro/chord_shapes_data.dart');
  print('OK: wrote lib/src/chordpro/chord_qualities_data.dart');
  print(
    '  emitted ${emitted.length} qualities '
    '($balanced balanced + $extended extended)',
  );
  print(
    '  ukulele: $shapeCount shapes, guitar: $shapeCount shapes '
    '(all midi-validated)',
  );

  _diffReport('UKULELE', ukulele, ukeMidi, _oldUkulele);
  _diffReport('GUITAR', guitar, gtrMidi, _oldGuitar);
}
