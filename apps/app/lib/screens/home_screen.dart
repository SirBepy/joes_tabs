import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../state/favorites_provider.dart';
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

    final greetingTop = user == null ? 'Welcome' : 'Welcome back';
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
                      color: context.palette.accent,
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
        const _SectionLabel('Recently opened'),
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
          'Saved',
          trailing: _SectionLink(
            key: Key('home-saved-see-all'),
            label: 'See all',
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

/// A grouped white card of song rows with hairline dividers, or [empty] when
/// there are none.
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
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < songs.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.palette.divider),
            SongListTile(song: songs[i], showIcon: true),
          ],
        ],
      ),
    );
  }
}

/// A "Label >" navigation link pinned to the right of a section header.
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
    final accent = context.palette.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: () => push ? context.push(route) : context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(PhosphorIconsRegular.caretRight, size: 16, color: accent),
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
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Text(
            'Log in to sync your saved tabs across devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w500),
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
                    foregroundColor: palette.accent,
                    side: BorderSide(color: palette.accent, width: 1.5),
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

/// Derives a friendly display name from an email: the local part before `@`.
/// Falls back to a generic label when no email is available.
String _displayName(String? email) {
  if (email == null || email.isEmpty) return 'friend';
  return email.split('@').first;
}

/// Home's white card: a hairline border plus a soft offset shadow so it lifts
/// off the pale blue page. Dark mode keeps the flat navy card.
BoxDecoration _cardDecoration(BuildContext context) {
  final palette = context.palette;
  final light = Theme.of(context).brightness == Brightness.light;
  return BoxDecoration(
    color: palette.card,
    borderRadius: BorderRadius.circular(AppSpacing.radius),
    border: light ? Border.all(color: palette.divider) : null,
    boxShadow: light
        ? const [
            BoxShadow(
              color: Color(0x0F12324A),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ]
        : null,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});
  final String text;

  /// Optional widget pinned to the right of the header (e.g. a "See all >"
  /// link).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + AppSpacing.xs,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        // Title at the start, optional link (e.g. "SEE ALL >") pinned to
        // the opposite end so the two are not cramped together.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
