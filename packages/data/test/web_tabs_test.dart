import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.utc(2026).toIso8601String(),
);

class _CountingCatalog implements CatalogRepository {
  int searchSongsCalls = 0;
  int getSongCalls = 0;

  @override
  Future<List<Song>> searchSongs(String query, {String? instrumentSlug}) async {
    searchSongsCalls++;
    return const [];
  }

  @override
  Future<SongWithTabs?> getSong(String id) async {
    getSongCalls++;
    return null;
  }

  @override
  Future<List<Song>> trending({int limit = 20}) async => const [];

  @override
  Future<List<Song>> listSongs({
    String? instrumentSlug,
    int limit = 50,
  }) async => const [];

  @override
  Future<List<Song>> search(String query) async => const [];

  @override
  Future<List<Instrument>> instruments() async => const [];
}

class _FakeWebTabs implements WebTabsRepository {
  String? lastQuery;

  @override
  Future<List<WebSearchResult>> search(String query) async {
    lastQuery = query;
    return [
      WebSearchResult(
        title: 'Love Like You',
        url: Uri.parse('https://ukulele-tabs.com/love.html'),
        description: '',
        site: WebTabSite.ukuleleTabs,
      ),
    ];
  }

  @override
  Future<String> importTab({
    required String title,
    String? artist,
    required Uri sourceUrl,
    required WebTabSite site,
    required String instrumentSlug,
    required String chordPro,
  }) async => 'song-1';
}

void main() {
  group('parseWebSearchResponse', () {
    test('keeps allowlisted results and resolves their site', () {
      final results = parseWebSearchResponse({
        'results': [
          {
            'title': 'Love Like You',
            'url': 'https://ukulele-tabs.com/love.html',
            'description': 'chords',
          },
          {
            'title': 'UG',
            'url': 'https://tabs.ultimate-guitar.com/tab/x',
            'description': '',
          },
        ],
      });
      expect(results.map((r) => r.site), [
        WebTabSite.ukuleleTabs,
        WebTabSite.ultimateGuitar,
      ]);
      expect(results.first.title, 'Love Like You');
      expect(results.first.songId, isNull);
    });

    test('skips malformed entries and off-list hosts', () {
      final results = parseWebSearchResponse({
        'results': [
          'nope',
          {'title': 'no url'},
          {'title': 'x', 'url': 42},
          {'title': 'x', 'url': 'https://songsterr.com/a'},
          {'url': 'https://chordie.com/a'},
        ],
      });
      expect(results, hasLength(1));
      expect(results.single.site, WebTabSite.chordie);
      expect(results.single.title, '');
    });

    test('tolerates a body without results', () {
      expect(parseWebSearchResponse(null), isEmpty);
      expect(parseWebSearchResponse({'results': 'x'}), isEmpty);
      expect(parseWebSearchResponse('text'), isEmpty);
    });
  });

  test('webSearchProvider passes the query to the repository', () async {
    final fake = _FakeWebTabs();
    final container = ProviderContainer(
      overrides: [webTabsRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final results = await container.read(webSearchProvider('su').future);
    expect(fake.lastQuery, 'su');
    expect(results.single.site, WebTabSite.ukuleleTabs);
  });

  test('catalog results refetch when the user signs in', () async {
    final catalog = _CountingCatalog();
    final signedIn = StateProvider<User?>((ref) => null);
    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        currentUserProvider.overrideWith((ref) => ref.watch(signedIn)),
      ],
    );
    addTearDown(container.dispose);

    const args = (query: 'steven universe', instrumentSlug: null);
    container.listen(searchFilteredProvider(args), (_, _) {});
    container.listen(songProvider('s1'), (_, _) {});
    await container.read(searchFilteredProvider(args).future);
    await container.read(songProvider('s1').future);
    expect(catalog.searchSongsCalls, 1);
    expect(catalog.getSongCalls, 1);

    container.read(signedIn.notifier).state = _user('u1');
    await container.read(searchFilteredProvider(args).future);
    await container.read(songProvider('s1').future);
    expect(catalog.searchSongsCalls, 2);
    expect(catalog.getSongCalls, 2);
  });

  test('the offline cache keeps an imported tab\'s source credit', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.utc(2026, 10, 27);
    await db.cacheSong(
      SongWithTabs(
        song: Song(
          id: 's1',
          title: 'Love Like You',
          artist: 'Steven Universe',
          createdAt: now,
          updatedAt: now,
        ),
        tabs: [
          Tab(
            id: 't1',
            songId: 's1',
            instrumentId: 'uke',
            content: '[C]If I could',
            originalKey: '',
            source: TabSource.imported,
            status: TabStatus.published,
            sourceUrl: 'https://ukulele-tabs.com/love.html',
            sourceSite: 'ukulele-tabs',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    final tab = (await db.cachedSong('s1'))!.tabs.single;
    expect(tab.sourceUrl, 'https://ukulele-tabs.com/love.html');
    expect(tab.sourceSite, 'ukulele-tabs');
  });

  test('a tabs row maps source_url and source_site', () {
    final tab = CatalogMappers.tab({
      'id': 't1',
      'song_id': 's1',
      'instrument_id': 'i1',
      'content': '[C]x',
      'original_key': null,
      'capo': null,
      'difficulty': null,
      'source': 'imported',
      'status': 'published',
      'author_id': 'u1',
      'source_url': 'https://chordie.com/a',
      'source_site': 'chordie',
      'created_at': '2026-10-27T00:00:00Z',
      'updated_at': '2026-10-27T00:00:00Z',
    });
    expect(tab.sourceUrl, 'https://chordie.com/a');
    expect(tab.sourceSite, 'chordie');
  });
}
