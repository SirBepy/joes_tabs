import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ads/ad_service.dart';
import '../ads/watch_ad_action.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';

/// Support Us / donation screen (per `docs/design/screens/support-us.md`).
///
/// Appreciation copy signed "With love, Joe.", the brand mascot, and two
/// stacked actions: a "Watch Ad" rewarded-ad trigger (mobile only) and a
/// primary orange "Support Us Directly". The direct action leads to the Thank
/// You screen (`/ty`); the ad action routes there once the reward is earned.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adService = ref.watch(adServiceProvider);
    final adsSupported = adService.isSupported;

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
              key: const Key('watch-ad-button'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.peach,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              onPressed: adsSupported
                  ? () => runWatchAdFlow(
                      context,
                      adService,
                      onRewarded: () => context.go(AppRoutes.thankYou),
                    )
                  : null,
              child: const Text(
                'WATCH AD',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (!adsSupported)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Available on the mobile app',
                key: Key('watch-ad-web-note'),
                style: TextStyle(color: AppColors.textDark, fontSize: 12),
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
