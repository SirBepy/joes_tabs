import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

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
        initialSettingsOverride(
          onboardingComplete: onboardingComplete,
          // Start empty so the onboarding instrument step requires a choice.
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

  group('onboarding instrument step', () {
    testWidgets(
      'Continue is disabled at zero selected and enabled after a pick, '
      'and commits the selection to instrumentsProvider',
      (tester) async {
        final db = inMemoryAppDatabase();
        addTearDown(db.close);
        late WidgetRef capturedRef;

        final router = buildRouter(initialLocation: AppRoutes.onboarding);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseOverride(db),
              initialSettingsOverride(
                onboardingComplete: false,
                instrumentSlugs: const [],
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return MaterialApp.router(
                  theme: AppTheme.light,
                  routerConfig: router,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Advance off the Welcome step to the instrument step.
        await tester.tap(find.byKey(const Key('onboarding-get-started')));
        await tester.pumpAndSettle();

        // Zero selected: Continue is disabled.
        final continueButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('onboarding-instrument-continue')),
        );
        expect(continueButton.onPressed, isNull);

        // Pick guitar: Continue becomes enabled.
        await tester.tap(find.byKey(const Key('onboarding-instrument-guitar')));
        await tester.pumpAndSettle();
        final enabledButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('onboarding-instrument-continue')),
        );
        expect(enabledButton.onPressed, isNotNull);

        // Continue commits the selection to the persisted provider.
        await tester.tap(
          find.byKey(const Key('onboarding-instrument-continue')),
        );
        await tester.pumpAndSettle();
        expect(capturedRef.read(instrumentsProvider), {ChordShapes.guitar});
        final record = await AppSettingsRepository(db).read();
        expect(record.instrumentSlugs, [ChordShapes.guitar]);
      },
    );
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

      // Advance off the Welcome step, then through the instrument step.
      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-instrument-ukulele')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-instrument-continue')));
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
      await tester.tap(find.byKey(const Key('onboarding-instrument-ukulele')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-instrument-continue')));
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
      await tester.tap(find.byKey(const Key('onboarding-instrument-ukulele')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-instrument-continue')));
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
