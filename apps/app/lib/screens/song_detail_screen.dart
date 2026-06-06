import 'package:data/data.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../song/chord_diagram.dart';
import '../song/chord_sheet_view.dart';
import '../song/song_controls_sheet.dart';
import '../state/favorites_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/song_tiles.dart';

/// Song / play-along view (per `docs/design/screens/tabs-screen.md`).
///
/// Consumes `songProvider(id)`. The body stays clean - the centered title +
/// artist, the horizontal chord-diagram strip, and the rendered chord sheet
/// (chords over lyrics) dominate. The playback controls (instrument toggle,
/// transpose, autoscroll) are NOT inline: they live in a brand-styled bottom
/// sheet opened from the orange faders [FloatingActionButton] at bottom-right,
/// matching the mockup. The app-bar heart toggles the in-memory favorites
/// store.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(songProvider(songId));
    final isFav = ref.watch(isFavoriteProvider(songId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        title: const Text('Joes Tabs'),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove favorite' : 'Add favorite',
            icon: Icon(
              isFav ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
              color: isFav ? AppColors.white : null,
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
///
/// All control state lives here (not in the sheet) so a) it survives the sheet
/// being dismissed - autoscroll keeps running - and b) every change applies
/// live to the chord sheet behind the open sheet. When the sheet is open we
/// also drive its [StatefulBuilder] refresh via [_refreshSheet] so its readouts
/// stay in sync with the view underneath.
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

  /// When the user plays a single instrument the per-song tab toggle is hidden;
  /// we seed the shown tab to that instrument's tab once (if the song has one).
  bool _forcedTabApplied = false;

  bool _scrolling = false;

  /// Autoscroll speed in logical pixels per second.
  double _speed = 40;

  /// When the controls sheet is open, this rebuilds it so its controls reflect
  /// live state changes made to the screen behind it. Null while the sheet is
  /// closed.
  VoidCallback? _refreshSheet;

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
      _refreshSheet?.call();
      _lastTick = null;
      _ticker.start();
    }
  }

  void _stopScroll() {
    _ticker.stop();
    if (mounted) {
      setState(() => _scrolling = false);
      _refreshSheet?.call();
    }
  }

  /// Applies a control mutation to the screen state and mirrors it onto the
  /// open sheet, so the readout in the sheet and the chord sheet behind it
  /// update together.
  void _apply(VoidCallback change) {
    setState(change);
    _refreshSheet?.call();
  }

  void _openControls(
    List<Tab> published,
    Map<String, Instrument>? instruments,
    String songKey,
    int? capo,
    bool showInstrumentToggle,
  ) {
    showSongControlsSheet(
      context,
      tabs: published,
      instruments: instruments,
      showInstrumentToggle: showInstrumentToggle,
      selectedTab: () => _tabIndex,
      onTabChanged: (i) => _apply(() => _tabIndex = i),
      transpose: () => _transpose,
      shownKey: () =>
          songKey.isEmpty ? '' : Transposer.transposeKey(songKey, _transpose),
      capo: () => capo,
      onTranspose: (d) => _apply(() => _transpose += d),
      onResetTranspose: () => _apply(() => _transpose = 0),
      scrolling: () => _scrolling,
      speed: () => _speed,
      onToggleScroll: _toggleScroll,
      onSpeed: (v) => _apply(() => _speed = v),
      registerRefresh: (refresh) => _refreshSheet = refresh,
    ).whenComplete(() => _refreshSheet = null);
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

    // Map each published tab's instrument id to a slug for the toggle + chord
    // diagrams. Falls back to "ukulele" shapes if the lookup is unavailable.
    final instruments = ref.watch(instrumentsByIdProvider).valueOrNull;

    // When the user plays one instrument, hide the per-song tab toggle and force
    // that instrument's tab (if this song has one) the first time we can resolve
    // the instrument map.
    final showInstrumentToggle = ref.watch(showInstrumentPickerProvider);
    if (!showInstrumentToggle && !_forcedTabApplied && instruments != null) {
      final wanted = ref.read(instrumentsProvider).first;
      final match = published.indexWhere(
        (t) => instruments[t.instrumentId]?.slug == wanted,
      );
      if (match >= 0) _tabIndex = match;
      _forcedTabApplied = true;
    }

    final tab = published[_tabIndex];
    final sheet = ChordProParser.parse(tab.content);
    final slug = instruments?[tab.instrumentId]?.slug ?? ChordShapes.ukulele;
    final songKey = sheet.key ?? tab.originalKey;
    final capo = sheet.capo ?? tab.capo;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
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
                  _ChordStrip(chords: sheet.chordsUsed, instrumentSlug: slug),
                  const SizedBox(height: AppSpacing.md),
                  _Header(song: widget.data.song),
                  const SizedBox(height: AppSpacing.md),
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
                songKey: songKey,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Song controls',
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        onPressed: () => _openControls(
          published,
          instruments,
          songKey,
          capo,
          showInstrumentToggle,
        ),
        child: const Icon(PhosphorIconsFill.faders),
      ),
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
