/// Data layer for Joes Tabs: Supabase client wiring, the catalog repository,
/// and the Riverpod providers the app consumes.
///
/// Cache integration (Drift) is stubbed here via [OfflineCatalogRepository] and
/// completed in plan 09.
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
export 'src/env.dart';
export 'src/mappers.dart';
export 'src/offline_catalog_repository.dart';
export 'src/providers.dart';
export 'src/supabase_catalog_repository.dart';
export 'src/supabase_init.dart';
