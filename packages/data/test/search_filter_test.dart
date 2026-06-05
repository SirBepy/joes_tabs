import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

Song _song(String id) => Song(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('SupabaseCatalogRepository.intersectByInstrument', () {
    test('keeps only matches that have a tab for the instrument', () {
      final result = SupabaseCatalogRepository.intersectByInstrument(
        [_song('a'), _song('b'), _song('c')],
        // Only a and c have a published tab for the instrument.
        [_song('a'), _song('c')],
      );

      expect(result.map((s) => s.id), ['a', 'c']);
    });

    test('preserves the search ranking order, not the instrument order', () {
      final result = SupabaseCatalogRepository.intersectByInstrument(
        [_song('c'), _song('a'), _song('b')],
        [_song('a'), _song('b'), _song('c')],
      );

      expect(result.map((s) => s.id), ['c', 'a', 'b']);
    });

    test('returns empty when no match has the instrument', () {
      final result = SupabaseCatalogRepository.intersectByInstrument([
        _song('a'),
        _song('b'),
      ], const []);

      expect(result, isEmpty);
    });

    test('empty matches with a non-empty instrument set is empty', () {
      final result = SupabaseCatalogRepository.intersectByInstrument(const [], [
        _song('a'),
        _song('b'),
      ]);
      expect(result, isEmpty);
    });

    test('both empty is empty', () {
      expect(
        SupabaseCatalogRepository.intersectByInstrument(const [], const []),
        isEmpty,
      );
    });

    test('keeps all matches when the instrument set is a superset', () {
      final result = SupabaseCatalogRepository.intersectByInstrument(
        [_song('b'), _song('a')],
        [_song('a'), _song('b'), _song('c')],
      );
      // Every match has the instrument; search order preserved.
      expect(result.map((s) => s.id), ['b', 'a']);
    });

    test('a duplicated match id is not double-emitted by membership', () {
      // The instrument set is a membership lookup, so listing an id twice on the
      // allowed side never changes the result; matches drive the output.
      final result = SupabaseCatalogRepository.intersectByInstrument(
        [_song('a'), _song('b')],
        [_song('a'), _song('a')],
      );
      expect(result.map((s) => s.id), ['a']);
    });
  });
}
