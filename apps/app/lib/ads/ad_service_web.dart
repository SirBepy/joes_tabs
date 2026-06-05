import 'ad_service.dart';

/// Web factory. AdMob has no Flutter-web support, so this is a no-op that
/// reports `unsupported`. The conditional import in `ad_service.dart` selects
/// this file when `dart:html` is available, which keeps the `google_mobile_ads`
/// plugin out of the web build entirely.
AdService createPlatformAdService() => const _WebAdService();

class _WebAdService implements AdService {
  const _WebAdService();

  @override
  bool get isSupported => false;

  @override
  Future<void> init() async {}

  @override
  Future<AdShowResult> showRewardedAd() async => AdShowResult.unsupported;
}
