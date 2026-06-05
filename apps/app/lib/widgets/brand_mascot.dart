import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';

/// Brand mascot placeholder: the orange ukulele character inside a peach circle.
///
/// TODO(design): replace the Phosphor guitar glyph with the orange ukulele
/// mascot illustration once the brand asset is delivered. Kept as a single
/// widget so every screen (Tuner, Support, Thank You, log-out dialog) shares one
/// placeholder and swaps in one place later.
class BrandMascot extends StatelessWidget {
  const BrandMascot({super.key, this.size = 160, this.icon});

  /// Diameter of the peach circle.
  final double size;

  /// Override glyph; defaults to a filled guitar.
  final PhosphorIconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.peach,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon ?? PhosphorIconsFill.guitar,
        size: size * 0.5,
        color: AppColors.orange,
      ),
    );
  }
}
