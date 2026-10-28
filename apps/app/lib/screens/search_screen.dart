import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../web_tabs/open_external.dart';
import '../widgets/song_tiles.dart';

/// Search screen: a debounced text field drives [webSearchProvider], which
/// reads ukulele-tabs.com's own search page from the device. Results are link
/// rows; opening one reads that page, and the bookmark saves only its link.
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

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            hintText: 'Search ukulele-tabs.com',
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
              Expanded(
                child: _query.isEmpty
                    ? const EmptyState(
                        message:
                            'Search ukulele-tabs.com by song or artist to '
                            'find a tab.',
                        icon: PhosphorIconsRegular.magnifyingGlass,
                      )
                    : _Results(query: _query),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The web build can't read another site's page (CORS), so it links out to
    // the site's own search instead.
    if (kIsWeb) {
      return _OpenOnSite(query: query);
    }
    return ref
        .watch(webSearchProvider(query))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const FriendlyError(
            message: "Couldn't reach ukulele-tabs.com. Please try again.",
          ),
          data: (results) {
            if (results.isEmpty) {
              return EmptyState(message: 'No songs found for "$query".');
            }
            return SongListOrGrid(
              itemCount: results.length,
              itemBuilder: (_, i) => SongListTile(
                song: webSongStub(
                  results[i].url.toString(),
                  title: results[i].title,
                  artist: results[i].artist,
                ),
                highlight: query,
              ),
            );
          },
        );
  }
}

class _OpenOnSite extends StatelessWidget {
  const _OpenOnSite({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The web version can only open the search on ukulele-tabs.com. '
              'Use the Android or iOS app to read tabs here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              icon: const Icon(PhosphorIconsRegular.arrowSquareOut),
              label: const Text('Search on ukulele-tabs.com'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
              onPressed: () => openExternally(ukuleleTabsSearchUrl(query)),
            ),
          ],
        ),
      ),
    );
  }
}
