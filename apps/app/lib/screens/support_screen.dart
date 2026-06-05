import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';

/// Support Us / donation screen (per `docs/design/screens/support-us.md`).
///
/// Appreciation copy signed "With love, Joe.", the brand mascot, and two
/// stacked actions: a muted "Watch Ad" and a primary orange "Support Us
/// Directly". Both lead to the Thank You screen (`/ty`) in this wireframe.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Text(
            'If you find our app useful and would love to support us you can '
            'do so here! Thank you!\n\nWith love, Joe.',
            style: TextStyle(color: AppColors.textDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Expanded(child: Center(child: BrandMascot(size: 200))),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.peach,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              onPressed: () => context.go(AppRoutes.thankYou),
              child: const Text(
                'WATCH AD',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              onPressed: () => context.go(AppRoutes.thankYou),
              child: const Text(
                'SUPPORT US DIRECTLY',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
