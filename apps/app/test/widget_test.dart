import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/app_drawer.dart';

/// Pumps the app shell starting at Home (skipping the splash timer) with an
/// empty ProviderScope so no live network / Supabase client is needed.
Future<GoRouter> _pumpShell(WidgetTester tester) async {
  final router = buildRouter(initialLocation: AppRoutes.home);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('app shell renders Home with the menu button', (tester) async {
    await _pumpShell(tester);

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
  });

  testWidgets('drawer opens and lists every destination', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    for (final d in AppDrawer.destinations) {
      expect(find.text(d.label), findsOneWidget);
    }
    // Support Us lives at the bottom of the drawer's scrollable list; scroll
    // it in. Target the drawer's own Scrollable (the Home body also scrolls).
    final drawerScrollable = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Support Us'),
      200,
      scrollable: drawerScrollable,
    );
    expect(find.text('Support Us'), findsOneWidget);
    // Account links sit in the fixed bottom row.
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('tapping a destination navigates and closes the drawer', (
    tester,
  ) async {
    final router = await _pumpShell(tester);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tuner'));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.tuner,
    );
    // Tuner placeholder body is shown.
    expect(find.text('Tuner'), findsOneWidget);
    // Drawer destinations are no longer visible (drawer closed).
    expect(find.text('Saved Tabs'), findsNothing);
  });
}
