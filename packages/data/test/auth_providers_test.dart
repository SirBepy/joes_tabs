import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String id, String email) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: email,
  createdAt: DateTime.utc(2026).toIso8601String(),
);

/// Fake AuthService driving a controllable [onAuthStateChange] stream so the
/// stream-derived providers can be tested without a live Supabase backend.
class FakeAuthService implements AuthService {
  // Single-subscription controller buffers events until the provider's stream
  // subscription is live, so a synchronously-emitted sign-in is never dropped
  // (a broadcast controller would drop events emitted before the listener
  // attaches).
  final _controller = StreamController<AuthState>();
  User? _current;

  void emitSignedIn(User user) {
    _current = user;
    _controller.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(accessToken: 't', tokenType: 'bearer', user: user),
      ),
    );
  }

  void emitSignedOut() {
    _current = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  User? get currentUser => _current;

  @override
  String? get currentEmail => _current?.email;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async => emitSignedOut();

  void dispose() => _controller.close();
}

void main() {
  test('currentUserProvider defaults to logged-out (null)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(currentUserProvider), isNull);
  });

  test('currentUserProvider can be overridden to a signed-in user', () {
    final user = _user('u1', 'joe@example.com');
    final container = ProviderContainer(
      overrides: [currentUserProvider.overrideWithValue(user)],
    );
    addTearDown(container.dispose);

    final read = container.read(currentUserProvider);
    expect(read, isNotNull);
    expect(read!.email, 'joe@example.com');
  });

  test('authUserStreamProvider reflects sign-in then sign-out', () async {
    final fake = FakeAuthService();
    addTearDown(fake.dispose);
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    // Capture every emitted user (or null) so the assertions are timing-robust.
    final emitted = <String?>[];
    final sub = container.listen<AsyncValue<User?>>(authUserStreamProvider, (
      _,
      next,
    ) {
      if (next.hasValue) emitted.add(next.value?.email);
    }, fireImmediately: true);
    addTearDown(sub.close);

    // Seed: starts logged out.
    await container.read(authUserStreamProvider.future);
    expect(container.read(authUserStreamProvider).valueOrNull, isNull);

    // Sign in -> user surfaces.
    fake.emitSignedIn(_user('u1', 'joe@example.com'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Sign out -> back to null.
    fake.emitSignedOut();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(emitted, contains('joe@example.com'));
    expect(emitted.last, isNull);
    expect(container.read(authUserStreamProvider).valueOrNull, isNull);
  });
}
