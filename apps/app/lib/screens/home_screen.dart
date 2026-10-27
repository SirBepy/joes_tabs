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
import '../widgets/brand_mascot.dart';
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
    // Signed out has no subtitle: the sign-in card below carries the prompt.
    final greetingName = user == null ? null : '${_displayName(user.email)}!';

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
                const SizedBox(height: AppSpacing.md),
                // Brand mascot placeholder (orange ukulele character TBD).
                const BrandMascot(size: 140),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel(
          'SAVED TABS',
          // "ALL SAVED TABS >" link routes to the full saved list.
          trailing: const _SectionLink(
            label: 'ALL SAVED TABS',
            route: AppRoutes.saved,
            push: true,
          ),
        ),
        _SavedRow(favoriteIds: favoriteIds, trending: trending),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel(
          'TRENDING',
          trailing: _SectionLink(
            key: Key('home-trending-see-all'),
            label: 'SEE ALL',
            route: AppRoutes.trending,
          ),
        ),
        trending.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              const FriendlyError(message: 'Could not load trending tabs.'),
          data: (songs) => _TrendingPanel(songs: songs),
        ),
      ],
    );
  }
}

/// The grouped peach panel wrapping the home Trending list, with thin dividers
/// between rows (mockup Welcome.png).
class _TrendingPanel extends StatelessWidget {
  const _TrendingPanel({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const EmptyState(
        message: 'No trending tabs right now. Check back soon.',
        icon: PhosphorIconsRegular.chartLineUp,
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
/// Saved is a sibling tab, so it is pushed; Trending is nested under Home, so
/// `go` stacks it on Home and back pops to Home.
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
        // Title at the start, optional link (e.g. "ALL SAVED TABS >") pinned to
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
      height: 118,
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
