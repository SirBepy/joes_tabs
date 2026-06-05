import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory set of favorited song ids (base notifier).
///
/// PERSISTENCE: plan 09 backs the same contract with a Drift table via
/// [DriftFavoritesNotifier]; the app overrides [favoritesProvider] at the root
/// `ProviderScope` so favorites survive an app restart. This base class stays
/// as the default (used in widget tests with no database) and defines the
/// contract every consumer relies on:
/// - `state` is the current set of favorited song ids.
/// - [isFavorite] / [toggle] / [add] / [remove] are the only mutators.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier([Set<String>? initial])
    : super(Set<String>.unmodifiable(initial ?? const <String>{}));

  /// Whether [songId] is currently favorited.
  bool isFavorite(String songId) => state.contains(songId);

  /// Adds [songId] to favorites (no-op if already present).
  void add(String songId) {
    if (state.contains(songId)) return;
    state = Set<String>.unmodifiable({...state, songId});
  }

  /// Removes [songId] from favorites (no-op if absent).
  void remove(String songId) {
    if (!state.contains(songId)) return;
    state = Set<String>.unmodifiable(state.where((id) => id != songId));
  }

  /// Toggles [songId]'s favorite state.
  void toggle(String songId) =>
      isFavorite(songId) ? remove(songId) : add(songId);
}

/// Drift-backed [FavoritesNotifier] that persists favorites across restart and,
/// when signed in, mirrors every toggle to the account in real time.
///
/// Local Drift is the always-on source of truth for instant UI: writes go
/// straight to the [AppDatabase] favorites table and `state` is kept in sync by
/// listening to the table's stream so external changes (and the Saved screen)
/// always agree. The mutator surface is unchanged from the base class, so no
/// consumer (`song_detail_screen`, `song_tiles`, `home_screen`, `saved_screen`)
/// needs to change.
///
/// Account write-through (ai_todo 005): when an [AccountFavoritesSink] is
/// injected, each add/remove ALSO mirrors the change to `user_favorites` so a
/// favorite made on web reaches mobile (and vice versa) immediately, not only
/// on the next sign-in. The sink itself decides whether to write (signed in) or
/// no-op (signed out / no backend). The mirror is best-effort: an account write
/// failure is logged and swallowed so it never breaks the local toggle.
class DriftFavoritesNotifier extends FavoritesNotifier {
  DriftFavoritesNotifier(
    this._db, {
    Set<String>? initial,
    AccountFavoritesSink? accountSink,
  }) : _accountSink = accountSink,
       super(initial) {
    _sub = _db.watchFavoriteIds().listen((ids) {
      state = Set<String>.unmodifiable(ids);
    });
  }

  final AppDatabase _db;
  final AccountFavoritesSink? _accountSink;
  StreamSubscription<List<String>>? _sub;

  @override
  void add(String songId) {
    if (state.contains(songId)) return;
    // Optimistic local update; the stream confirms it shortly after.
    super.add(songId);
    unawaited(_db.addFavorite(songId));
    _mirror(() => _accountSink?.add(songId), songId);
  }

  @override
  void remove(String songId) {
    if (!state.contains(songId)) return;
    super.remove(songId);
    unawaited(_db.removeFavorite(songId));
    _mirror(() => _accountSink?.remove(songId), songId);
  }

  /// Fire-and-forget the account mirror. Best-effort by design: local Drift has
  /// already been updated (instant UI), so a network/account failure is logged
  /// and swallowed - it must never throw out of a toggle.
  void _mirror(Future<void>? Function() write, String songId) {
    final future = write();
    if (future == null) return;
    unawaited(
      future.catchError((Object e) {
        debugPrint('Account favorites mirror failed for "$songId": $e');
      }),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// The app-wide favorites store.
///
/// Default is the in-memory [FavoritesNotifier]; `main.dart` overrides this at
/// the root `ProviderScope` (via [favoritesProvider.overrideWith]) with a
/// [DriftFavoritesNotifier] so favorites persist across restart. No consumer
/// changes because the [FavoritesNotifier] surface is identical.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

/// Convenience selector: is a given song id favorited right now.
final isFavoriteProvider = Provider.family<bool, String>(
  (ref, songId) => ref.watch(favoritesProvider).contains(songId),
);
