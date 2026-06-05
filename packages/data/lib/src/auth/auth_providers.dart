import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers.dart';
import 'account_favorites_repository.dart';
import 'auth_service.dart';

/// The app's [AuthService], built from the live [SupabaseClient].
///
/// Like [supabaseClientProvider] this resolves only once the client has been
/// wired at the root `ProviderScope`. Widget tests that never sign in read
/// [currentUserProvider] instead (which defaults to logged-out) and so never
/// force this provider to build.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Account favorites repository for the first-sign-in sync.
final accountFavoritesRepositoryProvider = Provider<AccountFavoritesRepository>(
  (ref) {
    return AccountFavoritesRepository(ref.watch(supabaseClientProvider));
  },
);

/// The current signed-in [User], or null when anonymous / logged out.
///
/// Default is a const logged-out provider so the app shell, drawer and home
/// greeting render with zero backend in widget tests. `main.dart` overrides
/// this with [authUserStreamProvider] (driven by `onAuthStateChange`) once a
/// live Supabase client exists, so the UI reacts to real sign-in / sign-out.
final currentUserProvider = Provider<User?>((ref) => null);

/// Live stream of the current [User] (or null) derived from Supabase's
/// `onAuthStateChange`. Seeded with the current user so the first frame after a
/// restart already reflects a persisted session.
final authUserStreamProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.onAuthStateChange
      .map((state) => state.session?.user)
      .startWith(auth.currentUser);
});

extension _StartWith<T> on Stream<T> {
  /// Emits [initial] immediately, then every event of the source stream. Keeps
  /// the greeting/drawer correct on the very first frame (before the auth SDK
  /// has emitted its initial event).
  Stream<T> startWith(T initial) async* {
    yield initial;
    yield* this;
  }
}
