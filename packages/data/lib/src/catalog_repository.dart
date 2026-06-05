import 'package:models/models.dart';

/// Read-only catalog access for the public (anon) catalog of songs and tabs.
///
/// This is the abstraction the app's Riverpod providers depend on. A network
/// implementation ([SupabaseCatalogRepository]) backs it today; plan 09 adds an
/// offline-caching decorator that wraps another [CatalogRepository] without the
/// app needing to change.
abstract class CatalogRepository {
  /// Songs to surface on the home/trending view, most-recent first.
  ///
  /// [limit] caps the number of rows returned.
  Future<List<Song>> trending({int limit = 20});

  /// All catalog songs, optionally filtered to those that have at least one
  /// published tab for the instrument with the given [instrumentSlug]
  /// (e.g. `ukulele`, `guitar`). When [instrumentSlug] is null, no instrument
  /// filter is applied.
  Future<List<Song>> listSongs({String? instrumentSlug, int limit = 50});

  /// Full-text search over title + artist via the `search_songs` RPC.
  ///
  /// An empty/blank [query] returns the default catalog ordering (handled
  /// server-side by the RPC).
  Future<List<Song>> search(String query);

  /// A single song with its published tabs, or null if the id is unknown or
  /// not publicly visible.
  Future<SongWithTabs?> getSong(String id);
}

/// Thrown when a catalog backend call fails (network, RLS, decode). Wraps the
/// underlying [cause] so the UI layer can show a single error type.
class CatalogException implements Exception {
  const CatalogException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'CatalogException: $message${cause == null ? '' : ' ($cause)'}';
}
