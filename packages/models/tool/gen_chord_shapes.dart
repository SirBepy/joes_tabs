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

/// (chords-db suffix, our symbol suffix), in display order.
const List<(String, String)> _qualities = [
  ('major', ''),
  ('minor', 'm'),
  ('7', '7'),
  ('m7', 'm7'),
  ('maj7', 'maj7'),
  ('sus2', 'sus2'),
  ('sus4', 'sus4'),
  ('6', '6'),
  ('dim', 'dim'),
  ('aug', 'aug'),
  ('add9', 'add9'),
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

String _emitMap(String name, Map<String, dynamic> db, List<int> openMidi) {
  final pcToGroupKey = _pcToGroupKey(db);
  final buf = StringBuffer('const Map<String, ChordShape> $name = {\n');
  for (final (root, pc) in _roots) {
    for (final (dbSuffix, symSuffix) in _qualities) {
      final symbol = '$root$symSuffix';
      final shape = _resolve(db, openMidi, pcToGroupKey, pc, dbSuffix, symbol);
      buf.writeln(
        "  '$symbol': ChordShape(name: '$symbol', "
        'frets: ${shape.frets}, baseFret: ${shape.baseFret}),',
      );
    }
  }
  buf.writeln('};');
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
  final symSuffixOf = {for (final (db, sym) in _qualities) db: sym};
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

  final ukeMap = _emitMap('kUkuleleShapes', ukulele, ukeMidi);
  final gtrMap = _emitMap('kGuitarShapes', guitar, gtrMidi);

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
      '// 12 roots x 11 qualities per instrument. Frets are absolute fret',
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

  final ukeCount = _roots.length * _qualities.length;
  print('OK: wrote lib/src/chordpro/chord_shapes_data.dart');
  print(
    '  ukulele: $ukeCount shapes, guitar: $ukeCount shapes (all midi-validated)',
  );

  _diffReport('UKULELE', ukulele, ukeMidi, _oldUkulele);
  _diffReport('GUITAR', guitar, gtrMidi, _oldGuitar);
}
