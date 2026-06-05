import 'package:flutter/material.dart';
import 'package:models/models.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A pill segmented control to switch between ukulele and guitar.
///
/// Emits the instrument slug (`ChordShapes.ukulele` / `ChordShapes.guitar`).
/// Used by the Chords screen and the Tuner so the instrument choice is a single
/// consistent control.
class InstrumentToggle extends StatelessWidget {
  const InstrumentToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Current instrument slug.
  final String value;

  /// Called with the newly selected slug.
  final ValueChanged<String> onChanged;

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
          _Segment(
            label: 'Ukulele',
            selected: value == ChordShapes.ukulele,
            onTap: () => onChanged(ChordShapes.ukulele),
          ),
          _Segment(
            label: 'Guitar',
            selected: value == ChordShapes.guitar,
            onTap: () => onChanged(ChordShapes.guitar),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
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
