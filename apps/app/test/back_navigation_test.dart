import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

import 'support/settings_overrides.dart';

/// Pumps the real router at [initialLocation] with zero backend.
Future<GoRouter> _pumpApp(
  WidgetTester tester,
  String initialLocation, {
  bool onboardingComplete = true,
}) async {
  final db = inMemoryAppDatabase();
  addTearDown(db.close);
  final router = buildRouter(initialLocation: initialLocation);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseOverride(db),
        initialSettingsOverride(
          onboardingComplete: onboardingComplete,
          instrumentSlugs: const [],
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Simulates the Android system back button.
Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Location of the top page; `uri` alone ignores imperatively pushed pages.
String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('back on a drawer destination returns to Home', (tester) async {
    final router = await _pumpApp(tester, AppRoutes.settings);

    await _pressBack(tester);

    expect(_path(router), AppRoutes.home);
  });

  testWidgets('back on Login opened from Home returns to Home', (tester) async {
    final router = await _pumpApp(tester, AppRoutes.home);
    router.push(AppRoutes.login);
    await tester.pumpAndSettle();

    await _pressBack(tester);

    expect(_path(router), AppRoutes.home);
  });

  testWidgets('back from Register opened via Login returns to Login', (
    tester,
  ) async {
    final router = await _pumpApp(tester, AppRoutes.home);
    router.push(AppRoutes.login);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('No account? Create one'));
    await tester.tap(find.text('No account? Create one'));
    await tester.pumpAndSettle();
    expect(_path(router), AppRoutes.register);

    await _pressBack(tester);

    expect(_path(router), AppRoutes.login);
  });

  testWidgets('back on a page reached with nothing beneath goes Home', (
    tester,
  ) async {
    final router = await _pumpApp(tester, AppRoutes.login);

    await _pressBack(tester);

    expect(_path(router), AppRoutes.home);
  });

  for (final location in [AppRoutes.search, AppRoutes.thankYou]) {
    testWidgets('back on $location reached with nothing beneath goes Home', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location);

      await _pressBack(tester);

      expect(_path(router), AppRoutes.home);
    });
  }

  testWidgets('back on an onboarding step returns to the previous step', (
    tester,
  ) async {
    final router = await _pumpApp(
      tester,
      AppRoutes.onboarding,
      onboardingComplete: false,
    );
    await tester.tap(find.byKey(const Key('onboarding-get-started')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-get-started')), findsNothing);

    await _pressBack(tester);

    expect(_path(router), AppRoutes.onboarding);
    expect(find.byKey(const Key('onboarding-get-started')), findsOneWidget);
  });

  for (final (label, route) in [
    ('Log In', AppRoutes.login),
    ('Register', AppRoutes.register),
  ]) {
    testWidgets('back on $label opened from the drawer returns to the page', (
      tester,
    ) async {
      final router = await _pumpApp(tester, AppRoutes.trending);
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(_path(router), route);

      await _pressBack(tester);

      // Trending (one of the two drawer hosts) is the origin: back must land
      // there, not on Home. A route swap instead of a push would fall through
      // to the Home fallback.
      expect(_path(router), AppRoutes.trending);
    });
  }
}
