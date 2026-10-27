import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../song/chord_diagram.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/scrollable_chip_row.dart';

/// Guided chord picker: a live result diagram on top, then Note + sharp/flat
/// strips, then a tabbed Family/Type section (a scrollable Family tab bar over a
/// list of that family's chords). Selection is in-memory view state.
class ChordPickerView extends ConsumerStatefulWidget {
  const ChordPickerView({super.key, required this.instrumentSlug});

  final String instrumentSlug;

  @override
  ConsumerState<ChordPickerView> createState() => _ChordPickerViewState();
}

class _ChordPickerViewState extends ConsumerState<ChordPickerView> {
  static const _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const _accidentals = ['♮', '♯', '♭'];

  String _letter = 'C';
  String _accidental = '♮';
  ChordFamily _family = ChordFamily.major;
  String _suffix = '';

  String get _root {
    switch (_accidental) {
      case '♯':
        return '$_letter#';
      case '♭':
        return '${_letter}b';
      default:
        return _letter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maximal = ref.watch(maximalChordsProvider);
    final qualities = qualitiesFor(_family, maximal: maximal);

    // Selection-validity: if the current suffix is not in the active family's
    // tier (family or maximal-tier changed), snap to that family's first
    // quality so the result card always reflects a real chord.
    if (!qualities.any((q) => q.suffix == _suffix)) {
      _suffix = qualities.isEmpty ? '' : qualities.first.suffix;
    }
    final symbol = '$_root$_suffix';

    return ListView(
      children: [
        _ResultCard(symbol: symbol, instrumentSlug: widget.instrumentSlug),
        ScrollableChipRow(
          label: 'Note',
          options: _letters,
          selected: _letter,
          onSelected: (v) => setState(() => _letter = v),
        ),
        ScrollableChipRow(
          label: 'Sharp / Flat',
          options: _accidentals,
          selected: _accidental,
          onSelected: (v) => setState(() => _accidental = v),
        ),
        _FamilyTabBar(
          selected: _family,
          onSelected: (f) => setState(() => _family = f),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TypeList(
          qualities: qualities,
          selectedSuffix: _suffix,
          onSelected: (suffix) => setState(() => _suffix = suffix),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// The Family tabs: a horizontally-scrollable pill strip mirroring the app's
/// orange/peach pill-tab style (see `_Tabs` in `chords_screen.dart`). Built
/// picker-local rather than extracted: the host `_Tabs` is a fixed 2-tab,
/// boolean-driven, non-scrolling row, so sharing would mean genericising both
/// for no real reuse win.
class _FamilyTabBar extends StatelessWidget {
  const _FamilyTabBar({required this.selected, required this.onSelected});

  final ChordFamily selected;
  final ValueChanged<ChordFamily> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.palette.chip,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final family in ChordFamily.values)
              _FamilyTab(
                label: family.label,
                selected: family == selected,
                onTap: () => onSelected(family),
              ),
          ],
        ),
      ),
    );
  }
}

class _FamilyTab extends StatelessWidget {
  const _FamilyTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : context.palette.ink,
          ),
        ),
      ),
    );
  }
}

/// The selected family's chords, one tappable row each. Tapping a row sets the
/// suffix and updates the result card/diagram live. Renders inside the outer
/// `ListView`, so it lays itself out as a non-scrolling Column.
class _TypeList extends StatelessWidget {
  const _TypeList({
    required this.qualities,
    required this.selectedSuffix,
    required this.onSelected,
  });

  final List<ChordQuality> qualities;
  final String selectedSuffix;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final q in qualities)
          _TypeRow(
            quality: q,
            selected: q.suffix == selectedSuffix,
            onTap: () => onSelected(q.suffix),
          ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.quality,
    required this.selected,
    required this.onTap,
  });

  final ChordQuality quality;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs / 2,
      ),
      child: Material(
        color: selected ? AppColors.orange : context.palette.card,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    quality.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.white : context.palette.ink,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    PhosphorIconsBold.check,
                    size: 18,
                    color: AppColors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.symbol, required this.instrumentSlug});

  final String symbol;
  final String instrumentSlug;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              symbol,
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 30,
              ),
            ),
          ),
          ChordDiagram(
            chord: symbol,
            instrumentSlug: instrumentSlug,
            width: 96,
            showLabel: false,
          ),
        ],
      ),
    );
  }
}
