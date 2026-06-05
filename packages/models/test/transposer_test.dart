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
  });
}
