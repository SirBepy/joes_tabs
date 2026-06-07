import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../song/chord_diagram.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Chord-diagram library (per `docs/design/screens/chords.md`).
///
/// Browsable list of chords grouped by root note, each group a horizontally
/// scrolling row of [ChordDiagram] cards. The instrument is supplied by the
/// host (the Chords tab host owns the toggle). A search field filters by chord
/// name, and the tier filter respects maximal mode.
class ChordLibraryView extends ConsumerStatefulWidget {
  const ChordLibraryView({super.key, required this.instrument});

  final String instrument;

  @override
  ConsumerState<ChordLibraryView> createState() => _ChordLibraryViewState();
}

class _ChordLibraryViewState extends ConsumerState<ChordLibraryView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final instrument = widget.instrument;
    final maximal = ref.watch(maximalChordsProvider);
    final allowed = {
      for (final q in (maximal ? kChordQualities : kBalancedQualities))
        q.suffix,
    };
    final names = ChordShapes.namesFor(instrument).where((n) {
      final suffix = n.replaceFirst(RegExp(r'^[A-G][#b]?'), '');
      return allowed.contains(suffix);
    }).toList();

    final filtered = _query.isEmpty
        ? names
        : names
              .where((n) => n.toLowerCase().contains(_query.toLowerCase()))
              .toList();
    final grouped = _groupByRoot(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search chords',
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: grouped.isEmpty
              ? const Center(
                  child: Text(
                    'No chords match that search.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    for (final entry in grouped.entries)
                      _RootSection(
                        root: entry.key,
                        chords: entry.value,
                        instrument: instrument,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Groups chord names by their root pitch class label (the leading note plus
  /// any accidental), preserving a musical order C, C#, D, ...
  Map<String, List<String>> _groupByRoot(List<String> names) {
    final groups = <String, List<String>>{};
    for (final name in names) {
      final root = _rootOf(name);
      groups.putIfAbsent(root, () => []).add(name);
    }
    final ordered = groups.keys.toList()
      ..sort((a, b) {
        final ia = Transposer.noteIndex(a) ?? 99;
        final ib = Transposer.noteIndex(b) ?? 99;
        return ia != ib ? ia.compareTo(ib) : a.compareTo(b);
      });
    return {for (final k in ordered) k: groups[k]!..sort()};
  }

  String _rootOf(String chord) {
    final m = RegExp(r'^([A-Ga-g][#b]*)').firstMatch(chord);
    return m?.group(1) ?? chord;
  }
}

/// One root-note section: a large root label and a horizontal carousel of the
/// variant diagrams for that root.
class _RootSection extends StatelessWidget {
  const _RootSection({
    required this.root,
    required this.chords,
    required this.instrument,
  });

  final String root;
  final List<String> chords;
  final String instrument;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              root,
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: chords.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => ChordDiagram(
                chord: chords[i],
                instrumentSlug: instrument,
                width: 84,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
