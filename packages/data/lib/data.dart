/// Data layer for Joes Tabs: Supabase client wiring, the catalog repository,
/// and the Riverpod providers the app consumes.
///
/// Offline caching (plan 09) is implemented via the Drift [AppDatabase] and the
/// [OfflineCatalogRepository] decorator wired in [catalogRepositoryProvider].
///
/// Startup:
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// final client = await initSupabase(); // reads --dart-define config
/// runApp(ProviderScope(
///   overrides: [supabaseClientProvider.overrideWithValue(client)],
///   child: const App(),
/// ));
/// ```
library;

export 'src/catalog_repository.dart';
// Expose the Drift cache type (AppDatabase) + companions so the app can wire a
// persistent favorites store. Generated row classes come along via the part.
export 'src/drift/app_database.dart';
export 'src/env.dart';
export 'src/mappers.dart';
export 'src/offline_catalog_repository.dart';
export 'src/providers.dart';
export 'src/supabase_catalog_repository.dart';
export 'src/supabase_init.dart';
