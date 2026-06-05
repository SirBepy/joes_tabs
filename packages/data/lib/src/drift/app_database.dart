import 'package:drift/drift.dart';
import 'package:models/models.dart';

import 'connection/connection.dart';

part 'app_database.g.dart';

/// Locally cached `songs` rows. Mirrors the catalog [Song] fields, keyed by the
/// stable Supabase `song_id`. Stable ids let a future account-migration map
/// these local rows to server rows without a rewrite (spec section 5).
class CachedSongs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Locally cached `tabs` rows for a cached song. The full ChordPro [content] is
/// stored so a tab renders fully offline. Keyed by the stable tab id; the owning
/// song is referenced by [songId] (no FK constraint so caching a tab whose song
/// row is missing never throws - we always upsert song + tabs together anyway).
class CachedTabs extends Table {
  TextColumn get id => text()();
  TextColumn get songId => text()();
  TextColumn get instrumentId => text()();
  TextColumn get content => text()();
  TextColumn get originalKey => text()();
  IntColumn get capo => integer().nullable()();
  TextColumn get difficulty => text().nullable()();
  TextColumn get source => text()();
  TextColumn get status => text()();
  TextColumn get authorId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Favorited songs, keyed by the stable [songId]. [createdAt] records when the
/// favorite was added (newest-first ordering in the Saved screen). Favorited
/// songs are never evicted from the cache by LRU.
class Favorites extends Table {
  TextColumn get songId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

/// Recently viewed songs for LRU cache management. [viewedAt] is the last view
/// timestamp; the oldest non-favorite view is evicted once the cap is exceeded.
class RecentViews extends Table {
  TextColumn get songId => text()();
  DateTimeColumn get viewedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

/// Maximum number of distinct recently-viewed songs kept cached. Favorites do
/// not count against this cap and are never evicted.
const int kRecentViewsCap = 20;

/// The Drift database for offline caching: cached songs/tabs, favorites, and an
/// LRU window of recently viewed songs.
///
/// Native (mobile/desktop) opens a file-backed database via
/// [openConnection]. On web, [openConnection] returns an in-memory database (see
/// connection/connection_web.dart) so the app still runs without the wasm
/// worker; the in-memory store simply does not survive a page reload.
@DriftDatabase(tables: [CachedSongs, CachedTabs, Favorites, RecentViews])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Test constructor: pass [NativeDatabase.memory()] (or any executor).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // --- Cache reads/writes -------------------------------------------------

  /// Upserts a full [SongWithTabs] (song row + all tab rows) into the cache.
  /// Existing tab rows for the song are replaced so a re-fetch never leaves
  /// stale tabs behind.
  Future<void> cacheSong(SongWithTabs detail) async {
    await transaction(() async {
      await into(cachedSongs).insertOnConflictUpdate(_songRow(detail.song));
      await (delete(
        cachedTabs,
      )..where((t) => t.songId.equals(detail.song.id))).go();
      for (final tab in detail.tabs) {
        await into(cachedTabs).insert(_tabRow(tab));
      }
    });
  }

  /// Reads a cached [SongWithTabs] by stable [songId], or null if not cached.
  Future<SongWithTabs?> cachedSong(String songId) async {
    final songRow = await (select(
      cachedSongs,
    )..where((s) => s.id.equals(songId))).getSingleOrNull();
    if (songRow == null) return null;
    final tabRows = await (select(
      cachedTabs,
    )..where((t) => t.songId.equals(songId))).get();
    return SongWithTabs(song: _song(songRow), tabs: tabRows.map(_tab).toList());
  }

  /// Reads cached [Song] rows (without tabs) for the given [songIds], in the
  /// input order. Ids with no cached song row are skipped. Used by the Saved
  /// screen to render favorited songs offline.
  Future<List<Song>> cachedSongsByIds(List<String> songIds) async {
    if (songIds.isEmpty) return const <Song>[];
    final rows = await (select(
      cachedSongs,
    )..where((s) => s.id.isIn(songIds))).get();
    final byId = {for (final r in rows) r.id: _song(r)};
    return [
      for (final id in songIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  // --- Favorites ----------------------------------------------------------

  /// Adds [songId] to favorites (idempotent).
  Future<void> addFavorite(String songId) {
    return into(favorites).insertOnConflictUpdate(
      FavoritesCompanion.insert(songId: songId, createdAt: DateTime.now()),
    );
  }

  /// Removes [songId] from favorites (no-op if absent).
  Future<void> removeFavorite(String songId) {
    return (delete(favorites)..where((f) => f.songId.equals(songId))).go();
  }

  /// One-shot read of the current favorite song ids, newest first.
  Future<List<String>> favoriteIds() async {
    final rows = await (select(
      favorites,
    )..orderBy([(f) => OrderingTerm.desc(f.createdAt)])).get();
    return rows.map((r) => r.songId).toList();
  }

  /// Stream of favorite song ids (newest first) for the Saved screen.
  Stream<List<String>> watchFavoriteIds() {
    final query = select(favorites)
      ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]);
    return query.watch().map((rows) => rows.map((r) => r.songId).toList());
  }

  // --- Recent views / LRU -------------------------------------------------

  /// Records a view of [songId] (insert or refresh its timestamp), then evicts
  /// the oldest NON-favorite cached songs while over [kRecentViewsCap].
  /// Favorited songs are never evicted and never counted against the cap.
  ///
  /// [at] overrides the view timestamp (tests pass strictly increasing values
  /// for deterministic LRU ordering); production uses [DateTime.now].
  Future<void> recordView(String songId, {DateTime? at}) async {
    await transaction(() async {
      await into(recentViews).insertOnConflictUpdate(
        RecentViewsCompanion.insert(
          songId: songId,
          viewedAt: at ?? DateTime.now(),
        ),
      );
      await _evictOverCap();
    });
  }

  /// Evicts the oldest non-favorite recently-viewed songs (and their cached
  /// song/tab rows) until the count of non-favorite views is within the cap.
  Future<void> _evictOverCap() async {
    final favIds = (await favoriteIds()).toSet();

    // Non-favorite views, oldest first.
    final views = await (select(
      recentViews,
    )..orderBy([(v) => OrderingTerm.asc(v.viewedAt)])).get();
    final nonFav = views.where((v) => !favIds.contains(v.songId)).toList();

    final overflow = nonFav.length - kRecentViewsCap;
    if (overflow <= 0) return;

    final evictIds = nonFav.take(overflow).map((v) => v.songId).toList();
    await (delete(recentViews)..where((v) => v.songId.isIn(evictIds))).go();
    await (delete(cachedTabs)..where((t) => t.songId.isIn(evictIds))).go();
    await (delete(cachedSongs)..where((s) => s.id.isIn(evictIds))).go();
  }

  // --- Row <-> model mapping ----------------------------------------------

  CachedSongsCompanion _songRow(Song song) => CachedSongsCompanion.insert(
    id: song.id,
    title: song.title,
    artist: song.artist,
    createdAt: song.createdAt,
    updatedAt: song.updatedAt,
  );

  Song _song(CachedSong row) => Song(
    id: row.id,
    title: row.title,
    artist: row.artist,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  CachedTabsCompanion _tabRow(Tab tab) => CachedTabsCompanion.insert(
    id: tab.id,
    songId: tab.songId,
    instrumentId: tab.instrumentId,
    content: tab.content,
    originalKey: tab.originalKey,
    capo: Value(tab.capo),
    difficulty: Value(tab.difficulty),
    source: tab.source.name,
    status: tab.status.name,
    authorId: Value(tab.authorId),
    createdAt: tab.createdAt,
    updatedAt: tab.updatedAt,
  );

  Tab _tab(CachedTab row) => Tab(
    id: row.id,
    songId: row.songId,
    instrumentId: row.instrumentId,
    content: row.content,
    originalKey: row.originalKey,
    capo: row.capo,
    difficulty: row.difficulty,
    source: TabSource.values.byName(row.source),
    status: TabStatus.values.byName(row.status),
    authorId: row.authorId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
