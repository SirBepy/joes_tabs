import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/home_screen.dart';
import 'package:joes_tabs_app/state/favorites_provider.dart';
import 'package:joes_tabs_app/theme/app_palette.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String email) => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: email,
  createdAt: DateTime.utc(2026).toIso8601String(),
);

const _url1 =
    'https://www.ukulele-tabs.com/uke-songs/vance-joy/riptide-uke-tab-1.html';
const _url2 =
    'https://www.ukulele-tabs.com/uke-songs/israel-kamakawiwoole/over-the-rainbow-uke-tab-2.html';

Future<void> _pump(
  WidgetTester tester, {
  User? user,
  ThemeData? theme,
  List<String> recent = const [],
  Set<String> saved = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (user != null) currentUserProvider.overrideWithValue(user),
        recentSongIdsProvider.overrideWith((ref) => Stream.value(recent)),
        favoritesProvider.overrideWith((ref) => FavoritesNotifier(saved)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const Scaffold(body: HomeScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _fill(WidgetTester tester, Finder finder) {
  final box = tester.widget<Container>(finder).decoration as BoxDecoration;
  return box.color;
}

void main() {
  testWidgets('anonymous: generic welcome, no user name', (tester) async {
    await _pump(tester);
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Tap Log In to sync your tabs'), findsNothing);
  });

  testWidgets('signed in: greets by the email local part', (tester) async {
    await _pump(tester, user: _user('joe@example.com'));
    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('JOE!'), findsOneWidget);
  });

  group('sign-in card', () {
    testWidgets('signed out: shows the prompt with Log In and Register', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byKey(const Key('home-login-cta')), findsOneWidget);
      expect(
        find.text('Log in to sync your saved tabs across devices.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home-cta-log-in')), findsOneWidget);
      expect(find.byKey(const Key('home-cta-register')), findsOneWidget);
    });

    testWidgets('signed in: no card', (tester) async {
      await _pump(tester, user: _user('joe@example.com'));

      expect(find.byKey(const Key('home-login-cta')), findsNothing);
      expect(find.byKey(const Key('home-cta-log-in')), findsNothing);
      expect(find.byKey(const Key('home-cta-register')), findsNothing);
    });

    testWidgets('dark: card fill and text follow the palette', (tester) async {
      await _pump(tester, theme: AppTheme.dark);

      expect(
        _fill(tester, find.byKey(const Key('home-login-cta'))),
        AppPalette.dark.card,
      );
      final prompt = tester.widget<Text>(
        find.text('Log in to sync your saved tabs across devices.'),
      );
      expect(prompt.style?.color, AppPalette.dark.ink);
    });
  });

  testWidgets('lists recent and saved links, skipping catalog ids', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, recent: [_url1, 'catalog-uuid'], saved: {_url2});

    expect(find.text('RECENTLY OPENED'), findsOneWidget);
    expect(find.text('Riptide'), findsOneWidget);
    expect(find.text('Vance Joy'), findsOneWidget);
    expect(find.text('Over The Rainbow'), findsOneWidget);
  });

  testWidgets('empty lists explain how to fill them', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester);

    expect(
      find.text('Search above to find a song. The ones you open show here.'),
      findsOneWidget,
    );
    expect(
      find.text('No saved songs yet. Tap the bookmark on a song to save it.'),
      findsOneWidget,
    );
  });

  group('dark palette', () {
    testWidgets('song panel and its dividers use palette tokens', (
      tester,
    ) async {
      // Tall enough that the lazy list builds the panels.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, theme: AppTheme.dark, recent: [_url1, _url2]);

      final panels = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color ==
                    AppPalette.dark.card &&
                c.margin != null,
          );
      expect(panels, isNotEmpty);
      final divider = tester.widget<Divider>(find.byType(Divider).first);
      expect(divider.color, AppPalette.dark.divider);
    });
  });
}
