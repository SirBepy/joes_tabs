import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Search results screen. A debounced text field drives `searchProvider`;
/// matching songs render as tappable rows to the song detail.
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
          decoration: InputDecoration(
            hintText: 'Search tabs',
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
      body: _query.isEmpty
          ? const EmptyState(
              message: 'Type to search the tab catalogue.',
              icon: PhosphorIconsRegular.magnifyingGlass,
            )
          : _Results(query: _query),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider(query));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const FriendlyError(message: 'Search failed.'),
      data: (songs) {
        if (songs.isEmpty) {
          return EmptyState(message: 'No tabs match "$query".');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => SongListTile(song: songs[i]),
        );
      },
    );
  }
}
