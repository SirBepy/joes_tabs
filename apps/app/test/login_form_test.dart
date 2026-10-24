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

/// Stands in for the platform Google flow; returns a fixed [result].
class FakeGoogleSignInFlow implements GoogleSignInFlow {
  FakeGoogleSignInFlow(this.result);

  final GoogleSignInResult result;
  int calls = 0;

  @override
  Future<GoogleSignInResult> signIn() async {
    calls++;
    return result;
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  MockAuthService auth, {
  FakeGoogleSignInFlow? google,
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
}
