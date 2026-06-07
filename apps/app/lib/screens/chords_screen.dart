import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/instrument_toggle.dart';
import 'chords/chord_library_view.dart';
import 'chords/chord_picker_view.dart';

/// Chords landing: a "Pick / Browse all" tab host. Pick is the guided picker;
/// Browse all is the grouped-by-root library. Instrument is resolved the same
/// way both views need it (forced to the single played instrument, or the
/// on-screen toggle when more than one is played).
class ChordsScreen extends ConsumerStatefulWidget {
  const ChordsScreen({super.key});

  @override
  ConsumerState<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends ConsumerState<ChordsScreen> {
  bool _browse = false;

  @override
  Widget build(BuildContext context) {
    final showPicker = ref.watch(showInstrumentPickerProvider);
    final instrument = showPicker
        ? ref.watch(selectedInstrumentProvider)
        : ref.watch(instrumentsProvider).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              _Tabs(
                browse: _browse,
                onChanged: (b) => setState(() => _browse = b),
              ),
              const Spacer(),
              if (showPicker)
                InstrumentToggle(
                  value: instrument,
                  onChanged: (slug) =>
                      ref.read(selectedInstrumentProvider.notifier).state =
                          slug,
                ),
            ],
          ),
        ),
        Expanded(
          child: _browse
              ? ChordLibraryView(instrument: instrument)
              : ChordPickerView(instrumentSlug: instrument),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.browse, required this.onChanged});

  final bool browse;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'Pick', selected: !browse, onTap: () => onChanged(false)),
          _Tab(
            label: 'Browse all',
            selected: browse,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
            color: selected ? AppColors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
