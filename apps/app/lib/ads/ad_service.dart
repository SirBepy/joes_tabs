import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_service_stub.dart'
    if (dart.library.io) 'ad_service_mobile.dart'
    if (dart.library.html) 'ad_service_web.dart';

/// Outcome of attempting to show a rewarded ad.
enum AdShowResult {
  /// The user watched the ad to the end and earned the reward.
  rewarded,

  /// The ad was shown but dismissed before the reward was earned, or it
  /// finished without granting a reward.
  dismissed,

  /// No ad was available to show (no fill / failed to load).
  noAd,

  /// Rewarded ads are not available on this platform (e.g. web / desktop).
  unsupported,
}

/// Abstraction over the rewarded-ad backend so the UI never touches the
/// `google_mobile_ads` plugin directly. This keeps the widgets testable with a
/// fake and lets web/desktop swap in a no-op implementation via the conditional
/// import in this file.
abstract interface class AdService {
  /// Whether rewarded ads can run on the current platform at all. `false` on
  /// web/desktop; `true` on Android/iOS. The UI uses this to enable or disable
  /// the "watch an ad" controls.
  bool get isSupported;

  /// Initialize the underlying ad SDK. Safe to call multiple times; later calls
  /// are no-ops. A no-op on unsupported platforms.
  Future<void> init();

  /// Show a rewarded ad, loading one first if needed. Resolves with the
  /// [AdShowResult] describing what happened. Never throws.
  Future<AdShowResult> showRewardedAd();
}

/// Constructs the platform-appropriate [AdService]. Resolved at compile time by
/// the conditional import above: AdMob on mobile, a no-op on web/desktop.
AdService createAdService() => createPlatformAdService();

/// App-wide [AdService]. Kept alive for the session so a loaded ad survives
/// navigation between Settings and the Support screen. In-memory only; no
/// persistence is appropriate for ad state.
final adServiceProvider = Provider<AdService>((ref) => createAdService());
