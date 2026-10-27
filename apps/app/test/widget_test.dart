import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

import 'support/settings_overrides.dart';

/// Pumps the app shell starting at Home (skipping the splash timer) with a
/// ProviderScope seeded with default settings so no live network / Supabase
/// client is needed.
Future<GoRouter> _pumpShell(WidgetTester tester) async {
  final router = buildRouter(initialLocation: AppRoutes.home);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride()],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('app shell renders Home with the search field and no menu', (
    tester,
  ) async {
    await _pumpShell(tester);

    // Anonymous (logged-out) default greeting is the generic 'WELCOME'.
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Search tabs'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsNothing);
    expect(find.byType(Drawer), findsNothing);
  });
}
