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

  group('verified fingerings', () {
    // Spot-checks of audited open-position shapes against authoritative charts
    // (Live Ukulele, UkuTabs, Fender Play, JamPlay). Each is a factual fretting,
    // not a stylistic choice, so locking them guards against silent data edits.
    test('ukulele open shapes', () {
      void uke(String c, List<int> frets) => expect(
        ChordShapes.lookup(c, ChordShapes.ukulele)!.frets,
        frets,
        reason: 'ukulele $c',
      );
      uke('C', [0, 0, 0, 3]);
      uke('G', [0, 2, 3, 2]);
      uke('D', [2, 2, 2, 0]);
      uke('D7', [2, 2, 2, 3]);
      uke('Am', [2, 0, 0, 0]);
      uke('Em', [0, 4, 3, 2]);
      uke('E', [4, 4, 4, 2]);
      uke('A7', [0, 1, 0, 0]);
      uke('F', [2, 0, 1, 0]);
      uke('Bb', [3, 2, 1, 1]);
    });

    test('guitar open shapes', () {
      void gtr(String c, List<int> frets) => expect(
        ChordShapes.lookup(c, ChordShapes.guitar)!.frets,
        frets,
        reason: 'guitar $c',
      );
      gtr('C', [-1, 3, 2, 0, 1, 0]);
      gtr('G', [3, 2, 0, 0, 0, 3]);
      gtr('D', [-1, -1, 0, 2, 3, 2]);
      gtr('Em', [0, 2, 2, 0, 0, 0]);
      gtr('Em7', [0, 2, 0, 0, 0, 0]);
      gtr('A', [-1, 0, 2, 2, 2, 0]);
      gtr('Am', [-1, 0, 2, 2, 1, 0]);
      gtr('E', [0, 2, 2, 1, 0, 0]);
      gtr('B7', [-1, 2, 1, 2, 0, 2]);
      gtr('F', [1, 3, 3, 2, 1, 1]);
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
