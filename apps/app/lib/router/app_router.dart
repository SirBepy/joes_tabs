import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../screens/chords_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
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
import '../widgets/back_to_home_scope.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// A [ShellRoute] wraps the main destinations (Home, Trending, Saved, Chords,
/// Tuner, Settings, Support) in the shared [AppShell] (top app bar + full-screen
/// drawer). Splash, auth, and the song detail view sit outside the shell so they
/// render without the drawer chrome. Every page except Splash and Onboarding
/// sits in a [BackToHomeScope] so system back never closes the app off-Home.
GoRouter buildRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _scoped(state, AppShell(child: child)),
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
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.thankYou,
        builder: (context, state) => _scoped(state, const ThankYouScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => _scoped(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => _scoped(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => _scoped(
          state,
          SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.song,
        builder: (context, state) => _scoped(
          state,
          SongDetailScreen(songId: state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
}

/// Every route except Splash and Onboarding goes through here, so a new page
/// can't forget the scope and let system back close the app.
Widget _scoped(GoRouterState state, Widget child) =>
    BackToHomeScope(location: state.matchedLocation, child: child);
