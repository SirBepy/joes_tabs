import 'package:models/models.dart';

import 'catalog_repository.dart';
import 'drift/app_database.dart';

/// Offline-caching decorator for [CatalogRepository], backed by a Drift cache.
///
/// Read-through with offline fallback:
/// - [getSong] tries the remote; on success it caches the result and records a
///   view (driving the LRU window), then returns it. On failure it serves the
///   cached copy if one exists, otherwise rethrows.
/// - [trending], [listSongs], [search], [instruments] pass through to the
///   remote (the cache is keyed per song, populated as songs are opened). They
///   are NOT served from cache on failure - the offline guarantee is scoped to
///   favorited + recently-viewed *songs* (spec section 5), which [getSong]
///   covers.
class OfflineCatalogRepository implements CatalogRepository {
  OfflineCatalogRepository({
    required CatalogRepository remote,
    required AppDatabase cache,
  }) : _remote = remote,
       _cache = cache;

  final CatalogRepository _remote;
  final AppDatabase _cache;

  @override
  Future<List<Song>> trending({int limit = 20}) =>
      _remote.trending(limit: limit);

  @override
  Future<List<Song>> listSongs({String? instrumentSlug, int limit = 50}) =>
      _remote.listSongs(instrumentSlug: instrumentSlug, limit: limit);

  @override
  Future<List<Song>> search(String query) => _remote.search(query);

  @override
  Future<SongWithTabs?> getSong(String id) async {
    try {
      final fresh = await _remote.getSong(id);
      if (fresh != null) {
        // Write-through: cache the fresh copy and record the view so it counts
        // toward the LRU window (favorites are protected from eviction).
        await _cache.cacheSong(fresh);
        await _cache.recordView(id);
      }
      return fresh;
    } catch (_) {
      // Offline / remote error: serve the cached copy if we have one.
      final cached = await _cache.cachedSong(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Instrument>> instruments() => _remote.instruments();
}
