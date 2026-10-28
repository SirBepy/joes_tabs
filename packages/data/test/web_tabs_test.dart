import 'dart:convert';

import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  group('ukuleleTabsSearchResults', () {
    const page = '''
<div class="song_res"><span class="tabtype chrd">chords</span> <a href="/uke-songs/a/love-like-you-uke-tab-1.html">Love Like You</a> - <em><a class="parenth" href="/a.html">Rebecca Sugar</a></em></div>
<div class="song_res"><span class="tabtype tab">tab</span> <a href="/uke-songs/a/riff-uke-tab-2.html">Riff</a></div>
<div class="song_res"><span class="tabtype mix">mix</span> <a href="/uke-songs/b/both-uke-tab-3.html">Both</a></div>
''';

    test('keeps chord sheets as ukulele-tabs.com results with artist', () {
      final results = ukuleleTabsSearchResults(page);
      expect(results.map((r) => r.title), ['Love Like You', 'Both']);
      expect(results.first.artist, 'Rebecca Sugar');
      expect(results.first.site, WebTabSite.ukuleleTabs);
      expect(results.first.songId, isNull);
      expect(results.last.artist, isNull);
    });

    test('withSongId keeps the artist', () {
      final r = ukuleleTabsSearchResults(page).first.withSongId('s1');
      expect(r.songId, 's1');
      expect(r.artist, 'Rebecca Sugar');
    });
  });

  group('SupabaseWebTabsRepository.search', () {
    const page = '''
<div class="song_res"><span class="tabtype chrd">chords</span> <a href="/uke-songs/a/love-like-you-uke-tab-1.html">Love Like You</a> - <em><a class="parenth" href="/a.html">Rebecca Sugar</a></em></div>
''';
    const loveUrl =
        'https://www.ukulele-tabs.com/uke-songs/a/love-like-you-uke-tab-1.html';

    SupabaseClient backend(List<Uri> calls) => SupabaseClient(
      'http://localhost:54321',
      'anon-key',
      httpClient: MockClient((request) async {
        calls.add(request.url);
        return http.Response(
          jsonEncode([
            {'source_url': loveUrl, 'song_id': 's7'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    test('fetches the site search page on device, never our backend', () async {
      final siteCalls = <Uri>[];
      final backendCalls = <Uri>[];
      final repo = SupabaseWebTabsRepository(
        backend(backendCalls),
        httpClient: MockClient((request) async {
          siteCalls.add(request.url);
          return http.Response(page, 200);
        }),
      );

      final results = await repo.search('love');

      expect(siteCalls.single, ukuleleTabsSearchUrl('love'));
      expect(backendCalls, isEmpty);
      expect(results.single.title, 'Love Like You');
      expect(results.single.artist, 'Rebecca Sugar');
    });

    test('a failed site fetch is a CatalogException', () async {
      final repo = SupabaseWebTabsRepository(
        backend([]),
        httpClient: MockClient((_) async => http.Response('', 503)),
      );
      expect(repo.search('love'), throwsA(isA<CatalogException>()));
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

  test('a web song id resolves from memory, never the catalog', () async {
    const url = 'https://www.ukulele-tabs.com/uke-songs/a/b-uke-tab-1.html';
    final catalog = _CountingCatalog();
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
    );
    addTearDown(container.dispose);

    expect(await container.read(songProvider(url).future), isNull);

    final song = SongWithTabs(song: webSongStub(url));
    container.read(webSongsProvider.notifier).state = {url: song};
    expect(await container.read(songProvider(url).future), song);
    expect(catalog.getSongCalls, 0);
  });
}
