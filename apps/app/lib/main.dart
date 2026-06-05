import 'package:data/data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router/app_router.dart';
import 'state/favorites_provider.dart';
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

  runApp(
    ProviderScope(
      overrides: [
        if (client != null) supabaseClientProvider.overrideWithValue(client),
        appDatabaseProvider.overrideWithValue(db),
        favoritesProvider.overrideWith(
          (ref) => DriftFavoritesNotifier(db, initial: initialFavorites),
        ),
      ],
      child: JoesTabsApp(initError: initError),
    ),
  );
}

/// Root app widget: themed [MaterialApp.router] driven by the go_router config.
class JoesTabsApp extends StatelessWidget {
  const JoesTabsApp({super.key, this.initError});

  /// Non-null when Supabase failed to initialize (e.g. missing dart-defines).
  final String? initError;

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();
    return MaterialApp.router(
      title: "Joe's Tabs",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
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
