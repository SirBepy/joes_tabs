import 'ad_service.dart';

/// Fallback factory used when neither `dart:io` nor `dart:html` is available
/// (an unusual target). Returns an unsupported, no-op service so the app still
/// compiles and runs without ads.
AdService createPlatformAdService() => const _UnsupportedAdService();

class _UnsupportedAdService implements AdService {
  const _UnsupportedAdService();

  @override
  bool get isSupported => false;

  @override
  Future<void> init() async {}

  @override
  Future<AdShowResult> showRewardedAd() async => AdShowResult.unsupported;
}
