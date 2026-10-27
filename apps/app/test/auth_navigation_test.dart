import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/auth/google_sign_in_flow.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/login_screen.dart';
import 'package:joes_tabs_app/screens/register_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_form_test.dart';

/// Origin screen with a button that pushes Log In, the way the drawer does.
Future<GoRouter> _pumpFromOrigin(
  WidgetTester tester, {
  GoogleSignInFlow? google,
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
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
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

/// Location of the top page; `uri` alone ignores imperatively pushed pages.
String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('toggling Log In / Register never stacks auth screens', (
    tester,
  ) async {
    final router = await _pumpFromOrigin(tester);

    await tester.tap(find.text('No account? Create one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No account? Create one'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    // Only the Log In that opened this Register sits beneath it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_path(router), '/login');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_path(router), '/origin');
    expect(find.text('ORIGIN'), findsOneWidget);
  });

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

  const hint = 'Sign-in did not complete. Try again or use email.';

  testWidgets('a cancelled Google sign-in shows a quiet hint on Log In', (
    tester,
  ) async {
    await _pumpFromOrigin(
      tester,
      google: FakeGoogleSignInFlow(GoogleSignInResult.cancelled),
    );
    expect(find.text(hint), findsNothing);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(find.text(hint), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a cancelled Google sign-in shows the hint on Register', (
    tester,
  ) async {
    await _pumpFromOrigin(
      tester,
      google: FakeGoogleSignInFlow(GoogleSignInResult.cancelled),
    );
    await tester.tap(find.text('No account? Create one'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('a signed-in Google result shows no hint', (tester) async {
    await _pumpFromOrigin(
      tester,
      google: FakeGoogleSignInFlow(GoogleSignInResult.signedIn),
    );

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(find.text(hint), findsNothing);
  });

  testWidgets('tapping Google again clears the hint', (tester) async {
    final gate = Completer<void>();
    final google = _SequencedGoogleFlow([
      GoogleSignInResult.cancelled,
      GoogleSignInResult.signedIn,
    ], secondGate: gate);
    await _pumpFromOrigin(tester, google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();
    expect(find.text(hint), findsOneWidget);

    // Second attempt is held open so the cleared state is observable.
    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pump();
    expect(find.text(hint), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(hint), findsNothing);
  });
}

/// Returns [results] in order; the second call waits on [secondGate].
class _SequencedGoogleFlow implements GoogleSignInFlow {
  _SequencedGoogleFlow(this.results, {this.secondGate});

  final List<GoogleSignInResult> results;
  final Completer<void>? secondGate;
  int _calls = 0;

  @override
  Future<GoogleSignInResult> signIn() async {
    final index = _calls++;
    if (index == 1) await secondGate?.future;
    return results[index];
  }
}
