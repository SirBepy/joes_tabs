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
import '../widgets/tab_scroll.dart';
import 'app_routes.dart';
import 'app_tabs.dart';

/// Builds the app's [GoRouter].
///
/// A [StatefulShellRoute] hosts the five bottom-bar tabs (see [appTabs] for the
/// branch order) in the shared [AppShell], so each tab keeps its own stack and
/// scroll position. Trending and Support Us are pushed pages inside the Home and
/// Settings branches, which keeps the bar visible on them. Splash, auth, search
/// and the song view sit outside the shell as full-screen pages; every one of
/// them except Splash and Onboarding is in a [BackToHomeScope] so system back
/// never closes the app from a page with nothing beneath it.
GoRouter buildRouter({String initialLocation = AppRoutes.splash}) {
  final scroll = TabScrollRegistry();

  // Wraps a tab's root screen so the shell can scroll it to the top.
  Widget tabRoot(String route, Widget screen) {
    final branch = appTabs.indexWhere((t) => t.route == route);
    return TabScrollScope(
      controller: scroll.controllerFor(branch),
      child: screen,
    );
  }

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell, scroll: scroll),
        // Order must match [appTabs].
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tuner,
                builder: (context, state) =>
                    tabRoot(AppRoutes.tuner, const TunerScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chords,
                builder: (context, state) =>
                    tabRoot(AppRoutes.chords, const ChordsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) =>
                    tabRoot(AppRoutes.home, const HomeScreen()),
                routes: [
                  // Nested so `go('/trending')` stacks it on Home and back pops
                  // to Home; the URL stays `/trending`.
                  GoRoute(
                    path: AppRoutes.trending.substring(1),
                    builder: (context, state) => const TrendingScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                builder: (context, state) =>
                    tabRoot(AppRoutes.saved, const SavedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) =>
                    tabRoot(AppRoutes.settings, const SettingsScreen()),
              ),
              // A sibling rather than a child so the path stays `/support`.
              // `push` from Settings stacks it on top of Settings.
              GoRoute(
                path: AppRoutes.support,
                builder: (context, state) => const SupportScreen(),
              ),
            ],
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

/// Every full-screen page outside the shell goes through here, so a new page
/// can't forget the scope and let system back close the app. The shell handles
/// its own back behaviour.
Widget _scoped(GoRouterState state, Widget child) =>
    BackToHomeScope(location: state.matchedLocation, child: child);
