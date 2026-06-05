import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../state/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A two-line trending/search list row: title over artist with a trailing
/// bookmark toggle, tappable to the song detail. Matches `trending-2.md`.
class SongListTile extends ConsumerWidget {
  const SongListTile({
    super.key,
    required this.song,
    this.trailingChip,
    this.highlight,
  });

  final Song song;

  /// Optional instrument chip text (e.g. `uke`/`guitar`) shown before the
  /// bookmark.
  final String? trailingChip;

  /// Optional query to emphasise where it matches the title/artist (search).
  final String? highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isFavoriteProvider(song.id));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      title: _Highlighted(
        text: song.title,
        query: highlight,
        base: const TextStyle(
          color: AppColors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: _Highlighted(
        text: song.artist,
        query: highlight,
        base: const TextStyle(color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingChip != null) _InstrumentChip(label: trailingChip!),
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save',
            icon: Icon(
              saved
                  ? PhosphorIconsFill.bookmarkSimple
                  : PhosphorIconsRegular.bookmarkSimple,
              color: AppColors.orange,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(song.id),
          ),
        ],
      ),
      onTap: () => context.push(AppRoutes.songPath(song.id)),
    );
  }
}

/// A compact saved-tab card for horizontal rows (home) and grids (saved).
class SongCard extends StatelessWidget {
  const SongCard({super.key, required this.song, this.width = 150});

  final Song song;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: () => context.push(AppRoutes.songPath(song.id)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardPeach,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [text] in [base] style, bolding the first case-insensitive run that
/// matches [query]. Falls back to plain text when there is no query or match.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.base, this.query});

  final String text;
  final String? query;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    final q = query?.trim() ?? '';
    if (q.isEmpty) return Text(text, style: base);

    final lowerText = text.toLowerCase();
    final start = lowerText.indexOf(q.toLowerCase());
    if (start < 0) return Text(text, style: base);

    final end = start + q.length;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: AppColors.rust,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.rust, fontSize: 11),
      ),
    );
  }
}

/// Shared friendly empty-state block with a mascot placeholder icon.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? PhosphorIconsFill.guitar,
              size: 56,
              color: AppColors.peach,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact inline error block for failed provider loads.
class FriendlyError extends StatelessWidget {
  const FriendlyError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              size: 40,
              color: AppColors.rust,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
