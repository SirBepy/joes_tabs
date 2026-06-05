import 'account_favorites_repository.dart';

/// Best-effort write-through sink for mirroring local favorite toggles to the
/// signed-in user's `user_favorites` account rows.
///
/// The favorites notifier owns the local Drift store (the instant, always-on
/// source of truth) and calls this sink AFTER every local mutation. The sink
/// decides, based on the current auth state, whether to also write the change
/// to the account:
///   * signed in  -> upsert/delete the row in `user_favorites`,
///   * signed out / no backend -> no-op (anonymous favorites stay local-only).
///
/// Writes are best-effort: a failure here must never break the local toggle, so
/// the notifier swallows/logs errors. Kept Riverpod- and Supabase-free so it is
/// trivially fakeable in tests.
abstract class AccountFavoritesSink {
  /// Mirror a local "add favorite" to the account when signed in.
  Future<void> add(String songId);

  /// Mirror a local "remove favorite" to the account when signed in.
  Future<void> remove(String songId);
}

/// The production [AccountFavoritesSink].
///
/// Reads the current signed-in state lazily via [isSignedIn] (a callback so the
/// sink always sees the latest auth state without holding a stale snapshot) and,
/// when signed in, forwards the write to the [AccountFavoritesRepository]. When
/// signed out it short-circuits, so anonymous toggles never hit the network.
class LiveAccountFavoritesSink implements AccountFavoritesSink {
  LiveAccountFavoritesSink({
    required AccountFavoritesRepository repository,
    required bool Function() isSignedIn,
  }) : _repository = repository,
       _isSignedIn = isSignedIn;

  final AccountFavoritesRepository _repository;
  final bool Function() _isSignedIn;

  @override
  Future<void> add(String songId) async {
    if (!_isSignedIn()) return;
    await _repository.pushFavoriteIds([songId]);
  }

  @override
  Future<void> remove(String songId) async {
    if (!_isSignedIn()) return;
    await _repository.removeFavoriteId(songId);
  }
}
