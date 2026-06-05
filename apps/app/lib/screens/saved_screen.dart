import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/favorites_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Saved tabs list (per `docs/design/screens/saved-tabs.md`): the favorited
/// songs from the in-memory favorites store, with a friendly empty state.
///
/// Favorite ids are resolved against `trendingProvider` (the only catalogue in
/// hand for plan 08); plan 09's cache will resolve any saved id directly.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final catalogue = ref.watch(trendingProvider);

    if (favoriteIds.isEmpty) {
      return const EmptyState(
        message: 'No saved tabs yet.\nTap the heart on a song to keep it here.',
        icon: PhosphorIconsRegular.bookmarkSimple,
      );
    }

    return catalogue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const FriendlyError(message: 'Could not load your saved tabs.'),
      data: (songs) {
        final saved = songs.where((s) => favoriteIds.contains(s.id)).toList();
        if (saved.isEmpty) {
          return const EmptyState(
            message: 'Your saved tabs are not in the catalogue right now.',
            icon: PhosphorIconsRegular.bookmarkSimple,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: saved.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => SongListTile(song: saved[i]),
        );
      },
    );
  }
}
