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

    test('exactly at the cap evicts nothing', () async {
      final base = DateTime.utc(2026, 1, 1);
      // Exactly kRecentViewsCap non-favorites: the boundary is inclusive, so
      // none should be evicted.
      for (var i = 0; i < kRecentViewsCap; i++) {
        await db.cacheSong(_detail('n$i'));
        await db.recordView('n$i', at: base.add(Duration(minutes: i)));
      }
      for (var i = 0; i < kRecentViewsCap; i++) {
        expect(
          await db.cachedSong('n$i'),
          isNotNull,
          reason: 'n$i within the cap must survive',
        );
      }
    });

    test('one over the cap evicts exactly the single oldest view', () async {
      final base = DateTime.utc(2026, 1, 1);
      for (var i = 0; i <= kRecentViewsCap; i++) {
        await db.cacheSong(_detail('n$i'));
        await db.recordView('n$i', at: base.add(Duration(minutes: i)));
      }
      // n0 is the oldest and the only overflow.
      expect(await db.cachedSong('n0'), isNull, reason: 'oldest evicted');
      for (var i = 1; i <= kRecentViewsCap; i++) {
        expect(await db.cachedSong('n$i'), isNotNull, reason: 'n$i retained');
      }
    });

    test(
      're-viewing an old song refreshes its timestamp and spares it',
      () async {
        final base = DateTime.utc(2026, 1, 1);
        // n0 is the oldest. Fill exactly to the cap.
        for (var i = 0; i < kRecentViewsCap; i++) {
          await db.cacheSong(_detail('n$i'));
          await db.recordView('n$i', at: base.add(Duration(minutes: i)));
        }
        // Touch n0 again with the newest timestamp so it is no longer the LRU.
        await db.recordView('n0', at: base.add(const Duration(hours: 10)));

        // Now push one more distinct view over the cap. The evicted one must be
        // n1 (the new oldest), NOT the just-refreshed n0.
        await db.cacheSong(_detail('fresh'));
        await db.recordView('fresh', at: base.add(const Duration(hours: 11)));

        expect(
          await db.cachedSong('n0'),
          isNotNull,
          reason: 'refreshed, spared',
        );
        expect(await db.cachedSong('n1'), isNull, reason: 'new LRU evicted');
        expect(await db.cachedSong('fresh'), isNotNull);
      },
    );

    test(
      'favoriting an already-viewed song shields it from later eviction',
      () async {
        final base = DateTime.utc(2026, 1, 1);
        // n0 viewed first (oldest), then favorited.
        await db.cacheSong(_detail('n0'));
        await db.recordView('n0', at: base);
        await db.addFavorite('n0');

        // Now flood with cap+5 newer non-favorites. n0 must survive because it is
        // a favorite and so is not counted against (or evicted by) the cap.
        for (var i = 1; i <= kRecentViewsCap + 5; i++) {
          await db.cacheSong(_detail('n$i'));
          await db.recordView('n$i', at: base.add(Duration(minutes: i)));
        }
        expect(
          await db.cachedSong('n0'),
          isNotNull,
          reason: 'favorited-after-view song is never evicted',
        );
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

    test('write-through: a successful getSong caches and records a view', () async {
      final remote = _StubRemote(song: _detail('s1', title: 'Fresh'));
      final repo = OfflineCatalogRepository(remote: remote, cache: db);

      // Nothing cached up front.
      expect(await db.cachedSong('s1'), isNull);

      final result = await repo.getSong('s1');
      expect(result?.song.title, 'Fresh');
      // The song is now cached AND counts as a recent view (so it participates
      // in the LRU window). Verify the view by checking it is evictable: it is
      // the lone non-favorite, so adding cap NEWER views evicts it. getSong
      // recorded s1's view with DateTime.now(), so the flood must be later still.
      expect(await db.cachedSong('s1'), isNotNull);
      final base = DateTime.now().add(const Duration(days: 1));
      for (var i = 0; i < kRecentViewsCap; i++) {
        await db.cacheSong(_detail('flood$i'));
        await db.recordView('flood$i', at: base.add(Duration(minutes: i)));
      }
      expect(
        await db.cachedSong('s1'),
        isNull,
        reason: 'recorded view made s1 LRU-evictable',
      );
    });

    test('a null remote result is not cached and not a view', () async {
      final remote = _StubRemote(song: null);
      final repo = OfflineCatalogRepository(remote: remote, cache: db);

      final result = await repo.getSong('nope');
      expect(result, isNull);
      expect(await db.cachedSong('nope'), isNull);
    });
  });
}
