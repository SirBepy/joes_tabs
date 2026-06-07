import 'package:models/models.dart';
import 'package:test/test.dart';

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
  const instruments = [ChordShapes.ukulele, ChordShapes.guitar];

  test('every family has at least one balanced quality', () {
    for (final family in ChordFamily.values) {
      final balanced = kBalancedQualities
          .where((q) => q.family == family)
          .toList();
      expect(
        balanced,
        isNotEmpty,
        reason: '${family.name} has no balanced quality',
      );
    }
  });

  test('balanced tier matches the spec set', () {
    final balanced = kBalancedQualities.map((q) => q.suffix).toSet();
    expect(balanced, {
      '', 'maj7', '6', 'add9', // major
      'm', 'm7', 'm6', 'madd9', // minor
      '7', '9', '11', '13', // dominant
      'sus2', 'sus4', // suspended
      'dim', 'dim7', 'm7b5', // diminished
      'aug', 'aug7', // augmented
    });
  });

  test('every catalog quality renders for every root on both instruments', () {
    for (final q in kChordQualities) {
      for (final r in roots) {
        for (final instrument in instruments) {
          final shape = ChordShapes.lookup('$r${q.suffix}', instrument);
          expect(
            shape,
            isNotNull,
            reason: '$instrument missing $r${q.suffix} (${q.family.name})',
          );
        }
      }
    }
  });

  test('qualitiesFor filters by family and tier', () {
    final balancedMajor = qualitiesFor(
      ChordFamily.major,
      maximal: false,
    ).map((q) => q.suffix);
    expect(balancedMajor, containsAll(['', 'maj7', '6', 'add9']));
    expect(balancedMajor, isNot(contains('maj9'))); // extended hidden when off

    final maximalMajor = qualitiesFor(
      ChordFamily.major,
      maximal: true,
    ).map((q) => q.suffix);
    expect(maximalMajor, contains('maj9'));
  });
}
