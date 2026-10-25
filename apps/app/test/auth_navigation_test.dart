import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/auth/google_sign_in_flow.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/login_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_form_test.dart';

/// Origin screen with a button that pushes Log In, the way the drawer does.
Future<GoRouter> _pumpFromOrigin(
  WidgetTester tester, {
  FakeGoogleSignInFlow? google,
}) async {
  final router = GoRouter(
    initialLocation: '/origin',
    routes: [
      GoRoute(
        path: '/origin',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push(AppRoutes.login),
            child: const Text('ORIGIN'),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(MockAuthService()),
        if (google != null) ...[
          googleSignInAvailableProvider.overrideWithValue(true),
          googleSignInFlowProvider.overrideWithValue(google),
        ],
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('ORIGIN'));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('a Google failure after backing out of Log In is ignored', (
    tester,
  ) async {
    final gate = Completer<void>();
    final google = FakeGoogleSignInFlow(
      GoogleSignInResult.cancelled,
      error: const AuthException('Provider is not enabled'),
      gate: gate,
    );
    await _pumpFromOrigin(tester, google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(google.calls, 1);
  });
}
