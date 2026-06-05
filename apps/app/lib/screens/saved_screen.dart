import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/favorites_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Resolves the favorited song ids to [Song]s for the Saved screen.
///
/// Cache-first so saved songs render offline (plan 09): each favorite was cached
/// when it was opened, so the Drift cache is the source of truth. Any id missing
/// from the cache (e.g. favorited then evicted before viewing) is back-filled
/// from `trendingProvider` when that is available.
final savedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider).toList();
  if (favoriteIds.isEmpty) return const <Song>[];

  final db = ref.watch(appDatabaseProvider);
  final cached = await db.cachedSongsByIds(favoriteIds);
  final foundIds = cached.map((s) => s.id).toSet();

  final missing = favoriteIds.where((id) => !foundIds.contains(id)).toList();
  if (missing.isEmpty) return cached;

  // Back-fill any not-yet-cached favorites from the in-hand catalogue if it has
  // already loaded; offline this simply yields nothing extra.
  final trending = ref.watch(trendingProvider).valueOrNull ?? const <Song>[];
  final extra = trending.where((s) => missing.contains(s.id));
  return [...cached, ...extra];
});

/// Saved tabs list (per `docs/design/screens/saved-tabs.md`): the favorited
/// songs, resolved cache-first so they render offline (plan 09), with a
/// friendly empty state.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final saved = ref.watch(savedSongsProvider);

    if (favoriteIds.isEmpty) {
      return const EmptyState(
        message: 'No saved tabs yet.\nTap the heart on a song to keep it here.',
        icon: PhosphorIconsRegular.bookmarkSimple,
      );
    }

    return saved.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const FriendlyError(message: 'Could not load your saved tabs.'),
      data: (songs) {
        if (songs.isEmpty) {
          return const EmptyState(
            message: 'Your saved tabs are not in the catalogue right now.',
            icon: PhosphorIconsRegular.bookmarkSimple,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => SongListTile(song: songs[i]),
        );
      },
    );
  }
}
