import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_repository.dart';
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

/// The catalog repository the UI depends on. Today this is the Supabase-backed
/// implementation; plan 09 can override it with an offline-caching decorator
/// (see [OfflineCatalogRepository]) without changing any consumer.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCatalogRepository(client);
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
