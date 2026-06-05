import 'package:go_router/go_router.dart';

import '../screens/chords_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/song_detail_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/support_screen.dart';
import '../screens/thank_you_screen.dart';
import '../screens/trending_screen.dart';
import '../screens/tuner_screen.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// A [ShellRoute] wraps the main destinations (Home, Trending, Saved, Chords,
/// Tuner, Settings, Support) in the shared [AppShell] (top app bar + full-screen
/// drawer). Splash, auth, and the song detail view sit outside the shell so they
/// render without the drawer chrome.
GoRouter buildRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.trending,
            builder: (context, state) => const TrendingScreen(),
          ),
          GoRoute(
            path: AppRoutes.saved,
            builder: (context, state) => const SavedScreen(),
          ),
          GoRoute(
            path: AppRoutes.chords,
            builder: (context, state) => const ChordsScreen(),
          ),
          GoRoute(
            path: AppRoutes.tuner,
            builder: (context, state) => const TunerScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.support,
            builder: (context, state) => const SupportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.thankYou,
        builder: (context, state) => const ThankYouScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) =>
            SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.song,
        builder: (context, state) =>
            SongDetailScreen(songId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
}
