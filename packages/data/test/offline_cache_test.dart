import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

/// Builds a [SongWithTabs] with a single tab for [id], for cache round-trips.
SongWithTabs _detail(String id, {String title = 'Title'}) {
  final now = DateTime.utc(2026, 1, 1);
  return SongWithTabs(
    song: Song(
      id: id,
      title: title,
      artist: 'Artist',
      createdAt: now,
      updatedAt: now,
    ),
    tabs: [
      Tab(
        id: 'tab-$id',
        songId: id,
        instrumentId: 'uke',
        content: '{title: $title}\n[C]Hello',
        originalKey: 'C',
        source: TabSource.official,
        status: TabStatus.published,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

/// [CatalogRepository] that returns a fixed song, or throws on demand to
/// simulate an offline / network-error remote.
class _StubRemote implements CatalogRepository {
  _StubRemote({this.song, this.throwOnGetSong = false});

  final SongWithTabs? song;
  bool throwOnGetSong;
  int getSongCalls = 0;

  @override
  Future<SongWithTabs?> getSong(String id) async {
    getSongCalls++;
    if (throwOnGetSong) {
      throw const CatalogException('offline');
    }
    return song;
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
  Future<List<Song>> searchSongs(
    String query, {
    String? instrumentSlug,
  }) async => const [];
  @override
  Future<List<Instrument>> instruments() async => const [];
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('favorites', () {
    test(
      'add then remove is reflected by favoriteIds and the stream',
      () async {
        expect(await db.favoriteIds(), isEmpty);

        await db.addFavorite('s1');
        await db.addFavorite('s2');
        expect((await db.favoriteIds()).toSet(), {'s1', 's2'});

        // addFavorite is idempotent.
        await db.addFavorite('s1');
        expect((await db.favoriteIds()).where((id) => id == 's1').length, 1);

        await db.removeFavorite('s1');
        expect(await db.favoriteIds(), ['s2']);

        // watchFavoriteIds emits the current set.
        expect(db.watchFavoriteIds(), emits(['s2']));
      },
    );

    test('cacheSong round-trips a SongWithTabs and its tabs', () async {
      await db.cacheSong(_detail('s1', title: 'Riptide'));
      final cached = await db.cachedSong('s1');
      expect(cached, isNotNull);
      expect(cached!.song.title, 'Riptide');
      expect(cached.tabs.single.content, contains('Hello'));
      expect(cached.tabs.single.source, TabSource.official);
    });
  });

  group('recent-views LRU', () {
    test(
      'evicts oldest NON-favorite over cap, keeps favorites cached',
      () async {
        final base = DateTime.utc(2026, 1, 1);

        // Favorite + cache one song that we will keep viewing-protected.
        await db.cacheSong(_detail('fav', title: 'Favourite'));
        await db.addFavorite('fav');
        await db.recordView('fav', at: base);

        // View 25 distinct non-favorite songs with strictly increasing
        // timestamps so eviction order is deterministic.
        for (var i = 0; i < 25; i++) {
          final id = 'song-$i';
          await db.cacheSong(_detail(id));
          await db.recordView(id, at: base.add(Duration(minutes: i + 1)));
        }

        // Cap is 20 non-favorites. We added 25, so the 5 oldest non-favorites
        // (song-0..song-4) must be evicted, favorite must survive.
        final remainingFavorite = await db.cachedSong('fav');
        expect(remainingFavorite, isNotNull, reason: 'favorite never evicted');
        expect((await db.favoriteIds()), contains('fav'));

        // The 5 oldest non-favorites are gone from the cache + recent views.
        for (var i = 0; i < 5; i++) {
          expect(
            await db.cachedSong('song-$i'),
            isNull,
            reason: 'song-$i should be LRU-evicted',
          );
        }

        // The 20 most-recent non-favorites are still cached.
        for (var i = 5; i < 25; i++) {
          expect(
            await db.cachedSong('song-$i'),
            isNotNull,
            reason: 'song-$i should be retained',
          );
        }
      },
    );

    test('favorited song is never counted against the cap', () async {
      final base = DateTime.utc(2026, 1, 1);
      // 20 non-favorites fill the cap exactly.
      for (var i = 0; i < 20; i++) {
        await db.cacheSong(_detail('n$i'));
        await db.recordView('n$i', at: base.add(Duration(minutes: i)));
      }
      // Favorite + view a 21st song; because favorites do not count, no
      // non-favorite is evicted.
      await db.cacheSong(_detail('fav'));
      await db.addFavorite('fav');
      await db.recordView('fav', at: base.add(const Duration(minutes: 100)));

      for (var i = 0; i < 20; i++) {
        expect(await db.cachedSong('n$i'), isNotNull);
      }
      expect(await db.cachedSong('fav'), isNotNull);
    });
  });

  group('OfflineCatalogRepository fallback', () {
    test('serves cached song when the remote throws', () async {
      final detail = _detail('s1', title: 'Cached Title');

      // First, a healthy remote: getSong caches + records the view.
      final healthyRemote = _StubRemote(song: detail);
      final repo1 = OfflineCatalogRepository(remote: healthyRemote, cache: db);
      final first = await repo1.getSong('s1');
      expect(first?.song.title, 'Cached Title');
      expect(await db.cachedSong('s1'), isNotNull);

      // Now the remote is offline (throws): the decorator serves the cache.
      final offlineRemote = _StubRemote(throwOnGetSong: true);
      final repo2 = OfflineCatalogRepository(remote: offlineRemote, cache: db);
      final second = await repo2.getSong('s1');
      expect(second, isNotNull);
      expect(second!.song.title, 'Cached Title');
      expect(offlineRemote.getSongCalls, 1);
    });

    test('rethrows when remote throws and nothing is cached', () async {
      final offlineRemote = _StubRemote(throwOnGetSong: true);
      final repo = OfflineCatalogRepository(remote: offlineRemote, cache: db);
      expect(() => repo.getSong('missing'), throwsA(isA<CatalogException>()));
    });
  });
}
