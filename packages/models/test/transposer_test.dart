import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  group('Transposer.noteIndex', () {
    test('naturals', () {
      expect(Transposer.noteIndex('C'), 0);
      expect(Transposer.noteIndex('E'), 4);
      expect(Transposer.noteIndex('B'), 11);
    });
    test('sharps and flats', () {
      expect(Transposer.noteIndex('C#'), 1);
      expect(Transposer.noteIndex('Db'), 1);
      expect(Transposer.noteIndex('Bb'), 10);
      expect(Transposer.noteIndex('Cb'), 11); // wraps below C
    });
    test('invalid', () {
      expect(Transposer.noteIndex(''), isNull);
      expect(Transposer.noteIndex('H'), isNull);
      expect(Transposer.noteIndex('Cx'), isNull);
    });
  });

  group('Transposer.transposeChord', () {
    test('simple up', () {
      expect(Transposer.transposeChord('C', 2), 'D');
      expect(Transposer.transposeChord('G', 2), 'A');
    });
    test('wrap-around at the top', () {
      expect(Transposer.transposeChord('B', 1), 'C');
      expect(Transposer.transposeChord('A#', 1), 'B');
    });
    test('wrap-around at the bottom (negative)', () {
      expect(Transposer.transposeChord('C', -1), 'B');
      expect(Transposer.transposeChord('C', -2), 'A#');
    });
    test('zero is identity', () {
      expect(Transposer.transposeChord('F#m7', 0), 'F#m7');
    });
    test('preserves minor / 7th / maj7 / sus / add suffixes', () {
      expect(Transposer.transposeChord('Am', 2), 'Bm');
      expect(Transposer.transposeChord('G7', 2), 'A7');
      expect(Transposer.transposeChord('Cmaj7', 2), 'Dmaj7');
      expect(Transposer.transposeChord('Dsus4', 2), 'Esus4');
      expect(Transposer.transposeChord('Cadd9', 2), 'Dadd9');
      expect(Transposer.transposeChord('Bdim', 1), 'Cdim');
    });
    test('slash chords transpose both parts', () {
      expect(Transposer.transposeChord('G/B', 2), 'A/C#');
      expect(Transposer.transposeChord('D/F#', 1), 'D#/G');
      expect(Transposer.transposeChord('C/E', 5), 'F/A');
    });
    test('prefers sharps by default', () {
      expect(Transposer.transposeChord('C', 1), 'C#');
      expect(Transposer.transposeChord('G', 1), 'G#');
    });
    test('preferSharps:false uses flats', () {
      expect(Transposer.transposeChord('C', 1, preferSharps: false), 'Db');
      expect(Transposer.transposeChord('G', 1, preferSharps: false), 'Ab');
    });
    test('flat key biases spelling', () {
      // Into F major (a flat key): C+1 should spell Db not C#.
      expect(Transposer.transposeChord('C', 1, key: 'F'), 'Db');
      // Into G major (a sharp key): C+1 spells C#.
      expect(Transposer.transposeChord('C', 1, key: 'G'), 'C#');
    });
    test('unparseable returns unchanged', () {
      expect(Transposer.transposeChord('N.C.', 2), 'N.C.');
      expect(Transposer.transposeChord('', 2), '');
    });
    test('input with flat root', () {
      expect(Transposer.transposeChord('Bb', 2), 'C');
      expect(Transposer.transposeChord('Bbm7', 1), 'Bm7');
    });
  });

  group('Transposer.transposeChord edge cases', () {
    test('shifts larger than an octave wrap correctly', () {
      // +12 is identity, +14 == +2, +24 == identity.
      expect(Transposer.transposeChord('C', 12), 'C');
      expect(Transposer.transposeChord('C', 14), 'D');
      expect(Transposer.transposeChord('G', 24), 'G');
    });

    test('large negative shifts wrap correctly', () {
      expect(Transposer.transposeChord('C', -12), 'C');
      expect(Transposer.transposeChord('C', -13), 'B');
      expect(Transposer.transposeChord('C', -14), 'A#');
    });

    test('lowercase root letter is accepted', () {
      // The root regex allows a-g; noteIndex upper-cases the letter.
      expect(Transposer.transposeChord('c', 2), 'D');
      expect(Transposer.transposeChord('g7', 2), 'A7');
    });

    test('flat-key bias applies to slash basses too', () {
      // Into Bb (a flat key): D+1 root spells Eb, and the F#-ish bass spells Gb.
      expect(Transposer.transposeChord('D/F', 1, key: 'Bb'), 'Eb/Gb');
    });

    test('minor flat key (Dm) biases toward flats', () {
      expect(Transposer.transposeChord('C', 1, key: 'Dm'), 'Db');
    });

    test('preferSharps overrides the key heuristic', () {
      // Even into a flat key, preferSharps:true forces sharps.
      expect(
        Transposer.transposeChord('C', 1, key: 'F', preferSharps: true),
        'C#',
      );
    });

    test('suffix with parentheses / numbers is preserved verbatim', () {
      expect(Transposer.transposeChord('C7(b9)', 2), 'D7(b9)');
      expect(Transposer.transposeChord('Gadd11', 2), 'Aadd11');
    });

    test(
      'slash chord where the bass is unparseable keeps the bass literal',
      () {
        // "/X" is not a note; the main transposes, the bass passes through.
        expect(Transposer.transposeChord('C/X', 2), 'D/X');
      },
    );

    test('whitespace around a chord is trimmed before transposing', () {
      expect(Transposer.transposeChord('  C  ', 2), 'D');
    });

    test(
      'double-flat / double-sharp roots resolve by accumulated accidentals',
      () {
        // Cbb == Bb (index 10); +0 keeps that pitch spelled in the scale.
        expect(Transposer.transposeChord('Cbb', 0), 'A#');
      },
    );
  });

  group('Transposer.transposeKey', () {
    test('major', () {
      expect(Transposer.transposeKey('G', 2), 'A');
      expect(Transposer.transposeKey('B', 1), 'C');
    });
    test('minor preserves m', () {
      expect(Transposer.transposeKey('Am', 2), 'Bm');
      expect(Transposer.transposeKey('Em', -2), 'Dm');
    });
    test('negative wrap', () {
      expect(Transposer.transposeKey('C', -1), 'B');
    });
    test('full octave is identity', () {
      expect(Transposer.transposeKey('G', 12), 'G');
      expect(Transposer.transposeKey('Am', 12), 'Am');
    });
    test('flat key spells with flats', () {
      // F is a flat key: F+1 == Gb (not F#).
      expect(Transposer.transposeKey('F', 1), 'Gb');
      // Bbm is a flat minor key.
      expect(Transposer.transposeKey('Bbm', 2), 'Cm');
    });
    test('empty / unparseable key returns unchanged', () {
      expect(Transposer.transposeKey('', 2), '');
      expect(Transposer.transposeKey('H', 2), 'H');
    });
    test('lone "m" is treated as a note, not a minor flag', () {
      // length > 1 guard: a bare 'm' has length 1 so isMinor is false; 'm' is
      // not a valid note so it returns unchanged.
      expect(Transposer.transposeKey('m', 2), 'm');
    });
  });
}
