import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../state/settings_provider.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../web_tabs/open_external.dart';
import '../widgets/song_tiles.dart';

/// Search results screen. A debounced text field drives [searchFilteredProvider]
/// (query + an instrument filter); matching songs render as tappable rows to the
/// song detail with a small instrument chip.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  /// Seed query passed via `/search?q=...`.
  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  Timer? _debounce;
  String _query = '';

  /// Active instrument filter slug, or null for "All" (both instruments).
  /// Seeded from the currently-viewed instrument in [didChangeDependencies].
  String? _instrumentSlug;
  bool _filterInitialized = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default the filter to the currently-viewed instrument once. Read (not
    // watch) so later settings changes don't yank the user's in-screen choice.
    if (!_filterInitialized) {
      _instrumentSlug = ref.read(selectedInstrumentProvider);
      _filterInitialized = true;
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _onFilterChanged(String? slug) {
    setState(() => _instrumentSlug = slug);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPicker = ref.watch(showInstrumentPickerProvider);
    // When the user plays one instrument, hide the All/Ukulele/Guitar filter and
    // force that single instrument as the result filter.
    final effectiveSlug = showPicker
        ? _instrumentSlug
        : ref.watch(instrumentsProvider).first;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          // The fill is white in both themes, so the typed text stays dark
          // instead of inheriting dark mode's light body text.
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Search by song or artist',
            // Hint and icon take the muted light-theme tone explicitly so dark
            // mode's pale input colours do not wash out on the white fill.
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.white,
            prefixIcon: const Icon(
              PhosphorIconsRegular.magnifyingGlass,
              color: AppColors.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      // Search is a separate route (not under the shell), so cap + center its
      // body here so wide windows do not stretch the griddy results edge to edge.
      // Below the cap the ConstrainedBox is a no-op, so mobile is unchanged.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
          child: Column(
            children: [
              if (showPicker)
                _InstrumentFilterBar(
                  selected: _instrumentSlug,
                  onChanged: _onFilterChanged,
                ),
              Expanded(
                child: _query.isEmpty
                    ? const EmptyState(
                        message: 'Search by song or artist to find a tab.',
                        icon: PhosphorIconsRegular.magnifyingGlass,
                      )
                    : _Results(query: _query, instrumentSlug: effectiveSlug),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented All / Ukulele / Guitar filter row above the results.
class _InstrumentFilterBar extends StatelessWidget {
  const _InstrumentFilterBar({required this.selected, required this.onChanged});

  /// Selected instrument slug, or null for "All".
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChoice(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChoice(
            label: 'Ukulele',
            selected: selected == ChordShapes.ukulele,
            onTap: () => onChanged(ChordShapes.ukulele),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChoice(
            label: 'Guitar',
            selected: selected == ChordShapes.guitar,
            onTap: () => onChanged(ChordShapes.guitar),
          ),
        ],
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.orange,
      backgroundColor: context.palette.chip,
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.rust,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.instrumentSlug});

  final String query;
  final String? instrumentSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(
      searchFilteredProvider((query: query, instrumentSlug: instrumentSlug)),
    );
    final web = ref.watch(webTabsEnabledProvider)
        ? _WebResults(query: query)
        : null;
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const FriendlyError(message: 'Search failed. Please try again.'),
      data: (songs) {
        if (songs.isEmpty) {
          return ListView(
            children: [
              EmptyState(message: 'No songs found for "$query".'),
              ?web,
            ],
          );
        }
        final chip = _chipLabel(instrumentSlug);
        return SongListOrGrid(
          itemCount: songs.length,
          itemBuilder: (_, i) => SongListTile(
            song: songs[i],
            trailingChip: chip,
            highlight: query,
          ),
          footer: web,
        );
      },
    );
  }

  /// The instrument chip shown on each result. When a specific instrument is
  /// selected every result has a tab for it, so we surface that label; for
  /// "All" we omit the chip (results may have either/both).
  static String? _chipLabel(String? slug) {
    switch (slug) {
      case ChordShapes.ukulele:
        return 'uke';
      case ChordShapes.guitar:
        return 'guitar';
      default:
        return null;
    }
  }
}

/// "From the web": chord pages on the allowlisted sites, below the catalog.
/// Signed-in only (imported tabs are visible to signed-in users only), so
/// signed-out users get a sign-in prompt instead.
class _WebResults extends ConsumerWidget {
  const _WebResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;
    final muted = TextStyle(color: context.palette.mutedInk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Text(
            'FROM THE WEB',
            style: TextStyle(
              color: context.palette.mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        if (!signedIn)
          ListTile(
            leading: const Icon(
              PhosphorIconsRegular.globe,
              color: AppColors.orange,
            ),
            title: const Text('Log in to search chord sites on the web'),
            onTap: () => context.push(AppRoutes.login),
          )
        else
          ref
              .watch(webSearchProvider(query))
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Web search is unavailable right now.',
                    style: muted,
                  ),
                ),
                data: (results) => results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No chord pages found on the web.',
                          style: muted,
                        ),
                      )
                    : Column(
                        children: [
                          for (final r in results) _WebResultTile(result: r),
                        ],
                      ),
              ),
      ],
    );
  }
}

class _WebResultTile extends StatelessWidget {
  const _WebResultTile({required this.result});

  final WebSearchResult result;

  /// Opens in the in-app reader only where it can work: a parseable site, on
  /// Android/iOS (the web build has no WebView and can't read other sites).
  bool get _readsInApp => result.site.parseable && !kIsWeb;

  void _open(BuildContext context) {
    final songId = result.songId;
    if (songId != null) {
      context.push(AppRoutes.songPath(songId));
    } else if (_readsInApp) {
      context.push(AppRoutes.webTabPath(result.url, result.title));
    } else {
      openExternally(result.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artist = result.artist;
    final parsed = artist != null
        ? (title: result.title, artist: artist)
        : parseWebTabTitle(result.title);
    final external = result.songId == null && !_readsInApp;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      title: Text(
        parsed.title.isEmpty ? result.title : parsed.title,
        style: TextStyle(
          color: context.palette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [?parsed.artist, result.site.name].join(' · '),
        style: const TextStyle(color: AppColors.orange),
      ),
      trailing: Icon(
        external
            ? PhosphorIconsRegular.arrowSquareOut
            : PhosphorIconsRegular.caretRight,
        color: AppColors.rust,
        semanticLabel: external ? 'Opens in browser' : null,
      ),
      onTap: () => _open(context),
    );
  }
}
