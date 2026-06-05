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

  group('extended shapes (minor 7th, sus, 6th, add9, barre)', () {
    // Each fingering audited against authoritative open/standard charts
    // (ukulele-chords.com, UkuTabs, GtrLib, til.co, JamPlay). Locking them
    // guards the broadened coverage against silent data edits.
    test('ukulele extended shapes', () {
      void uke(String c, List<int> frets) => expect(
        ChordShapes.lookup(c, ChordShapes.ukulele)!.frets,
        frets,
        reason: 'ukulele $c',
      );
      uke('Dm7', [2, 2, 1, 3]);
      uke('Em7', [0, 2, 0, 2]);
      uke('Bm7', [2, 2, 2, 2]);
      uke('Asus2', [2, 4, 5, 2]);
      uke('Asus4', [2, 2, 0, 0]);
      uke('Dsus4', [0, 2, 3, 0]);
      uke('Esus4', [4, 4, 0, 0]);
      uke('Csus2', [0, 2, 3, 3]);
      uke('Gsus4', [0, 2, 3, 3]);
      uke('C6', [0, 0, 0, 0]);
      uke('G6', [0, 2, 0, 2]);
      uke('Cadd9', [0, 2, 0, 3]);
      uke('F#m', [2, 1, 2, 0]);
      uke('C#m', [1, 2, 0, 0]);
    });

    test('guitar extended shapes', () {
      void gtr(String c, List<int> frets) => expect(
        ChordShapes.lookup(c, ChordShapes.guitar)!.frets,
        frets,
        reason: 'guitar $c',
      );
      gtr('Dm7', [-1, -1, 0, 2, 1, 1]);
      gtr('Bm7', [-1, 2, 4, 2, 3, 2]);
      gtr('Asus2', [-1, 0, 2, 2, 0, 0]);
      gtr('Asus4', [-1, 0, 2, 2, 3, 0]);
      gtr('Dsus4', [-1, -1, 0, 2, 3, 2]);
      gtr('Esus4', [0, 2, 2, 2, 0, 0]);
      gtr('Csus2', [-1, 3, 0, 0, 3, 3]);
      gtr('Gsus4', [3, 3, 0, 0, 1, 3]);
      gtr('C6', [-1, 3, 2, 2, 1, 3]);
      gtr('G6', [3, 2, 0, 2, 0, 0]);
      gtr('Cadd9', [-1, 3, 2, 0, 3, 0]);
      gtr('Gadd9', [3, 2, 0, 0, 0, 3]);
      gtr('F#m', [2, 4, 4, 2, 2, 2]);
      gtr('C#m', [-1, 4, 6, 6, 5, 4]);
    });

    test('F#m resolves via Gb enharmonic spelling on both instruments', () {
      expect(ChordShapes.lookup('Gbm', ChordShapes.ukulele)!.frets, [
        2,
        1,
        2,
        0,
      ]);
      expect(ChordShapes.lookup('Gbm', ChordShapes.guitar)!.frets, [
        2,
        4,
        4,
        2,
        2,
        2,
      ]);
    });

    test('C#m resolves via Db enharmonic spelling on ukulele', () {
      expect(ChordShapes.lookup('Dbm', ChordShapes.ukulele)!.frets, [
        1,
        2,
        0,
        0,
      ]);
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
