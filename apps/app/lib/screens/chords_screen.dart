import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/settings_provider.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_shell.dart';
import 'chords/chord_library_view.dart';
import 'chords/chord_picker_view.dart';

/// Chords landing: a "Pick / Browse all" tab host. Pick is the guided picker;
/// Browse all is the grouped-by-root library. Instrument is resolved the same
/// way both views need it (forced to the single played instrument, or the
/// top-bar icon dropdown when more than one is played).
class ChordsScreen extends ConsumerStatefulWidget {
  const ChordsScreen({super.key});

  @override
  ConsumerState<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends ConsumerState<ChordsScreen> {
  bool _browse = false;

  @override
  void initState() {
    super.initState();
    // Register the instrument picker into the section header's actions slot.
    // The widget itself is reactive (it watches the providers), so we only need
    // to register/unregister it with this screen's lifecycle. We register after
    // the first frame because mutating a provider during build is disallowed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sectionActionsProvider.notifier).state = const [
        _InstrumentPickerAction(),
      ];
    });
  }

  @override
  void deactivate() {
    // Clear so other section screens show no stray action. Capture the notifier
    // now (while `ref` is valid) and schedule the reset after this teardown
    // frame: mutating the provider synchronously here would force the sibling
    // SectionHeader to rebuild mid-deactivation, which the framework forbids.
    final actions = ref.read(sectionActionsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Best-effort: if the whole ProviderScope was torn down (e.g. app exit)
      // the controller is already disposed and there is nothing to clear.
      try {
        actions.state = const [];
      } catch (_) {}
    });
    super.deactivate();
  }

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
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Tabs(
              browse: _browse,
              onChanged: (b) => setState(() => _browse = b),
            ),
          ),
        ),
        Expanded(
          // The Chords route caps at kPageMaxWidth so the Browse-all library can
          // use the width. The Pick picker is a reading flow, so self-limit it to
          // kReadingMaxWidth (centered) - below the breakpoint this is a no-op.
          child: _browse
              ? ChordLibraryView(instrument: instrument)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kReadingMaxWidth,
                    ),
                    child: ChordPickerView(instrumentSlug: instrument),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The top-bar instrument picker for the Chords screen: a single [IconButton]
/// showing the currently-viewed instrument's icon that opens a popup menu of
/// `[icon] Name` rows, one per played instrument. Hidden (renders nothing) when
/// only one instrument is played. Reactive, so the icon tracks the selection.
class _InstrumentPickerAction extends ConsumerWidget {
  const _InstrumentPickerAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPicker = ref.watch(showInstrumentPickerProvider);
    if (!showPicker) return const SizedBox.shrink();

    final instruments = ref.watch(instrumentsProvider);
    final selected = ref.watch(selectedInstrumentProvider);
    // Keep the menu in display order regardless of the played-set iteration.
    final ordered = kSupportedInstrumentSlugs
        .where(instruments.contains)
        .toList();

    return PopupMenuButton<String>(
      tooltip: 'Choose instrument',
      icon: Icon(instrumentIcon(selected), color: AppColors.orange),
      onSelected: (slug) =>
          ref.read(selectedInstrumentProvider.notifier).state = slug,
      itemBuilder: (context) => [
        for (final slug in ordered)
          PopupMenuItem<String>(
            value: slug,
            child: Row(
              children: [
                Icon(
                  instrumentIcon(slug),
                  size: 20,
                  color: slug == selected
                      ? AppColors.orange
                      : context.palette.ink,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  instrumentDisplayName(slug),
                  style: TextStyle(
                    fontWeight: slug == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: slug == selected
                        ? AppColors.orange
                        : context.palette.ink,
                  ),
                ),
              ],
            ),
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
        color: context.palette.chip,
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
            color: selected ? AppColors.white : context.palette.ink,
          ),
        ),
      ),
    );
  }
}
