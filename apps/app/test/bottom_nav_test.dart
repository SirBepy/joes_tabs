import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'support/settings_overrides.dart';

/// Records sign-outs; every other [AuthService] member is unused here.
class _FakeAuthService implements AuthService {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps the real router at [location] on a [width] x [height] logical surface.
Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  double width = 390,
  double height = 700,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = inMemoryAppDatabase();
  addTearDown(db.close);
  final router = buildRouter(initialLocation: location);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseOverride(db),
        initialSettingsOverride(instrumentSlugs: const []),
        ...overrides,
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// The scrollable of the page currently shown (the first one in tree order is
/// the active tab's vertical list; hidden tabs are offstage).
ScrollableState _pageScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first);

/// Counts `SystemNavigator.pop` calls, which is how the app exits.
List<MethodCall> _recordExits(WidgetTester tester) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') calls.add(call);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  group('destinations', () {
    testWidgets('five tabs in order with Home selected', (tester) async {
      await _pumpApp(tester);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final labels = bar.destinations
          .cast<NavigationDestination>()
          .map((d) => d.label)
          .toList();
      expect(labels, ['Tuner', 'Chords', 'Home', 'Saved', 'Settings']);
      expect(bar.selectedIndex, 2);
    });

    testWidgets('tapping a tab navigates to it', (tester) async {
      final router = await _pumpApp(tester);

      for (final (label, route) in [
        ('Tuner', AppRoutes.tuner),
        ('Chords', AppRoutes.chords),
        ('Saved', AppRoutes.saved),
        ('Settings', AppRoutes.settings),
        ('Home', AppRoutes.home),
      ]) {
        await tester.tap(_tab(label));
        await tester.pumpAndSettle();
        expect(_path(router), route, reason: label);
      }
    });

    testWidgets('the selected tab follows the route', (tester) async {
      await _pumpApp(tester, location: AppRoutes.saved);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 3);
    });

    testWidgets('has no drawer and no hamburger', (tester) async {
      await _pumpApp(tester);

      expect(find.byType(Drawer), findsNothing);
      expect(find.byTooltip('Menu'), findsNothing);
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).first).hasDrawer,
        isFalse,
      );
    });

    testWidgets('top-level tabs show no back circle', (tester) async {
      await _pumpApp(tester, location: AppRoutes.saved);

      expect(find.bySemanticsLabel('Back'), findsNothing);
    });
  });

  group('responsive layout', () {
    testWidgets('phone width uses the bottom bar', (tester) async {
      await _pumpApp(tester, width: 599);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('width >= 600 uses the rail with the same order', (
      tester,
    ) async {
      await _pumpApp(tester, width: 600);

      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      final labels = rail.destinations
          .map((d) => (d.label as Text).data)
          .toList();
      expect(labels, ['Tuner', 'Chords', 'Home', 'Saved', 'Settings']);
      expect(rail.selectedIndex, 2);
    });

    testWidgets('reflows when the window is resized', (tester) async {
      await _pumpApp(tester, width: 390);
      expect(find.byType(NavigationBar), findsOneWidget);

      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      tester.view.physicalSize = const Size(390, 700);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('rail taps navigate', (tester) async {
      final router = await _pumpApp(tester, width: 900);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Saved'),
        ),
      );
      await tester.pumpAndSettle();

      expect(_path(router), AppRoutes.saved);
    });
  });

  group('tab state and re-tap', () {
    testWidgets('a tab keeps its scroll position while another is shown', (
      tester,
    ) async {
      await _pumpApp(tester, height: 500);
      expect(_pageScroll(tester).position.maxScrollExtent, greaterThan(0));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      final offset = _pageScroll(tester).position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(_tab('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(_tab('Home'));
      await tester.pumpAndSettle();

      expect(_pageScroll(tester).position.pixels, offset);
    });

    testWidgets('tapping the active tab scrolls it to the top', (tester) async {
      await _pumpApp(tester, height: 500);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_pageScroll(tester).position.pixels, greaterThan(0));

      await tester.tap(_tab('Home'));
      await tester.pumpAndSettle();

      expect(_pageScroll(tester).position.pixels, 0);
    });

    testWidgets('tapping the active tab pops its pushed pages first', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location: AppRoutes.settings);
      router.push(AppRoutes.support);
      await tester.pumpAndSettle();
      expect(find.text('SUPPORT US'), findsOneWidget);

      await tester.tap(_tab('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('SUPPORT US'), findsNothing);
      expect(find.byKey(const Key('account-log-in')), findsOneWidget);
    });
  });

  group('system back', () {
    testWidgets('Home scrolled down: back scrolls to the top, not exit', (
      tester,
    ) async {
      final exits = _recordExits(tester);
      await _pumpApp(tester, height: 500);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_pageScroll(tester).position.pixels, greaterThan(0));

      await _pressBack(tester);

      expect(_pageScroll(tester).position.pixels, 0);
      expect(find.text('Press back again to exit'), findsNothing);
      expect(exits, isEmpty);
    });

    testWidgets('Home at the top: back prompts, a second back exits', (
      tester,
    ) async {
      final exits = _recordExits(tester);
      await _pumpApp(tester);

      await _pressBack(tester);
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(exits, isEmpty);

      await _pressBack(tester);
      expect(exits, hasLength(1));
    });

    testWidgets('the exit prompt resets after two seconds', (tester) async {
      final exits = _recordExits(tester);
      await _pumpApp(tester);

      await _pressBack(tester);
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();

      await _pressBack(tester);
      // Back to the first press: prompted again rather than exiting.
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(exits, isEmpty);
    });

    testWidgets('an armed exit does not leak onto another tab', (tester) async {
      final exits = _recordExits(tester);
      final router = await _pumpApp(tester);

      await _pressBack(tester);
      await tester.tap(_tab('Settings'));
      await tester.pumpAndSettle();
      await _pressBack(tester);

      expect(_path(router), AppRoutes.home);
      expect(exits, isEmpty);
    });

    testWidgets('a pushed page in a tab pops before anything else', (
      tester,
    ) async {
      final exits = _recordExits(tester);
      final router = await _pumpApp(tester, location: AppRoutes.trending);
      expect(_path(router), AppRoutes.trending);

      await _pressBack(tester);

      expect(_path(router), AppRoutes.home);
      expect(find.text('Press back again to exit'), findsNothing);
      expect(exits, isEmpty);
    });

    testWidgets('an open dialog closes before back switches tab', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location: AppRoutes.settings);
      showDialog<void>(
        context: tester.element(find.byType(Scaffold).first),
        builder: (_) => const AlertDialog(content: Text('hello dialog')),
      );
      await tester.pumpAndSettle();

      await _pressBack(tester);

      expect(find.text('hello dialog'), findsNothing);
      expect(_path(router), AppRoutes.settings);
    });
  });

  group('Trending and Support pages', () {
    testWidgets('Trending keeps the bar and a back button that pops', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      router.go(AppRoutes.trending);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(_path(router), AppRoutes.home);
    });

    testWidgets('Support Us opened by deep link: back goes to Settings', (
      tester,
    ) async {
      // Nothing sits beneath the page, so the back circle falls back.
      final router = await _pumpApp(tester, location: AppRoutes.support);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(_path(router), AppRoutes.settings);
    });

    testWidgets('Support Us keeps the bar and its back circle pops', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location: AppRoutes.settings);
      router.push(AppRoutes.support);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('SUPPORT US'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(_path(router), AppRoutes.settings);
    });
  });

  group('Settings account section', () {
    testWidgets('signed out: Log In and Register push their screens', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location: AppRoutes.settings);
      expect(find.byKey(const Key('account-log-in')), findsOneWidget);
      expect(find.byKey(const Key('account-register')), findsOneWidget);
      expect(find.byKey(const Key('account-log-out')), findsNothing);

      await tester.tap(find.byKey(const Key('account-log-in')));
      await tester.pumpAndSettle();
      expect(_path(router), AppRoutes.login);
    });

    testWidgets('signed out: Register pushes the register screen', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location: AppRoutes.settings);

      await tester.tap(find.byKey(const Key('account-register')));
      await tester.pumpAndSettle();

      expect(_path(router), AppRoutes.register);
    });

    testWidgets('signed in: shows the email and Log Out signs out', (
      tester,
    ) async {
      final auth = _FakeAuthService();
      await _pumpApp(
        tester,
        location: AppRoutes.settings,
        overrides: [
          currentUserProvider.overrideWithValue(
            User(
              id: 'user-1',
              appMetadata: const {},
              userMetadata: const {},
              aud: 'authenticated',
              createdAt: '2026-01-01T00:00:00Z',
              email: 'joe@example.com',
            ),
          ),
          authServiceProvider.overrideWithValue(auth),
        ],
      );
      expect(find.text('joe@example.com'), findsOneWidget);
      expect(find.byKey(const Key('account-log-in')), findsNothing);
      expect(find.byKey(const Key('account-register')), findsNothing);

      await tester.tap(find.byKey(const Key('account-log-out')));
      await tester.pump();

      expect(auth.signOutCalls, 1);
    });

    testWidgets('Support Us row opens the Support page', (tester) async {
      final router = await _pumpApp(tester, location: AppRoutes.settings);

      await tester.scrollUntilVisible(
        find.byKey(const Key('support-us-row')),
        200,
      );
      await tester.tap(find.byKey(const Key('support-us-row')));
      await tester.pumpAndSettle();

      expect(_path(router), AppRoutes.support);
      expect(find.text('SUPPORT US'), findsOneWidget);
    });
  });
}
