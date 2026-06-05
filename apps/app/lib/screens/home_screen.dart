import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Logged-in home / dashboard (mockup `welcome.md`): greeting, a horizontal
/// Saved Tabs row from the in-memory favorites, and a vertical Trending list
/// from `trendingProvider`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final trending = ref.watch(trendingProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    final user = ref.watch(currentUserProvider);

    // Logged in: greet by email (name part). Anonymous: a generic welcome.
    final greetingTop = user == null ? 'WELCOME' : 'WELCOME BACK';
    final greetingName = user == null
        ? 'Tap Log In to sync your tabs'
        : '${_displayName(user.email)}!';

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            child: Column(
              children: [
                Text(greetingTop, style: textTheme.headlineMedium),
                Text(
                  greetingName,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.peach,
                  child: Icon(
                    PhosphorIconsFill.guitar,
                    size: 56,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel('SAVED TABS'),
        _SavedRow(favoriteIds: favoriteIds, trending: trending),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel('TRENDING'),
        trending.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              const FriendlyError(message: 'Could not load trending tabs.'),
          data: (songs) =>
              Column(children: [for (final s in songs) SongListTile(song: s)]),
        ),
      ],
    );
  }
}

/// Derives a friendly display name from an email: the local part before `@`,
/// upper-cased to match the mockup's all-caps greeting. Falls back to a generic
/// label when no email is available.
String _displayName(String? email) {
  if (email == null || email.isEmpty) return 'FRIEND';
  final local = email.split('@').first;
  return local.toUpperCase();
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Horizontal saved-tab cards. Resolves favorite ids against the trending list
/// (the only catalogue currently in hand); shows an empty state when none.
class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.favoriteIds, required this.trending});

  final Set<String> favoriteIds;
  final AsyncValue<List<Song>> trending;

  @override
  Widget build(BuildContext context) {
    if (favoriteIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: EmptyState(
          message: 'No saved tabs yet. Tap the heart on a song to save it.',
          icon: PhosphorIconsRegular.bookmarkSimple,
        ),
      );
    }
    final saved = (trending.valueOrNull ?? const <Song>[])
        .where((s) => favoriteIds.contains(s.id))
        .toList();
    if (saved.isEmpty) {
      return const SizedBox(height: 1);
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: saved.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => SongCard(song: saved[i]),
      ),
    );
  }
}
