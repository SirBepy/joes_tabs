import 'package:models/models.dart';
import 'package:test/test.dart';

/// The shape tables are generated from the MIT-licensed chords-db dataset by
/// `tool/gen_chord_shapes.dart`, which validates every voicing against the
/// dataset's shipped MIDI notes. These tests guard the consumer-facing contract:
/// full coverage, sane structure, enharmonic/slash resolution, and a few
/// regenerate-friendly golden voicings to catch accidental data corruption.
void main() {
  const roots = [
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
  const suffixes = [
    '',
    'm',
    '7',
    'm7',
    'maj7',
    'sus2',
    'sus4',
    '6',
    'dim',
    'aug',
    'add9',
  ];
  const instruments = [ChordShapes.ukulele, ChordShapes.guitar];

  group('coverage: every root x quality resolves', () {
    for (final instrument in instruments) {
      test('$instrument has all ${roots.length * suffixes.length}', () {
        final expectedStrings = instrument == ChordShapes.guitar ? 6 : 4;
        for (final r in roots) {
          for (final s in suffixes) {
            final sym = '$r$s';
            final shape = ChordShapes.lookup(sym, instrument);
            expect(shape, isNotNull, reason: '$instrument missing $sym');
            expect(
              shape!.stringCount,
              expectedStrings,
              reason: '$instrument $sym string count',
            );
          }
        }
      });
    }
  });

  group('structure: fret values are sane', () {
    for (final instrument in instruments) {
      test('$instrument frets in [-1, 24], baseFret >= 1', () {
        for (final name in ChordShapes.namesFor(instrument)) {
          final shape = ChordShapes.lookup(name, instrument)!;
          expect(
            shape.baseFret,
            greaterThanOrEqualTo(1),
            reason: '$instrument $name baseFret',
          );
          for (final f in shape.frets) {
            expect(
              f,
              inInclusiveRange(-1, 24),
              reason: '$instrument $name fret $f',
            );
          }
        }
      });
    }
  });

  group('namesFor', () {
    test('returns 132 sorted names per instrument; empty for unknown', () {
      for (final instrument in instruments) {
        final names = ChordShapes.namesFor(instrument);
        expect(
          names.length,
          roots.length * suffixes.length,
          reason: instrument,
        );
        final sorted = [...names]..sort();
        expect(names, sorted, reason: '$instrument sorted');
      }
      expect(ChordShapes.namesFor('banjo'), isEmpty);
    });
  });

  group('golden spot-checks (regenerate-friendly, from chords-db)', () {
    // Update via `dart run tool/gen_chord_shapes.dart` if the dataset or the
    // friendliest-voicing selector changes.
    test('ukulele', () {
      void uke(String c, List<int> frets, [int baseFret = 1]) {
        final s = ChordShapes.lookup(c, ChordShapes.ukulele)!;
        expect(s.frets, frets, reason: 'ukulele $c frets');
        expect(s.baseFret, baseFret, reason: 'ukulele $c baseFret');
      }

      uke('C', [0, 0, 0, 3]);
      uke('G', [0, 2, 3, 2]);
      uke('Am', [2, 0, 0, 0]);
      uke('Dm7', [2, 2, 1, 3]);
      uke('Cdim', [5, 3, 2, 3], 2); // barre voicing carries its own baseFret
    });

    test('guitar', () {
      void gtr(String c, List<int> frets, [int baseFret = 1]) {
        final s = ChordShapes.lookup(c, ChordShapes.guitar)!;
        expect(s.frets, frets, reason: 'guitar $c frets');
        expect(s.baseFret, baseFret, reason: 'guitar $c baseFret');
      }

      gtr('C', [-1, 3, 2, 0, 1, 0]);
      gtr('G', [3, 2, 0, 0, 0, 3]);
      gtr('Em', [0, 2, 2, 0, 0, 0]);
      gtr('F', [
        -1,
        -1,
        3,
        2,
        1,
        1,
      ]); // beginner-friendly partial, not full barre
      gtr('C#m7', [-1, 4, 6, 4, 5, 4], 4);
    });
  });

  group('lookup enharmonic', () {
    test('flats resolve to their sharp spelling on both instruments', () {
      for (final instrument in instruments) {
        expect(
          ChordShapes.lookup('Db', instrument)!.frets,
          ChordShapes.lookup('C#', instrument)!.frets,
          reason: '$instrument Db',
        );
        expect(
          ChordShapes.lookup('Ebm', instrument)!.frets,
          ChordShapes.lookup('D#m', instrument)!.frets,
          reason: '$instrument Ebm',
        );
        expect(
          ChordShapes.lookup('Bb7', instrument)!.frets,
          ChordShapes.lookup('A#7', instrument)!.frets,
          reason: '$instrument Bb7',
        );
      }
    });
  });

  group('lookup slash chords', () {
    test('G/B falls back to G shape, keeps display name and baseFret', () {
      final g = ChordShapes.lookup('G', ChordShapes.ukulele)!;
      final shape = ChordShapes.lookup('G/B', ChordShapes.ukulele)!;
      expect(shape.name, 'G/B');
      expect(shape.frets, g.frets);
      expect(shape.baseFret, g.baseFret);
    });
  });

  group('unknown', () {
    test('returns null, does not throw', () {
      expect(ChordShapes.lookup('Xyz9', ChordShapes.ukulele), isNull);
      expect(ChordShapes.lookup('C', 'banjo'), isNull);
      expect(ChordShapes.lookup('', ChordShapes.ukulele), isNull);
    });
  });

  group('seed catalogue chords all resolve', () {
    const seedChords = [
      'C',
      'G',
      'D',
      'A',
      'E',
      'Am',
      'Em',
      'Dm',
      'F',
      'G7',
      'D7',
      'A7',
      'E7',
      'C7',
    ];
    for (final instrument in instruments) {
      test(instrument, () {
        for (final c in seedChords) {
          expect(
            ChordShapes.lookup(c, instrument),
            isNotNull,
            reason: '$instrument missing $c',
          );
        }
      });
    }
  });
}
