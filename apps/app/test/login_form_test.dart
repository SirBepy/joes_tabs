import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/auth/google_sign_in_flow.dart';
import 'package:joes_tabs_app/screens/login_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records sign-in calls; can be told to throw an [AuthException] to exercise
/// the error path. Never touches a real Supabase client.
class MockAuthService implements AuthService {
  String? signInEmail;
  String? signInPassword;
  bool throwOnSignIn = false;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInEmail = email;
    signInPassword = password;
    if (throwOnSignIn) {
      throw const AuthException('Invalid login credentials');
    }
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogleIdToken({required String idToken}) =>
      throw UnimplementedError();

  @override
  Future<bool> signInWithGoogleRedirect({String? redirectTo}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  String? get currentEmail => null;
}

/// Stands in for the platform Google flow; returns a fixed [result]. Set
/// [error] to make the flow throw, or [gate] to hold the call in flight until
/// the test completes it.
class FakeGoogleSignInFlow implements GoogleSignInFlow {
  FakeGoogleSignInFlow(this.result, {this.error, this.gate});

  final GoogleSignInResult result;
  final Object? error;
  final Completer<void>? gate;
  int calls = 0;

  @override
  Future<GoogleSignInResult> signIn() async {
    calls++;
    await gate?.future;
    if (error != null) throw error!;
    return result;
  }
}

/// Test-controlled auth user. [currentUserProvider] is a plain Provider, so
/// the listener tests feed it from this notifier and flip it mid-test.
final testUserSource = StateProvider<User?>((_) => null);

final testUser = User(
  id: 'user-1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

/// Overrides [currentUserProvider] so it follows [testUserSource].
final followTestUserOverride = currentUserProvider.overrideWith(
  (ref) => ref.watch(testUserSource),
);

Future<GoRouter> _pump(
  WidgetTester tester,
  MockAuthService auth, {
  FakeGoogleSignInFlow? google,
  List<Override> extraOverrides = const [],
}) async {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const Scaffold(body: Text('REGISTER')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
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
  testWidgets('blocks submit and shows validation errors on empty fields', (
    tester,
  ) async {
    final auth = MockAuthService();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
    // Auth service never called when validation fails.
    expect(auth.signInEmail, isNull);
  });

  testWidgets('valid credentials call signIn and route to home', (
    tester,
  ) async {
    final auth = MockAuthService();
    final router = await _pump(tester, auth);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'joe@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(auth.signInEmail, 'joe@example.com');
    expect(auth.signInPassword, 'secret123');
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('surfaces a friendly error when sign-in fails', (tester) async {
    final auth = MockAuthService()..throwOnSignIn = true;
    final router = await _pump(tester, auth);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'joe@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('Invalid login credentials'), findsOneWidget);
    // Stayed on the login screen.
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('hides the Google button when Google sign-in is unavailable', (
    tester,
  ) async {
    await _pump(tester, MockAuthService());

    expect(find.byKey(const Key('google-sign-in')), findsNothing);
  });

  testWidgets('Google sign-in routes to home once signed in', (tester) async {
    final google = FakeGoogleSignInFlow(GoogleSignInResult.signedIn);
    final router = await _pump(tester, MockAuthService(), google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(google.calls, 1);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });

  testWidgets('cancelling the Google picker stays on login', (tester) async {
    final google = FakeGoogleSignInFlow(GoogleSignInResult.cancelled);
    final router = await _pump(tester, MockAuthService(), google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.byKey(const Key('login-error')), findsNothing);
  });

  testWidgets('shows the AuthException message when Google sign-in fails', (
    tester,
  ) async {
    final google = FakeGoogleSignInFlow(
      GoogleSignInResult.cancelled,
      error: const AuthException('Provider is not enabled'),
    );
    final router = await _pump(tester, MockAuthService(), google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(find.text('Provider is not enabled'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('shows a generic message when Google sign-in throws', (
    tester,
  ) async {
    final google = FakeGoogleSignInFlow(
      GoogleSignInResult.cancelled,
      error: StateError('platform channel blew up'),
    );
    final router = await _pump(tester, MockAuthService(), google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();

    expect(
      find.text('Google sign-in failed. Please try again.'),
      findsOneWidget,
    );
    // The raw exception text must not leak into the UI.
    expect(find.textContaining('platform channel'), findsNothing);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('Google button is disabled and busy while sign-in is in flight', (
    tester,
  ) async {
    final gate = Completer<void>();
    final google = FakeGoogleSignInFlow(
      GoogleSignInResult.signedIn,
      gate: gate,
    );
    await _pump(tester, MockAuthService(), google: google);

    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pump();

    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('google-sign-in')),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // A second tap while busy must not start another sign-in.
    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pump();
    expect(google.calls, 1);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a user appearing after a redirect return routes Login to home', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      MockAuthService(),
      extraOverrides: [followTestUserOverride],
    );
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');

    ProviderScope.containerOf(
      tester.element(find.byType(LoginScreen)),
    ).read(testUserSource.notifier).state = testUser;
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(find.text('HOME'), findsOneWidget);
  });
}
