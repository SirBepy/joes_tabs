import '../drift/app_database.dart';
import 'account_favorites_repository.dart';
import 'favorites_merge.dart';

/// Runs the first-sign-in favorites merge between the local Drift store and the
/// signed-in user's account (spec section 5).
///
/// Pragmatic and idempotent (re-running is safe and a no-op once converged):
///   * push local-only ids up to `user_favorites`,
///   * pull account-only ids down into the local Drift favorites,
/// leaving the union present in both places. Continuous two-way live sync is a
/// deliberate follow-up (see .for_bepy/ai_todos/005-favorites-live-sync.md);
/// this sign-in-time merge is enough for v1.
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
