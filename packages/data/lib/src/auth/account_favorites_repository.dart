import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the signed-in user's favorites in the `user_favorites` table.
///
/// RLS (see the `user_favorites` migration) scopes every row to
/// `auth.uid()`, so these queries never need to pass a user id explicitly: the
/// authenticated request only ever sees and writes its own rows.
class AccountFavoritesRepository {
  AccountFavoritesRepository(this._client);

  final SupabaseClient _client;

  /// All `song_id`s the current user has favorited on their account.
  Future<Set<String>> fetchFavoriteIds() async {
    final rows = await _client.from('user_favorites').select('song_id');
    return {for (final r in rows) r['song_id'] as String};
  }

  /// Upserts [songIds] into the account favorites (idempotent: the table's
  /// primary key is `(user_id, song_id)`, so re-pushing an existing favorite is
  /// a no-op). The `user_id` defaults to `auth.uid()` server-side.
  Future<void> pushFavoriteIds(Iterable<String> songIds) async {
    final ids = songIds.toList();
    if (ids.isEmpty) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('user_favorites')
        .upsert(
          [
            for (final id in ids) {'user_id': userId, 'song_id': id},
          ],
          onConflict: 'user_id,song_id',
          ignoreDuplicates: true,
        );
  }

  /// Removes a single favorite [songId] from the account (idempotent: deleting
  /// a row that does not exist is a no-op). RLS restricts the delete to the
  /// signed-in user's own row, so no `user_id` filter is needed.
  Future<void> removeFavoriteId(String songId) async {
    await _client.from('user_favorites').delete().eq('song_id', songId);
  }
}
