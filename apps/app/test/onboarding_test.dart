import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

import 'support/settings_overrides.dart';

/// Pumps the real router (so splash gating runs) starting at the splash, wired
/// with an in-memory database and a seeded settings record.
Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required bool onboardingComplete,
  required AppDatabase db,
}) async {
  final router = buildRouter(initialLocation: AppRoutes.splash);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseOverride(db),
        // Home's Recently opened is a Drift stream query, which leaves a timer
        // pending past the test; the lists are not under test here.
        recentSongIdsProvider.overrideWith((ref) => Stream.value(const [])),
        initialSettingsOverride(
          onboardingComplete: onboardingComplete,
          instrumentSlugs: const [],
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  // Pump past the 1500ms splash timer.
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('splash routing gates on onboardingComplete', () {
    testWidgets('onboardingComplete=false routes to onboarding', (
      tester,
    ) async {
      final db = inMemoryAppDatabase();
      addTearDown(db.close);
      final router = await _pumpApp(tester, onboardingComplete: false, db: db);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.onboarding,
      );
      expect(find.byKey(const Key('onboarding-pageview')), findsOneWidget);
    });

    testWidgets('onboardingComplete=true routes to home', (tester) async {
      final db = inMemoryAppDatabase();
      addTearDown(db.close);
      final router = await _pumpApp(tester, onboardingComplete: true, db: db);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
    });
  });

  group('onboarding account step', () {
    testWidgets('Skip marks onboardingComplete=true and routes home', (
      tester,
    ) async {
      final db = inMemoryAppDatabase();
      addTearDown(db.close);

      final router = buildRouter(initialLocation: AppRoutes.onboarding);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseOverride(db),
            // Home's Recently opened is a Drift stream query, which leaves a timer
            // pending past the test; the lists are not under test here.
            recentSongIdsProvider.overrideWith((ref) => Stream.value(const [])),
            initialSettingsOverride(
              onboardingComplete: false,
              instrumentSlugs: const [],
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance off the Welcome step to the Account step.
      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();

      // Skip finishes onboarding to home.
      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
      final record = await AppSettingsRepository(db).read();
      expect(record.onboardingComplete, isTrue);
    });

    testWidgets('Sign in marks onboardingComplete=true and routes to login', (
      tester,
    ) async {
      final db = inMemoryAppDatabase();
      addTearDown(db.close);

      final router = buildRouter(initialLocation: AppRoutes.onboarding);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseOverride(db),
            // Home's Recently opened is a Drift stream query, which leaves a timer
            // pending past the test; the lists are not under test here.
            recentSongIdsProvider.overrideWith((ref) => Stream.value(const [])),
            initialSettingsOverride(
              onboardingComplete: false,
              instrumentSlugs: const [],
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-sign-in')));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.login,
      );
      final record = await AppSettingsRepository(db).read();
      expect(record.onboardingComplete, isTrue);
    });

    testWidgets('Create account marks onboardingComplete=true', (tester) async {
      final db = inMemoryAppDatabase();
      addTearDown(db.close);

      final router = buildRouter(initialLocation: AppRoutes.onboarding);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseOverride(db),
            // Home's Recently opened is a Drift stream query, which leaves a timer
            // pending past the test; the lists are not under test here.
            recentSongIdsProvider.overrideWith((ref) => Stream.value(const [])),
            initialSettingsOverride(
              onboardingComplete: false,
              instrumentSlugs: const [],
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-create-account')));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.register,
      );
      final record = await AppSettingsRepository(db).read();
      expect(record.onboardingComplete, isTrue);
    });
  });
}
