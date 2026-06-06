import 'package:data/data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router/app_router.dart';
import 'state/favorites_provider.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use clean path-based URLs on web (e.g. /song/<id>) instead of hash routing,
  // so song links are shareable and reload correctly. No-op on other platforms.
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize Supabase from --dart-define config. If the env is missing (or
  // init fails), still launch the app so the shell is navigable, just without a
  // live backend, and surface a small banner.
  SupabaseClient? client;
  String? initError;
  try {
    client = await initSupabase();
  } catch (e) {
    initError = e.toString();
  }

  // Open the offline cache (plan 09) and seed the persistent favorites store
  // with whatever is already on disk so the Saved screen is populated on first
  // frame. On web this is in-memory (see data/.../connection_web.dart); if it
  // throws for any reason we fall back to the in-memory favorites store so the
  // app still launches.
  final db = AppDatabase();
  Set<String> initialFavorites = const <String>{};
  try {
    initialFavorites = (await db.favoriteIds()).toSet();
  } catch (_) {
    // Cache unavailable: app still runs with non-persistent favorites.
  }

  // Read persisted preferences (theme, instruments, font size) before the first
  // frame so the providers hydrate from disk. If the read fails, fall back to
  // safe in-memory defaults (system theme, both instruments, font 20) and let
  // persistence resume on the next successful write - never block launch on IO.
  final settingsRepository = AppSettingsRepository(db);
  AppSettingsRecord initialSettings = const AppSettingsRecord(
    onboardingComplete: false,
    themeMode: 'system',
    instrumentSlugs: [ChordShapes.ukulele, ChordShapes.guitar],
    fontSize: 20,
  );
  try {
    initialSettings = await settingsRepository.read();
  } catch (_) {
    // Settings IO unavailable: app still runs with in-memory defaults.
  }

  runApp(
    ProviderScope(
      overrides: [
        if (client != null) supabaseClientProvider.overrideWithValue(client),
        appDatabaseProvider.overrideWithValue(db),
        // Seed the persisted-preferences providers with the row read above, so
        // theme / instruments / font size hydrate from disk on first frame.
        initialAppSettingsProvider.overrideWithValue(initialSettings),
        favoritesProvider.overrideWith(
          (ref) => DriftFavoritesNotifier(
            db,
            initial: initialFavorites,
            // With a live backend, mirror every toggle to the signed-in user's
            // account in real time (ai_todo 005). The sink reads the latest
            // auth state on each write via `currentUserProvider`, so it writes
            // only while signed in and no-ops while anonymous. Without a client
            // there is no sink, so favorites stay local-only.
            accountSink: client == null
                ? null
                : LiveAccountFavoritesSink(
                    repository: ref.read(accountFavoritesRepositoryProvider),
                    isSignedIn: () => ref.read(currentUserProvider) != null,
                  ),
          ),
        ),
        // With a live client, the current user is driven by Supabase's auth
        // stream so the greeting + drawer react to real sign-in / sign-out.
        // Without one (e.g. missing dart-defines) the default logged-out
        // provider keeps the app fully navigable in anonymous mode.
        if (client != null)
          currentUserProvider.overrideWith(
            (ref) => ref.watch(authUserStreamProvider).valueOrNull,
          ),
      ],
      child: JoesTabsApp(initError: initError, hasBackend: client != null),
    ),
  );
}

/// Root app widget: themed [MaterialApp.router] driven by the go_router config.
///
/// A [ConsumerStatefulWidget] so it can (a) build the [GoRouter] EXACTLY ONCE and
/// hold it in state, and (b) listen to [currentUserProvider] to run the first
/// sign-in favorites merge. Building the router once is load-bearing: if it were
/// rebuilt on every build (e.g. when the dark-mode toggle changes the watched
/// theme), a fresh GoRouter would reset navigation to its initial location
/// (splash), kicking the user off whatever screen they were on.
class JoesTabsApp extends ConsumerStatefulWidget {
  const JoesTabsApp({super.key, this.initError, this.hasBackend = false});

  /// Non-null when Supabase failed to initialize (e.g. missing dart-defines).
  final String? initError;

  /// Whether a live Supabase client is wired (auth + account sync available).
  final bool hasBackend;

  @override
  ConsumerState<JoesTabsApp> createState() => _JoesTabsAppState();
}

class _JoesTabsAppState extends ConsumerState<JoesTabsApp> {
  // Built once for the lifetime of the app so theme/auth rebuilds never reset
  // the navigation stack.
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final initError = widget.initError;
    if (widget.hasBackend) {
      // Run the account favorites sync on every transition into a signed-in
      // state (sign-in / restored session). Idempotent, so re-runs are safe.
      ref.listen<User?>(currentUserProvider, (previous, next) {
        if (previous?.id != next?.id && next != null) {
          final sync = FavoritesAccountSync(
            ref.read(appDatabaseProvider),
            ref.read(accountFavoritesRepositoryProvider),
          );
          sync.run().catchError((Object e) {
            debugPrint('Favorites account sync failed: $e');
            return const <String>{};
          });
        }
      });
    }
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: "Joe's Tabs",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) {
        if (initError == null) return child ?? const SizedBox.shrink();
        // Backend unavailable: show a thin banner above the app content.
        return Column(
          children: [
            Material(
              color: Colors.red.shade700,
              child: SafeArea(
                bottom: false,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Backend not configured: running without Supabase.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
