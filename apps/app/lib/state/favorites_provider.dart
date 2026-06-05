import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory set of favorited song ids.
///
/// PERSISTENCE NOTE: deliberately in-memory only for plan 08. Plan 09 backs the
/// same contract with a Drift table so favorites survive an app restart. Until
/// then, favorites reset when the app process exits (acceptable for the
/// wireframe). The contract plan 09 should preserve:
/// - `state` is the current set of favorited song ids.
/// - [isFavorite] / [toggle] / [add] / [remove] are the only mutators.
/// - Replace the body of this notifier with a cache-backed one and override
///   [favoritesProvider] at the root `ProviderScope`; no consumer changes.
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

/// The app-wide favorites store. In-memory for plan 08 (see [FavoritesNotifier]).
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

/// Convenience selector: is a given song id favorited right now.
final isFavoriteProvider = Provider.family<bool, String>(
  (ref, songId) => ref.watch(favoritesProvider).contains(songId),
);
