import 'package:flutter/material.dart' hide Tab;
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Brand-styled bottom sheet that hosts the song playback controls (instrument
/// toggle, transpose, autoscroll). Per `docs/design/screens/tabs-screen.md`,
/// the song screen keeps the chord strip and the sheet as the dominant
/// surfaces; these controls live behind the floating faders button.
///
/// The sheet owns NO control state. Every value is read from the supplied
/// snapshot and every change is routed back through the callbacks so the
/// screen's [State] remains the single source of truth. A [StatefulBuilder]
/// wraps the body so that, after the screen rebuilds and calls our refresh,
/// the open sheet redraws in lockstep with the view behind it.
typedef SheetRefresh = void Function(VoidCallback rebuild);

/// Opens the controls sheet. The caller passes live getters (so each rebuild
/// reads the freshest screen state) and mutation callbacks (which drive the
/// screen's [setState], updating both the sheet and the view underneath).
Future<void> showSongControlsSheet(
  BuildContext context, {
  required List<Tab> tabs,
  required Map<String, Instrument>? instruments,
  required int Function() selectedTab,
  required ValueChanged<int> onTabChanged,
  required int Function() transpose,
  required String Function() shownKey,
  required int? Function() capo,
  required ValueChanged<int> onTranspose,
  required VoidCallback onResetTranspose,
  required bool Function() scrolling,
  required double Function() speed,
  required VoidCallback onToggleScroll,
  required ValueChanged<double> onSpeed,
  required void Function(VoidCallback register) registerRefresh,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          // Let the screen ask us to redraw so the sheet mirrors live changes
          // (e.g. transpose readout, play/pause) made while it is open.
          registerRefresh(() => setSheetState(() {}));
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controls',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (tabs.length > 1) ...[
                    _InstrumentToggle(
                      tabs: tabs,
                      instruments: instruments,
                      selected: selectedTab(),
                      onChanged: onTabChanged,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _TransposeRow(
                    transpose: transpose(),
                    shownKey: shownKey(),
                    capo: capo(),
                    onTranspose: onTranspose,
                    onReset: onResetTranspose,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AutoscrollRow(
                    scrolling: scrolling(),
                    speed: speed(),
                    onToggle: onToggleScroll,
                    onSpeed: onSpeed,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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
    return SegmentedButton<int>(
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
    );
  }
}

class _TransposeRow extends StatelessWidget {
  const _TransposeRow({
    required this.transpose,
    required this.shownKey,
    required this.capo,
    required this.onTranspose,
    required this.onReset,
  });

  final int transpose;
  final String shownKey;
  final int? capo;
  final ValueChanged<int> onTranspose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
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
        if (shownKey.isNotEmpty)
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

class _AutoscrollRow extends StatelessWidget {
  const _AutoscrollRow({
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
