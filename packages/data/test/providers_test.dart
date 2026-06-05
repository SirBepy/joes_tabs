import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

/// In-memory [CatalogRepository] used to test the provider graph without a
/// network or a real Supabase client. Records the arguments it was called with
/// so the family providers can be asserted end to end.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.songs = const <Song>[],
    this.songDetail,
    this.instrumentList = const <Instrument>[],
  });

  final List<Song> songs;
  final SongWithTabs? songDetail;
  final List<Instrument> instrumentList;

  String? lastSearchQuery;
  String? lastSongId;
  String? lastInstrumentSlug;

  @override
  Future<List<Song>> trending({int limit = 20}) async => songs;

  @override
  Future<List<Song>> listSongs({String? instrumentSlug, int limit = 50}) async {
    lastInstrumentSlug = instrumentSlug;
    return songs;
  }

  @override
  Future<List<Song>> search(String query) async {
    lastSearchQuery = query;
    return songs;
  }

  @override
  Future<SongWithTabs?> getSong(String id) async {
    lastSongId = id;
    return songDetail;
  }

  @override
  Future<List<Instrument>> instruments() async => instrumentList;
}

Song _song(String id, String title) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('catalogRepositoryProvider can be overridden for the whole graph', () {
    final fake = FakeCatalogRepository();
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    expect(container.read(catalogRepositoryProvider), same(fake));
  });

  test('trendingProvider resolves through the repository', () async {
    final fake = FakeCatalogRepository(songs: [_song('a', 'Aaa')]);
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final result = await container.read(trendingProvider.future);
    expect(result.single.title, 'Aaa');
  });

  test('searchProvider passes the query through', () async {
    final fake = FakeCatalogRepository(songs: [_song('a', 'Aaa')]);
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(searchProvider('riptide').future);
    expect(fake.lastSearchQuery, 'riptide');
  });

  test('songsByInstrumentProvider passes the slug through', () async {
    final fake = FakeCatalogRepository();
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(songsByInstrumentProvider('ukulele').future);
    expect(fake.lastInstrumentSlug, 'ukulele');
  });

  test('songProvider returns the detail aggregate', () async {
    final detail = SongWithTabs(song: _song('s1', 'Riptide'));
    final fake = FakeCatalogRepository(songDetail: detail);
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final result = await container.read(songProvider('s1').future);
    expect(result, isNotNull);
    expect(result!.song.title, 'Riptide');
    expect(fake.lastSongId, 's1');
  });

  test('supabaseClientProvider throws until overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(supabaseClientProvider),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test(
    'OfflineCatalogRepository passes trending + search through to its remote',
    () async {
      final fake = FakeCatalogRepository(songs: [_song('a', 'Aaa')]);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final offline = OfflineCatalogRepository(remote: fake, cache: db);

      final trending = await offline.trending();
      expect(trending.single.title, 'Aaa');

      await offline.search('q');
      expect(fake.lastSearchQuery, 'q');
    },
  );
}
