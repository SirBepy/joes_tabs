import 'dart:async';
import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Factory selected when `dart:io` is available. Returns the real AdMob-backed
/// service on Android/iOS, and an unsupported no-op on desktop (where `dart:io`
/// is present but AdMob is not).
AdService createPlatformAdService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return AdMobAdService();
  }
  return const _DesktopAdService();
}

/// Desktop fallback. `dart:io` resolves here too, but AdMob has no desktop
/// plugin, so report unsupported.
class _DesktopAdService implements AdService {
  const _DesktopAdService();

  @override
  bool get isSupported => false;

  @override
  Future<void> init() async {}

  @override
  Future<AdShowResult> showRewardedAd() async => AdShowResult.unsupported;
}

/// AdMob-backed rewarded-ad service for Android/iOS.
///
/// TEST AD IDS: the rewarded unit id below is Google's official Android test
/// unit. Joe replaces it with his real rewarded unit id from his AdMob account
/// once he has one (the matching AdMob *app* id lives in AndroidManifest.xml).
class AdMobAdService implements AdService {
  AdMobAdService();

  /// Google's official Android rewarded-ad TEST unit id. Always returns test
  /// ads, safe to ship in dev/CI. REPLACE with the real unit id later.
  static const String _androidTestRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Google's official iOS rewarded-ad TEST unit id. REPLACE later.
  static const String _iosTestRewardedUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  bool _initialized = false;

  String get _unitId =>
      Platform.isIOS ? _iosTestRewardedUnitId : _androidTestRewardedUnitId;

  @override
  bool get isSupported => true;

  @override
  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  @override
  Future<AdShowResult> showRewardedAd() async {
    await init();

    final ad = await _loadRewardedAd();
    if (ad == null) return AdShowResult.noAd;

    final completer = Completer<AdShowResult>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            earned ? AdShowResult.rewarded : AdShowResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(AdShowResult.noAd);
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
      },
    );

    return completer.future;
  }

  /// Loads a single rewarded ad, completing with `null` on no-fill / load error.
  Future<RewardedAd?> _loadRewardedAd() {
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future;
  }
}
