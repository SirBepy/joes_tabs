import 'package:data/data.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../song/chord_diagram.dart';
import '../song/chord_sheet_view.dart';
import '../state/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Song / play-along view (per `docs/design/screens/tabs-screen.md`).
///
/// Consumes `songProvider(id)`. Renders the chord sheet (chords over lyrics),
/// an instrument toggle when both tabs exist, transpose +/- controls, a capo
/// readout, an autoscroll play/pause + speed slider, and a strip of chord
/// diagrams for the chords the song uses. The app-bar heart toggles the
/// in-memory favorites store.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(songProvider(songId));
    final isFav = ref.watch(isFavoriteProvider(songId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Song'),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove favorite' : 'Add favorite',
            icon: Icon(
              isFav ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
              color: isFav ? AppColors.rust : null,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(songId),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const FriendlyError(message: 'Could not load this song.'),
        data: (songWithTabs) {
          if (songWithTabs == null) {
            return const EmptyState(message: 'Song not found.');
          }
          return _SongBody(data: songWithTabs);
        },
      ),
    );
  }
}

/// Stateful body owning transpose offset, instrument selection, and autoscroll.
class _SongBody extends ConsumerStatefulWidget {
  const _SongBody({required this.data});

  final SongWithTabs data;

  @override
  ConsumerState<_SongBody> createState() => _SongBodyState();
}

class _SongBodyState extends ConsumerState<_SongBody>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final Ticker _ticker;
  int _transpose = 0;

  /// Selected tab index among the published tabs.
  int _tabIndex = 0;

  bool _scrolling = false;

  /// Autoscroll speed in logical pixels per second.
  double _speed = 40;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  Duration? _lastTick;
  void _onTick(Duration elapsed) {
    if (!_scrolling || !_scroll.hasClients) return;
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = (elapsed - last).inMicroseconds / 1e6;
    final max = _scroll.position.maxScrollExtent;
    final next = (_scroll.offset + _speed * dt).clamp(0.0, max);
    _scroll.jumpTo(next);
    if (next >= max) _stopScroll();
  }

  void _toggleScroll() {
    if (_scrolling) {
      _stopScroll();
    } else {
      setState(() => _scrolling = true);
      _lastTick = null;
      _ticker.start();
    }
  }

  void _stopScroll() {
    _ticker.stop();
    if (mounted) setState(() => _scrolling = false);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final published = widget.data.publishedTabs;
    if (published.isEmpty) {
      return const EmptyState(message: 'No published tab for this song yet.');
    }
    if (_tabIndex >= published.length) _tabIndex = 0;
    final tab = published[_tabIndex];
    final sheet = ChordProParser.parse(tab.content);

    // Map each published tab's instrument id to a slug for the toggle + chord
    // diagrams. Falls back to "ukulele" shapes if the lookup is unavailable.
    final instruments = ref.watch(instrumentsByIdProvider).valueOrNull;
    final slug = instruments?[tab.instrumentId]?.slug ?? ChordShapes.ukulele;

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(song: widget.data.song),
                const SizedBox(height: AppSpacing.md),
                _ChordStrip(chords: sheet.chordsUsed, instrumentSlug: slug),
                const SizedBox(height: AppSpacing.md),
                if (published.length > 1)
                  _InstrumentToggle(
                    tabs: published,
                    instruments: instruments,
                    selected: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                _ControlsBar(
                  transpose: _transpose,
                  songKey: sheet.key ?? tab.originalKey,
                  capo: sheet.capo ?? tab.capo,
                  onTranspose: (d) => setState(() => _transpose += d),
                  onReset: () => setState(() => _transpose = 0),
                ),
                _AutoscrollBar(
                  scrolling: _scrolling,
                  speed: _speed,
                  onToggle: _toggleScroll,
                  onSpeed: (v) => setState(() => _speed = v),
                ),
                const Divider(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: ChordSheetView(
              sheet: sheet,
              transpose: _transpose,
              songKey: sheet.key ?? tab.originalKey,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            song.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          Text(song.artist, style: const TextStyle(color: AppColors.rust)),
        ],
      ),
    );
  }
}

class _ChordStrip extends StatelessWidget {
  const _ChordStrip({required this.chords, required this.instrumentSlug});
  final List<String> chords;
  final String instrumentSlug;

  @override
  Widget build(BuildContext context) {
    if (chords.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chords.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) =>
            ChordDiagram(chord: chords[i], instrumentSlug: instrumentSlug),
      ),
    );
  }
}

class _InstrumentToggle extends StatelessWidget {
  const _InstrumentToggle({
    required this.tabs,
    required this.instruments,
    required this.selected,
    required this.onChanged,
  });

  final List<Tab> tabs;
  final Map<String, Instrument>? instruments;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SegmentedButton<int>(
        segments: [
          for (var i = 0; i < tabs.length; i++)
            ButtonSegment<int>(
              value: i,
              label: Text(
                instruments?[tabs[i].instrumentId]?.name ?? 'Tab ${i + 1}',
              ),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.transpose,
    required this.songKey,
    required this.capo,
    required this.onTranspose,
    required this.onReset,
  });

  final int transpose;
  final String songKey;
  final int? capo;
  final ValueChanged<int> onTranspose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final shownKey = songKey.isEmpty
        ? null
        : Transposer.transposeKey(songKey, transpose);
    final offset = transpose == 0
        ? '0'
        : (transpose > 0 ? '+$transpose' : '$transpose');
    return Row(
      children: [
        const Text('Transpose', style: TextStyle(color: AppColors.textDark)),
        IconButton(
          tooltip: 'Down a semitone',
          icon: const Icon(PhosphorIconsRegular.minus),
          onPressed: () => onTranspose(-1),
        ),
        Text(
          offset,
          key: const Key('transpose-offset'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          tooltip: 'Up a semitone',
          icon: const Icon(PhosphorIconsRegular.plus),
          onPressed: () => onTranspose(1),
        ),
        if (shownKey != null)
          Text(
            'Key $shownKey',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        const Spacer(),
        if (capo != null && capo! > 0)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              'Capo $capo',
              style: const TextStyle(color: AppColors.rust),
            ),
          ),
        if (transpose != 0)
          TextButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _AutoscrollBar extends StatelessWidget {
  const _AutoscrollBar({
    required this.scrolling,
    required this.speed,
    required this.onToggle,
    required this.onSpeed,
  });

  final bool scrolling;
  final double speed;
  final VoidCallback onToggle;
  final ValueChanged<double> onSpeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          tooltip: scrolling ? 'Pause autoscroll' : 'Start autoscroll',
          icon: Icon(
            scrolling ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
          ),
          onPressed: onToggle,
        ),
        const SizedBox(width: AppSpacing.sm),
        const Icon(PhosphorIconsRegular.gauge, color: AppColors.textMuted),
        Expanded(
          child: Slider(
            min: 10,
            max: 160,
            value: speed,
            label: '${speed.round()} px/s',
            onChanged: onSpeed,
          ),
        ),
      ],
    );
  }
}
