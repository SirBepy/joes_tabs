import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/search_screen.dart';
import 'package:joes_tabs_app/state/favorites_provider.dart';
import 'package:joes_tabs_app/theme/app_colors.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/song_tiles.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

final _love = Uri.parse(
  'https://www.ukulele-tabs.com/uke-songs/rebecca-sugar/love-like-you-uke-tab-1.html',
);

WebSearchResult _result(Uri url, String title, String? artist) =>
    WebSearchResult(
      title: title,
      artist: artist,
      url: url,
      description: '',
      site: WebTabSite.ukuleleTabs,
    );

/// Search at `/search`; the web-tab reader echoes what it was asked to open.
GoRouter _router({required Widget search}) => GoRouter(
  initialLocation: AppRoutes.search,
  routes: [
    GoRoute(path: AppRoutes.search, builder: (_, _) => search),
    GoRoute(
      path: AppRoutes.webTab,
      builder: (_, state) => Scaffold(
        body: Text(
          'READ ${state.uri.queryParameters['url']} '
          '${state.uri.queryParameters['artist']}',
        ),
      ),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  String query = '',
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride(), ...overrides],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: _router(search: SearchScreen(initialQuery: query)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dark mode types dark text on the white search field', (
    tester,
  ) async {
    await _pump(tester, theme: AppTheme.dark, overrides: const []);

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.style.color, AppColors.textDark);
  });

  testWidgets('empty query explains what is searched', (tester) async {
    await _pump(tester, overrides: const []);
    expect(
      find.text('Search ukulele-tabs.com by song or artist to find a tab.'),
      findsOneWidget,
    );
  });

  testWidgets('lists ukulele-tabs.com results signed out', (tester) async {
    await _pump(
      tester,
      query: 'love',
      overrides: [
        webSearchProvider('love').overrideWith(
          (ref) async => [_result(_love, 'Love Like You', 'Rebecca Sugar')],
        ),
      ],
    );

    expect(find.byType(SongListTile), findsOneWidget);
    expect(find.text('Love Like You'), findsOneWidget);
    expect(find.text('Rebecca Sugar'), findsOneWidget);
  });

  testWidgets('a result opens the reader with its URL and artist', (
    tester,
  ) async {
    await _pump(
      tester,
      query: 'love',
      overrides: [
        webSearchProvider('love').overrideWith(
          (ref) async => [_result(_love, 'Love Like You', 'Rebecca Sugar')],
        ),
      ],
    );

    await tester.tap(find.text('Love Like You'));
    await tester.pumpAndSettle();
    expect(find.text('READ $_love Rebecca Sugar'), findsOneWidget);
  });

  testWidgets('the bookmark saves only the link', (tester) async {
    final favorites = FavoritesNotifier();
    await _pump(
      tester,
      query: 'love',
      overrides: [
        favoritesProvider.overrideWith((ref) => favorites),
        webSearchProvider('love').overrideWith(
          (ref) async => [_result(_love, 'Love Like You', 'Rebecca Sugar')],
        ),
      ],
    );

    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(favorites.state, {_love.toString()});
  });

  testWidgets('no results says so', (tester) async {
    await _pump(
      tester,
      query: 'zzz',
      overrides: [webSearchProvider('zzz').overrideWith((ref) async => [])],
    );
    expect(find.text('No songs found for "zzz".'), findsOneWidget);
  });

  testWidgets('a failed search says the site was unreachable', (tester) async {
    await _pump(
      tester,
      query: 'boom',
      overrides: [
        webSearchProvider(
          'boom',
        ).overrideWith((ref) async => throw Exception('503')),
      ],
    );
    expect(
      find.text("Couldn't reach ukulele-tabs.com. Please try again."),
      findsOneWidget,
    );
  });

  test('numbers only results whose title and artist repeat', () {
    Uri u(int n) => Uri.parse('https://www.ukulele-tabs.com/x-uke-tab-$n.html');
    final versions = searchVersions([
      _result(u(1), 'Giant Woman', 'Rebecca Sugar'),
      _result(u(2), 'Giant Woman (steven Universe)', 'Rebecca Sugar'),
      _result(u(3), 'giant woman', 'rebecca sugar'),
      _result(u(4), 'Giant Woman', 'Steven Universe'),
      _result(u(5), 'Giant Woman', 'Rebecca Sugar'),
    ]);
    expect(versions, [1, null, 2, null, 3]);
  });

  testWidgets('same-named results show which version each is', (tester) async {
    final other = Uri.parse(
      'https://www.ukulele-tabs.com/uke-songs/rebecca-sugar/love-like-you-uke-tab-2.html',
    );
    await _pump(
      tester,
      query: 'love',
      overrides: [
        webSearchProvider('love').overrideWith(
          (ref) async => [
            _result(_love, 'Love Like You', 'Rebecca Sugar'),
            _result(other, 'Love Like You', 'Rebecca Sugar'),
          ],
        ),
      ],
    );

    expect(find.text('Rebecca Sugar · Version 1'), findsOneWidget);
    expect(find.text('Rebecca Sugar · Version 2'), findsOneWidget);
  });
}
