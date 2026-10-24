import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/auth/google_sign_in_flow.dart';
import 'package:joes_tabs_app/screens/register_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_form_test.dart';

Future<GoRouter> _pumpRegister(
  WidgetTester tester, {
  FakeGoogleSignInFlow? google,
  List<Override> extraOverrides = const [],
}) async {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(MockAuthService()),
        ...extraOverrides,
        if (google != null) ...[
          googleSignInAvailableProvider.overrideWithValue(true),
          googleSignInFlowProvider.overrideWithValue(google),
        ],
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Register: Google sign-in routes to home once signed in', (
    tester,
  ) async {
    final google = FakeGoogleSignInFlow(GoogleSignInResult.signedIn);
    final router = await _pumpRegister(tester, google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(google.calls, 1);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });

  testWidgets('Register: cancelling the Google picker stays on register', (
    tester,
  ) async {
    final google = FakeGoogleSignInFlow(GoogleSignInResult.cancelled);
    final router = await _pumpRegister(tester, google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/register');
    expect(find.byKey(const Key('register-error')), findsNothing);
  });

  testWidgets('Register: a Google failure shows in the register error slot', (
    tester,
  ) async {
    final google = FakeGoogleSignInFlow(
      GoogleSignInResult.cancelled,
      error: const AuthException('Provider is not enabled'),
    );
    await _pumpRegister(tester, google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register-error')), findsOneWidget);
    expect(find.text('Provider is not enabled'), findsOneWidget);
  });

  testWidgets('a user appearing after a redirect return routes Register home', (
    tester,
  ) async {
    final router = await _pumpRegister(
      tester,
      extraOverrides: [followTestUserOverride],
    );
    expect(router.routerDelegate.currentConfiguration.uri.path, '/register');

    ProviderScope.containerOf(
      tester.element(find.byType(RegisterScreen)),
    ).read(testUserSource.notifier).state = testUser;
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(find.text('HOME'), findsOneWidget);
  });
}
