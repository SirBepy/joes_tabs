import '../drift/app_database.dart';
import 'account_favorites_repository.dart';
import 'favorites_merge.dart';

/// Runs the first-sign-in favorites merge between the local Drift store and the
/// signed-in user's account (spec section 5).
///
/// Pragmatic and idempotent (re-running is safe and a no-op once converged):
///   * push local-only ids up to `user_favorites`,
///   * pull account-only ids down into the local Drift favorites,
/// leaving the union present in both places. Continuous write-through (live
/// mirroring of each toggle while signed in) is handled separately by
/// [AccountFavoritesSink] in the favorites notifier; this merge converges the
/// two stores at the sign-in boundary.
///
/// MULTI-ACCOUNT: the merge unions local + account, which is exactly right for
/// the single-user case (anonymous favorites made before sign-in are preserved
/// and pushed up, then the account's own set is pulled down). In the rarer
/// "sign out as A, sign in as B on the same device without an app restart"
/// case the union would push A's residual local favorites into B's account.
/// v1 is single-user-first (accounts are optional, spec section 5) and does not
/// track per-row ownership, so this is an accepted, documented limitation; a
/// future revision can scope local rows by user id to fully isolate accounts.
class FavoritesAccountSync {
  FavoritesAccountSync(this._db, this._account);

  final AppDatabase _db;
  final AccountFavoritesRepository _account;

  /// Merges local and account favorites. Returns the merged id set (handy for
  /// callers/tests). Network/db errors propagate to the caller, which logs and
  /// continues - a failed sync must never block sign-in.
  Future<Set<String>> run() async {
    final local = (await _db.favoriteIds()).toSet();
    final account = await _account.fetchFavoriteIds();

    final push = toPush(local, account);
    if (push.isNotEmpty) {
      await _account.pushFavoriteIds(push);
    }

    final pull = toPull(local, account);
    for (final id in pull) {
      await _db.addFavorite(id);
    }

    return mergeFavorites(local, account);
  }
}
