import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../state/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Home for the ukulele-tabs.com client: the shell's search bar on top, then
/// the songs you opened recently and the ones you saved. Both lists hold only
/// links (song ids are page URLs), so titles come from each URL's slug.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final favoriteIds = ref.watch(favoritesProvider);
    final recentIds = ref.watch(recentSongIdsProvider).valueOrNull ?? const [];
    final user = ref.watch(currentUserProvider);

    final greetingTop = user == null ? 'WELCOME' : 'WELCOME BACK';
    final greetingName = user == null ? null : '${_displayName(user.email)}!';

    final recent = [
      for (final id in recentIds)
        if (isWebSongId(id)) webSongStub(id),
    ].take(kHomeRecentCount).toList();
    final saved = [
      for (final id in favoriteIds)
        if (isWebSongId(id)) webSongStub(id),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            child: Column(
              children: [
                Text(greetingTop, style: textTheme.headlineMedium),
                if (greetingName != null)
                  Text(
                    greetingName,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.orange.withValues(alpha: 0.6),
                    ),
                  ),
                if (user == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _SignInCard(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel('RECENTLY OPENED'),
        _SongPanel(
          songs: recent,
          empty: const EmptyState(
            message:
                'Search above to find a song. The ones you open show here.',
            icon: PhosphorIconsRegular.clockCounterClockwise,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel(
          'SAVED',
          trailing: _SectionLink(
            key: Key('home-saved-see-all'),
            label: 'SEE ALL',
            route: AppRoutes.saved,
            push: true,
          ),
        ),
        _SongPanel(
          songs: saved.take(kHomeRecentCount).toList(),
          empty: const EmptyState(
            message:
                'No saved songs yet. Tap the bookmark on a song to save it.',
            icon: PhosphorIconsRegular.bookmarkSimple,
          ),
        ),
      ],
    );
  }
}

/// How many songs each Home list shows before "SEE ALL".
const int kHomeRecentCount = 5;

/// A grouped card of song rows with thin dividers, or [empty] when there are
/// none.
class _SongPanel extends StatelessWidget {
  const _SongPanel({required this.songs, required this.empty});

  final List<Song> songs;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: empty,
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < songs.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: context.palette.divider,
              ),
            SongListTile(song: songs[i]),
          ],
        ],
      ),
    );
  }
}

/// A "LABEL >" navigation link pinned to the right of a section header.
/// Saved is a sibling tab, so it is pushed; a nested route would use `go` so
/// it stacks on Home and back pops to Home.
class _SectionLink extends StatelessWidget {
  const _SectionLink({
    super.key,
    required this.label,
    required this.route,
    this.push = false,
  });

  final String label;
  final String route;
  final bool push;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: () => push ? context.push(route) : context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

/// Signed-out prompt under the greeting: why to sign in plus Log In / Register.
class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('home-login-cta'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Column(
        children: [
          Text(
            'Log in to sync your saved tabs across devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('home-cta-log-in'),
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  key: const Key('home-cta-register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                  ),
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
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
  const _SectionLabel(this.text, {this.trailing});
  final String text;

  /// Optional widget pinned to the right of the header (e.g. an "ALL SAVED
  /// TABS >" link).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        // Title at the start, optional link (e.g. "SEE ALL >") pinned to
        // the opposite end so the two are not cramped together.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
