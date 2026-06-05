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
  });
}
