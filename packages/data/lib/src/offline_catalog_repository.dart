import 'package:models/models.dart';

import 'catalog_repository.dart';

/// Offline-caching decorator extension point for [CatalogRepository].
///
/// STUB ONLY. Plan 09 completes this with a Drift-backed local cache:
/// read-through (serve cached rows when offline / on error) and write-behind
/// (persist fresh network results). It is intentionally a thin pass-through to
/// [_remote] today so the abstraction and provider override path exist now and
/// nothing else has to change when caching lands.
///
/// Wiring (plan 09) will look like:
/// ```dart
/// final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
///   final remote = SupabaseCatalogRepository(ref.watch(supabaseClientProvider));
///   final cache = ref.watch(catalogCacheProvider); // Drift
///   return OfflineCatalogRepository(remote: remote, cache: cache);
/// });
/// ```
class OfflineCatalogRepository implements CatalogRepository {
  OfflineCatalogRepository({required CatalogRepository remote})
    : _remote = remote;

  final CatalogRepository _remote;

  // TODO(plan-09): inject a Drift cache and implement read-through /
  // write-behind around each call below.

  @override
  Future<List<Song>> trending({int limit = 20}) =>
      _remote.trending(limit: limit);

  @override
  Future<List<Song>> listSongs({String? instrumentSlug, int limit = 50}) =>
      _remote.listSongs(instrumentSlug: instrumentSlug, limit: limit);

  @override
  Future<List<Song>> search(String query) => _remote.search(query);

  @override
  Future<SongWithTabs?> getSong(String id) => _remote.getSong(id);
}
