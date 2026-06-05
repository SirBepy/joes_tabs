import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Trending tabs list (per `docs/design/screens/trending-2.md`): a heading and
/// a vertical list of tappable song rows from `trendingProvider`.
class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProvider);
    return trending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const FriendlyError(message: 'Could not load trending tabs.'),
      data: (songs) {
        if (songs.isEmpty) {
          return const EmptyState(message: 'No tabs yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: songs.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'TRENDING',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              );
            }
            return SongListTile(song: songs[i - 1]);
          },
        );
      },
    );
  }
}
