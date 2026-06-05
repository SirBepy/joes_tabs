import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  group('lookup exact', () {
    test('ukulele C / G7 / Am', () {
      expect(ChordShapes.lookup('C', ChordShapes.ukulele)!.frets, [0, 0, 0, 3]);
      expect(ChordShapes.lookup('G7', ChordShapes.ukulele)!.frets, [
        0,
        2,
        1,
        2,
      ]);
      expect(ChordShapes.lookup('Am', ChordShapes.ukulele)!.frets, [
        2,
        0,
        0,
        0,
      ]);
    });

    test('guitar shapes have 6 strings, ukulele 4', () {
      expect(ChordShapes.lookup('G', ChordShapes.guitar)!.stringCount, 6);
      expect(ChordShapes.lookup('G', ChordShapes.ukulele)!.stringCount, 4);
    });
  });

  group('lookup enharmonic', () {
    test('Bb resolves to A# spelling (or vice versa)', () {
      final uke = ChordShapes.lookup('Bb', ChordShapes.ukulele);
      expect(uke, isNotNull);
      expect(uke!.frets, [3, 2, 1, 1]);
    });
  });

  group('lookup slash chords', () {
    test('G/B falls back to G shape, keeps display name', () {
      final shape = ChordShapes.lookup('G/B', ChordShapes.ukulele);
      expect(shape, isNotNull);
      expect(shape!.name, 'G/B');
      expect(shape.frets, ChordShapes.lookup('G', ChordShapes.ukulele)!.frets);
    });
  });

  group('unknown', () {
    test('returns null, does not throw', () {
      expect(ChordShapes.lookup('Xyz9', ChordShapes.ukulele), isNull);
      expect(ChordShapes.lookup('C', 'banjo'), isNull);
      expect(ChordShapes.lookup('', ChordShapes.ukulele), isNull);
    });
  });

  group('coverage', () {
    // Chords used across the seed catalogue must all resolve for both
    // instruments so the song view never shows a missing diagram for them.
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
    test('seed chords resolve on ukulele', () {
      for (final c in seedChords) {
        expect(
          ChordShapes.lookup(c, ChordShapes.ukulele),
          isNotNull,
          reason: 'ukulele missing $c',
        );
      }
    });
    test('seed chords resolve on guitar', () {
      for (final c in seedChords) {
        expect(
          ChordShapes.lookup(c, ChordShapes.guitar),
          isNotNull,
          reason: 'guitar missing $c',
        );
      }
    });
  });

  test('namesFor returns sorted names; empty for unknown instrument', () {
    final names = ChordShapes.namesFor(ChordShapes.ukulele);
    expect(names, isNotEmpty);
    final sorted = [...names]..sort();
    expect(names, sorted);
    expect(ChordShapes.namesFor('banjo'), isEmpty);
  });
}
