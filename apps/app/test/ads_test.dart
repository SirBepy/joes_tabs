import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/ads/ad_service.dart';
import 'package:joes_tabs_app/ads/watch_ad_action.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/settings_screen.dart';
import 'package:joes_tabs_app/screens/support_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

/// Test double for [AdService]. Records calls and returns a scripted result so
/// no real ad is ever loaded in tests.
class FakeAdService implements AdService {
  FakeAdService({
    required this.isSupported,
    this.result = AdShowResult.rewarded,
  });

  @override
  final bool isSupported;

  /// Result the next [showRewardedAd] call resolves with.
  AdShowResult result;

  int initCalls = 0;
  int showCalls = 0;

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<AdShowResult> showRewardedAd() async {
    showCalls++;
    return result;
  }
}

GoRouter _router(Widget body) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: body),
      ),
      GoRoute(
        path: AppRoutes.thankYou,
        builder: (_, _) =>
            const Scaffold(body: Text('THANK YOU', key: Key('ty-screen'))),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Widget body, FakeAdService ad) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adServiceProvider.overrideWithValue(ad)],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _router(body),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps a single button that runs [runWatchAdFlow] when tapped, capturing the
/// result and any onRewarded invocation. Returns a getter pair via the closures.
Future<void> _pumpFlowButton(
  WidgetTester tester,
  FakeAdService ad, {
  required void Function(AdShowResult) onResult,
  void Function()? onRewarded,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('flow-btn'),
            onPressed: () async {
              final r = await runWatchAdFlow(
                context,
                ad,
                onRewarded: onRewarded,
              );
              onResult(r);
            },
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('runWatchAdFlow outcomes', () {
    testWidgets('rewarded fires onRewarded and returns rewarded', (
      tester,
    ) async {
      final ad = FakeAdService(
        isSupported: true,
        result: AdShowResult.rewarded,
      );
      AdShowResult? got;
      var rewardedCalls = 0;
      await _pumpFlowButton(
        tester,
        ad,
        onResult: (r) => got = r,
        onRewarded: () => rewardedCalls++,
      );
      await tester.tap(find.byKey(const Key('flow-btn')));
      await tester.pumpAndSettle();

      expect(ad.showCalls, 1);
      expect(got, AdShowResult.rewarded);
      expect(rewardedCalls, 1);
    });

    testWidgets('dismissed does NOT fire onRewarded', (tester) async {
      final ad = FakeAdService(
        isSupported: true,
        result: AdShowResult.dismissed,
      );
      AdShowResult? got;
      var rewardedCalls = 0;
      await _pumpFlowButton(
        tester,
        ad,
        onResult: (r) => got = r,
        onRewarded: () => rewardedCalls++,
      );
      await tester.tap(find.byKey(const Key('flow-btn')));
      await tester.pumpAndSettle();

      expect(got, AdShowResult.dismissed);
      expect(rewardedCalls, 0, reason: 'no reward on dismissal');
    });

    testWidgets('noAd returns noAd and never rewards', (tester) async {
      final ad = FakeAdService(isSupported: true, result: AdShowResult.noAd);
      AdShowResult? got;
      var rewardedCalls = 0;
      await _pumpFlowButton(
        tester,
        ad,
        onResult: (r) => got = r,
        onRewarded: () => rewardedCalls++,
      );
      await tester.tap(find.byKey(const Key('flow-btn')));
      await tester.pumpAndSettle();

      expect(got, AdShowResult.noAd);
      expect(rewardedCalls, 0);
    });

    testWidgets('unsupported short-circuits without ever calling the service', (
      tester,
    ) async {
      final ad = FakeAdService(isSupported: false);
      AdShowResult? got;
      var rewardedCalls = 0;
      await _pumpFlowButton(
        tester,
        ad,
        onResult: (r) => got = r,
        onRewarded: () => rewardedCalls++,
      );
      await tester.tap(find.byKey(const Key('flow-btn')));
      await tester.pumpAndSettle();

      expect(got, AdShowResult.unsupported);
      expect(ad.showCalls, 0, reason: 'no ad loaded on unsupported platforms');
      expect(rewardedCalls, 0);
    });
  });

  group('createAdService', () {
    test('returns an unsupported service on the test (VM) platform', () {
      // The conditional import resolves to the mobile file under the Dart VM,
      // whose factory returns the desktop no-op (dart:io present, not mobile).
      final service = createAdService();
      expect(service.isSupported, isFalse);
    });
  });

  group('Settings watch-ad row', () {
    testWidgets('enabled on mobile, tapping invokes the service', (
      tester,
    ) async {
      final ad = FakeAdService(isSupported: true);
      await _pump(tester, const SettingsScreen(), ad);

      // No web caption when supported.
      expect(find.byKey(const Key('watch-ad-web-note')), findsNothing);

      final tile = tester.widget<ListTile>(
        find.byKey(const Key('watch-ad-row')),
      );
      expect(tile.enabled, isTrue);

      await tester.tap(find.byKey(const Key('watch-ad-row')));
      await tester.pump();
      expect(ad.showCalls, 1);
    });

    testWidgets('disabled on web with a caption, tapping does nothing', (
      tester,
    ) async {
      final ad = FakeAdService(isSupported: false);
      await _pump(tester, const SettingsScreen(), ad);

      expect(find.byKey(const Key('watch-ad-web-note')), findsOneWidget);

      final tile = tester.widget<ListTile>(
        find.byKey(const Key('watch-ad-row')),
      );
      expect(tile.enabled, isFalse);
      expect(tile.onTap, isNull);

      await tester.tap(find.byKey(const Key('watch-ad-row')));
      await tester.pump();
      expect(ad.showCalls, 0);
    });
  });

  group('Support screen WATCH AD button', () {
    testWidgets('enabled on mobile; reward routes to thank-you', (
      tester,
    ) async {
      final ad = FakeAdService(
        isSupported: true,
        result: AdShowResult.rewarded,
      );
      await _pump(tester, const SupportScreen(), ad);

      final button = tester.widget<TextButton>(
        find.byKey(const Key('watch-ad-button')),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('watch-ad-button')));
      await tester.pumpAndSettle();

      expect(ad.showCalls, 1);
      expect(find.byKey(const Key('ty-screen')), findsOneWidget);
    });

    testWidgets('no-fill keeps user on screen, no route change', (
      tester,
    ) async {
      final ad = FakeAdService(isSupported: true, result: AdShowResult.noAd);
      await _pump(tester, const SupportScreen(), ad);

      await tester.tap(find.byKey(const Key('watch-ad-button')));
      await tester.pumpAndSettle();

      // No-fill: the service was asked, but no reward and so no route change.
      expect(ad.showCalls, 1);
      expect(find.byKey(const Key('ty-screen')), findsNothing);
    });

    testWidgets('disabled on web with caption; no service call', (
      tester,
    ) async {
      final ad = FakeAdService(isSupported: false);
      await _pump(tester, const SupportScreen(), ad);

      expect(find.byKey(const Key('watch-ad-web-note')), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.byKey(const Key('watch-ad-button')),
      );
      expect(button.onPressed, isNull);
      expect(ad.showCalls, 0);
    });
  });
}
