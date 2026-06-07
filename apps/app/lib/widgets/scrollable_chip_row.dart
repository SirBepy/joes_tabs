import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A labelled, single-line horizontally-scrollable single-select chip row, with
/// a right-edge fade hinting more content. Used by the chord picker for Note,
/// sharp/flat, Family and Type. Pure presentation: it owns no selection state.
class ScrollableChipRow extends StatelessWidget {
  const ScrollableChipRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.92, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (final option in options) ...[
                  ChoiceChip(
                    label: Text(option),
                    selected: option == selected,
                    showCheckmark: false,
                    selectedColor: AppColors.orange,
                    backgroundColor: AppColors.peach,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: option == selected
                          ? AppColors.white
                          : AppColors.rust,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => onSelected(option),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
