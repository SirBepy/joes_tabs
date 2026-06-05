import 'package:flutter/material.dart';

import 'ad_service.dart';

/// Shared "watch a rewarded ad to support us" flow used by both the Settings row
/// and the Support screen button, so the two entry points behave identically.
///
/// Returns the [AdShowResult] (handy for tests / callers that want to route on
/// reward), and shows a friendly snackbar for every outcome so the user is
/// never left staring at a dead button. Never throws.
Future<AdShowResult> runWatchAdFlow(
  BuildContext context,
  AdService service, {
  void Function()? onRewarded,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  if (!service.isSupported) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Ads are available on the mobile app.')),
    );
    return AdShowResult.unsupported;
  }

  messenger.showSnackBar(
    const SnackBar(content: Text('Loading an ad, thank you for the support!')),
  );

  final result = await service.showRewardedAd();
  if (!context.mounted) return result;

  switch (result) {
    case AdShowResult.rewarded:
      messenger.showSnackBar(
        const SnackBar(content: Text('Thanks for the support!')),
      );
      onRewarded?.call();
    case AdShowResult.dismissed:
      messenger.showSnackBar(
        const SnackBar(content: Text('No worries, thanks anyway!')),
      );
    case AdShowResult.noAd:
      messenger.showSnackBar(
        const SnackBar(content: Text('No ad available right now. Try again.')),
      );
    case AdShowResult.unsupported:
      messenger.showSnackBar(
        const SnackBar(content: Text('Ads are available on the mobile app.')),
      );
  }
  return result;
}
