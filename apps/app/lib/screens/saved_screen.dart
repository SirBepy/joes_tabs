import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/favorites_provider.dart';
import '../widgets/song_tiles.dart';

/// The saved ukulele-tabs.com songs, newest first. Only links are saved (a
/// web song's id is its page URL), so each row is built from its URL and the
/// sheet is read from the site again when opened.
final savedSongsProvider = Provider<List<Song>>((ref) {
  return [
    for (final id in ref.watch(favoritesProvider))
      if (isWebSongId(id)) webSongStub(id),
  ];
});

/// Saved songs list (per `docs/design/screens/saved-tabs.md`) with a friendly
/// empty state.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(savedSongsProvider);
    if (songs.isEmpty) {
      return const EmptyState(
        message:
            'No saved songs yet.\nTap the bookmark on a song to keep it here.',
        icon: PhosphorIconsRegular.bookmarkSimple,
      );
    }
    return SongListOrGrid(
      itemCount: songs.length,
      itemBuilder: (_, i) => SongListTile(song: songs[i]),
    );
  }
}
