import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_repository.dart';
import 'drift/app_database.dart';
import 'offline_catalog_repository.dart';
import 'supabase_catalog_repository.dart';

/// Exposes the initialized [SupabaseClient] to the Riverpod graph.
///
/// Manual providers are used (not riverpod_generator) to stay on the Riverpod 2
/// line, which resolves cleanly on this Dart 3.10 / analyzer 8 SDK.
///
/// This base provider throws by default; the app must override it at the root
/// `ProviderScope` after calling `initSupabase()`:
/// ```dart
/// final client = await initSupabase();
/// runApp(ProviderScope(
///   overrides: [supabaseClientProvider.overrideWithValue(client)],
///   child: const App(),
/// ));
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw UnimplementedError(
    'supabaseClientProvider must be overridden at the root ProviderScope '
    'with the client returned by initSupabase().',
  );
});

/// The Drift offline cache (cached songs/tabs, favorites, recent-views LRU).
///
/// Opened once per app run and disposed with the provider container. On native
/// platforms this is a file-backed sqlite database; on web it falls back to an
/// in-memory database (see drift/connection/connection_web.dart).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The Supabase-backed remote catalog repository (network source of truth).
final remoteCatalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCatalogRepository(client);
});

/// The catalog repository the UI depends on: the Supabase remote wrapped in the
/// offline-caching decorator so opened songs survive offline (spec section 5).
/// Consumers are unchanged - they still watch [catalogRepositoryProvider].
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final remote = ref.watch(remoteCatalogRepositoryProvider);
  final cache = ref.watch(appDatabaseProvider);
  return OfflineCatalogRepository(remote: remote, cache: cache);
});

/// Stream of persisted favorite song ids (newest first) from the Drift cache.
/// Backs the app's persistent favorites store and the Saved screen.
final favoriteIdsStreamProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(appDatabaseProvider).watchFavoriteIds();
});

/// Trending songs for the home view.
final trendingProvider = FutureProvider<List<Song>>((ref) {
  return ref.watch(catalogRepositoryProvider).trending();
});

/// Catalog songs, optionally filtered by instrument slug (null = all).
final songsByInstrumentProvider = FutureProvider.family<List<Song>, String?>((
  ref,
  instrumentSlug,
) {
  return ref
      .watch(catalogRepositoryProvider)
      .listSongs(instrumentSlug: instrumentSlug);
});

/// Full-text search results for [query] (blank = default catalog order).
final searchProvider = FutureProvider.family<List<Song>, String>((ref, query) {
  return ref.watch(catalogRepositoryProvider).search(query);
});

/// Search query plus an optional instrument-slug filter (null = all/both).
/// A record so the [searchFilteredProvider] family keys on both values with
/// structural equality (no extra equatable boilerplate).
typedef SearchArgs = ({String query, String? instrumentSlug});

/// Full-text search results for [SearchArgs.query], narrowed to songs that
/// have a published tab for [SearchArgs.instrumentSlug] (null = no filter).
final searchFilteredProvider = FutureProvider.family<List<Song>, SearchArgs>((
  ref,
  args,
) {
  return ref
      .watch(catalogRepositoryProvider)
      .searchSongs(args.query, instrumentSlug: args.instrumentSlug);
});

/// A single song with its published tabs, or null if not found/visible.
final songProvider = FutureProvider.family<SongWithTabs?, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).getSong(id);
});

/// The instrument lookup table, keyed by instrument id, for mapping a tab's
/// `instrumentId` to its slug / string count in the UI.
final instrumentsByIdProvider = FutureProvider<Map<String, Instrument>>((
  ref,
) async {
  final list = await ref.watch(catalogRepositoryProvider).instruments();
  return {for (final i in list) i.id: i};
});
