import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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
  /// Seeded from the user's preferred instrument in [initState].
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
    // Default the filter to the user's preferred instrument once. Read (not
    // watch) so later settings changes don't yank the user's in-screen choice.
    if (!_filterInitialized) {
      _instrumentSlug = ref.read(defaultInstrumentProvider);
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Search by song or artist',
            filled: true,
            fillColor: AppColors.white,
            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Column(
        children: [
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
                : _Results(query: _query, instrumentSlug: _instrumentSlug),
          ),
        ],
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
      backgroundColor: AppColors.peach,
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
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const FriendlyError(message: 'Search failed. Please try again.'),
      data: (songs) {
        if (songs.isEmpty) {
          return EmptyState(message: 'No songs found for "$query".');
        }
        final chip = _chipLabel(instrumentSlug);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => SongListTile(
            song: songs[i],
            trailingChip: chip,
            highlight: query,
          ),
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
