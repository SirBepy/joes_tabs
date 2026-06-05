import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

/// A representative `songs` row as Supabase/PostgREST returns it (snake_case).
Map<String, dynamic> _songRow({
  String id = '11111111-1111-1111-1111-111111111111',
  String title = 'Riptide',
  String artist = 'Vance Joy',
}) => <String, dynamic>{
  'id': id,
  'title': title,
  'artist': artist,
  'created_at': '2026-01-02T03:04:05.000Z',
  'updated_at': '2026-01-02T03:04:05.000Z',
  // search_tsv is also returned by `select()`/RPC but ignored by the model.
  'search_tsv': "'riptide':1A 'vance':2B",
};

/// A representative `tabs` row.
Map<String, dynamic> _tabRow({
  String id = '22222222-2222-2222-2222-222222222222',
  String songId = '11111111-1111-1111-1111-111111111111',
  String status = 'published',
  Object? originalKey = 'C',
}) => <String, dynamic>{
  'id': id,
  'song_id': songId,
  'instrument_id': '33333333-3333-3333-3333-333333333333',
  'content': '{title: Riptide}\n[Am]I was scared of...',
  'original_key': originalKey,
  'capo': 1,
  'difficulty': 'easy',
  'source': 'imported',
  'status': status,
  'author_id': null,
  'created_at': '2026-01-02T03:04:05.000Z',
  'updated_at': '2026-01-02T03:04:05.000Z',
};

void main() {
  group('CatalogMappers.song', () {
    test('decodes a snake_case songs row, ignoring extra columns', () {
      final song = CatalogMappers.song(_songRow());
      expect(song.id, '11111111-1111-1111-1111-111111111111');
      expect(song.title, 'Riptide');
      expect(song.artist, 'Vance Joy');
      expect(song.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });
  });

  group('CatalogMappers.songs', () {
    test('maps a list of rows in order', () {
      final songs = CatalogMappers.songs([
        _songRow(id: 'a', title: 'Aaa'),
        _songRow(id: 'b', title: 'Bbb'),
      ]);
      expect(songs.map((s) => s.title), ['Aaa', 'Bbb']);
    });

    test('returns empty list for empty input', () {
      expect(CatalogMappers.songs(const <dynamic>[]), isEmpty);
    });
  });

  group('CatalogMappers.tab', () {
    test('decodes a tabs row with enums', () {
      final tab = CatalogMappers.tab(_tabRow());
      expect(tab.songId, '11111111-1111-1111-1111-111111111111');
      expect(tab.source, TabSource.imported);
      expect(tab.status, TabStatus.published);
      expect(tab.originalKey, 'C');
      expect(tab.capo, 1);
    });

    test('normalizes null original_key to empty string', () {
      final tab = CatalogMappers.tab(_tabRow(originalKey: null));
      expect(tab.originalKey, '');
    });

    test('normalizes a missing original_key key to empty string', () {
      final row = _tabRow()..remove('original_key');
      final tab = CatalogMappers.tab(row);
      expect(tab.originalKey, '');
    });

    test('does not mutate the caller-supplied row map', () {
      final row = _tabRow(originalKey: null);
      CatalogMappers.tab(row);
      expect(row['original_key'], isNull);
    });
  });

  group('CatalogMappers.songWithEmbeddedTabs', () {
    test('splits the embedded tabs array from the song fields', () {
      final row = _songRow();
      row['tabs'] = [_tabRow(), _tabRow(id: 'other', status: 'draft')];

      final swt = CatalogMappers.songWithEmbeddedTabs(row);
      expect(swt.song.title, 'Riptide');
      expect(swt.tabs, hasLength(2));
      // publishedTabs is a model convenience that filters drafts.
      expect(swt.publishedTabs, hasLength(1));
      expect(swt.publishedTabs.single.status, TabStatus.published);
    });

    test('handles a song row with no embedded tabs key', () {
      final swt = CatalogMappers.songWithEmbeddedTabs(_songRow());
      expect(swt.tabs, isEmpty);
      expect(swt.song.title, 'Riptide');
    });
  });

  group('CatalogMappers.songWithTabs', () {
    test('combines a song row with separate tab rows', () {
      final swt = CatalogMappers.songWithTabs(
        songRow: _songRow(),
        tabRows: [_tabRow()],
      );
      expect(swt.song.artist, 'Vance Joy');
      expect(swt.tabs.single.id, '22222222-2222-2222-2222-222222222222');
    });
  });
}
