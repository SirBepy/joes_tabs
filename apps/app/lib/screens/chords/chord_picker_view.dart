import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

import '../../song/chord_diagram.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/scrollable_chip_row.dart';

/// Guided chord picker: a live result diagram on top, then four scrollable
/// strips (Note, sharp/flat, Family, Type). Selection is in-memory view state.
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
        ScrollableChipRow(
          label: 'Family',
          options: [for (final f in ChordFamily.values) f.label],
          selected: _family.label,
          onSelected: (label) => setState(() {
            _family = ChordFamily.values.firstWhere((f) => f.label == label);
          }),
        ),
        ScrollableChipRow(
          label: 'Type',
          options: [for (final q in qualities) q.label],
          selected: _labelFor(qualities, _suffix),
          onSelected: (label) => setState(() {
            _suffix = qualities.firstWhere((q) => q.label == label).suffix;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  String _labelFor(List<ChordQuality> qs, String suffix) =>
      qs.firstWhere((q) => q.suffix == suffix, orElse: () => qs.first).label;
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
        color: AppColors.cardPeach,
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
