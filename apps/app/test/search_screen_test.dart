import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/search_screen.dart';
import 'package:joes_tabs_app/theme/app_colors.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/song_tiles.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'support/settings_overrides.dart';

Song _song(String id, String title, {String artist = 'Artist'}) => Song(
  id: id,
  title: title,
  artist: artist,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Minimal router so SongListTile's `context.push('/song/:id')` resolves and we
/// can assert navigation. The search screen is mounted at `/search`.
GoRouter _router({required Widget search}) {
  String? landed;
  return GoRouter(
    initialLocation: AppRoutes.search,
    routes: [
      GoRoute(path: AppRoutes.search, builder: (_, _) => search),
      GoRoute(
        path: AppRoutes.song,
        builder: (_, state) {
          landed = state.pathParameters['id'];
          return Scaffold(body: Text('SONG ${landed ?? ''}'));
        },
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  GoRouter? router,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig:
            router ?? _router(search: const SearchScreen(initialQuery: '')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dark mode types dark text on the white search field', (
    tester,
  ) async {
    await _pump(
      tester,
      theme: AppTheme.dark,
      overrides: [initialSettingsOverride()],
    );

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.style.color, AppColors.textDark);
  });

  testWidgets('empty query shows the friendly search prompt', (tester) async {
    await _pump(
      tester,
      overrides: [
        // Default to "all" so the filter bar starts on All.
        initialSettingsOverride(),
      ],
    );

    expect(
      find.text('Search by song or artist to find a tab.'),
      findsOneWidget,
    );
  });

  for (final (label, size, grid) in [
    ('compact', const Size(390, 844), false),
    ('wide', const Size(1100, 900), true),
  ]) {
    testWidgets(
      '$label surface lays results out as a ${grid ? 'grid' : 'list'}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pump(
          tester,
          router: _router(search: const SearchScreen(initialQuery: 'song')),
          overrides: [
            initialSettingsOverride(),
            searchFilteredProvider((
              query: 'song',
              instrumentSlug: ChordShapes.ukulele,
            )).overrideWith(
              (ref) async => [_song('a', 'Song A'), _song('b', 'Song B')],
            ),
          ],
        );

        // A sliver grid, since the web-results footer needs a full-width row.
        expect(find.byType(SliverGrid), grid ? findsOneWidget : findsNothing);
        expect(find.byType(SongListTile), findsNWidgets(2));
        expect(find.text('FROM THE WEB'), findsOneWidget);
      },
    );
  }

  testWidgets('results render and are tappable to the song detail', (
    tester,
  ) async {
    await _pump(
      tester,
      router: _router(search: const SearchScreen(initialQuery: 'grace')),
      overrides: [
        initialSettingsOverride(),
        // Override the filtered provider for the seeded query under the default
        // (ukulele) filter so the results render deterministically.
        searchFilteredProvider((
          query: 'grace',
          instrumentSlug: ChordShapes.ukulele,
        )).overrideWith((ref) async => [_song('s1', 'Amazing Grace')]),
      ],
    );

    expect(find.text('Amazing Grace'), findsOneWidget);

    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();

    // Navigating to the song detail proves the row is tappable to /song/:id.
    expect(find.text('SONG s1'), findsOneWidget);
  });

  testWidgets('no-results query shows the empty state with the query', (
    tester,
  ) async {
    await _pump(
      tester,
      router: _router(search: const SearchScreen(initialQuery: 'zzz')),
      overrides: [
        initialSettingsOverride(),
        searchFilteredProvider((
          query: 'zzz',
          instrumentSlug: ChordShapes.ukulele,
        )).overrideWith((ref) async => const <Song>[]),
      ],
    );

    expect(find.text('No songs found for "zzz".'), findsOneWidget);
  });

  testWidgets('error state shows a friendly message', (tester) async {
    await _pump(
      tester,
      router: _router(search: const SearchScreen(initialQuery: 'boom')),
      overrides: [
        initialSettingsOverride(),
        searchFilteredProvider((
          query: 'boom',
          instrumentSlug: ChordShapes.ukulele,
        )).overrideWith((ref) async => throw Exception('network')),
      ],
    );

    expect(find.text('Search failed. Please try again.'), findsOneWidget);
  });

  testWidgets('switching the instrument filter narrows results', (
    tester,
  ) async {
    await _pump(
      tester,
      router: _router(search: const SearchScreen(initialQuery: 'song')),
      overrides: [
        // Start on the default (ukulele) filter: two songs have uke tabs.
        initialSettingsOverride(),
        searchFilteredProvider((
          query: 'song',
          instrumentSlug: ChordShapes.ukulele,
        )).overrideWith(
          (ref) async => [_song('a', 'Song A'), _song('b', 'Song B')],
        ),
        // Guitar has only one matching tab.
        searchFilteredProvider((
          query: 'song',
          instrumentSlug: ChordShapes.guitar,
        )).overrideWith((ref) async => [_song('a', 'Song A')]),
      ],
    );

    // Ukulele (default) shows both.
    expect(find.text('Song A'), findsOneWidget);
    expect(find.text('Song B'), findsOneWidget);

    // Tap the Guitar filter chip.
    await tester.tap(find.text('Guitar'));
    await tester.pumpAndSettle();

    // Now only the guitar-tabbed song remains.
    expect(find.text('Song A'), findsOneWidget);
    expect(find.text('Song B'), findsNothing);
  });

  group('from the web', () {
    List<Override> emptyCatalog(String query) => [
      initialSettingsOverride(),
      searchFilteredProvider((
        query: query,
        instrumentSlug: ChordShapes.ukulele,
      )).overrideWith((ref) async => const <Song>[]),
    ];

    testWidgets('signed out, it offers log in instead of searching', (
      tester,
    ) async {
      var searched = false;
      await _pump(
        tester,
        router: _router(search: const SearchScreen(initialQuery: 'su')),
        overrides: [
          ...emptyCatalog('su'),
          webSearchProvider('su').overrideWith((ref) async {
            searched = true;
            return const [];
          }),
        ],
      );

      expect(find.text('No songs found for "su".'), findsOneWidget);
      expect(
        find.text('Log in to search chord sites on the web'),
        findsOneWidget,
      );
      expect(searched, isFalse);
    });

    testWidgets('signed in, it lists pages with their site', (tester) async {
      await _pump(
        tester,
        router: _router(search: const SearchScreen(initialQuery: 'su')),
        overrides: [
          ...emptyCatalog('su'),
          currentUserProvider.overrideWith((ref) => _user()),
          webSearchProvider('su').overrideWith(
            (ref) async => [
              WebSearchResult(
                title: 'Love Like You Ukulele Tabs by Steven Universe',
                url: Uri.parse('https://ukulele-tabs.com/love.html'),
                description: '',
                site: WebTabSite.ukuleleTabs,
              ),
              WebSearchResult(
                title: 'HERE COMES A THOUGHT CHORDS by Steven Universe',
                url: Uri.parse('https://tabs.ultimate-guitar.com/tab/x'),
                description: '',
                site: WebTabSite.ultimateGuitar,
              ),
            ],
          ),
        ],
      );

      expect(find.text('Love Like You'), findsOneWidget);
      expect(find.text('Steven Universe · Ukulele-tabs.com'), findsOneWidget);
      expect(find.text('HERE COMES A THOUGHT'), findsOneWidget);
      // Ultimate Guitar is link-only: marked as opening in the browser.
      expect(find.byIcon(PhosphorIconsRegular.arrowSquareOut), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.caretRight), findsOneWidget);
    });

    testWidgets('an already imported page opens its song', (tester) async {
      await _pump(
        tester,
        router: _router(search: const SearchScreen(initialQuery: 'su')),
        overrides: [
          ...emptyCatalog('su'),
          currentUserProvider.overrideWith((ref) => _user()),
          webSearchProvider('su').overrideWith(
            (ref) async => [
              WebSearchResult(
                title: 'Love Like You by Steven Universe',
                url: Uri.parse('https://ukulele-tabs.com/love.html'),
                description: '',
                site: WebTabSite.ukuleleTabs,
                songId: 's9',
              ),
            ],
          ),
        ],
      );

      await tester.tap(find.text('Love Like You'));
      await tester.pumpAndSettle();
      expect(find.text('SONG s9'), findsOneWidget);
    });

    testWidgets('a failed web search keeps the catalog results', (
      tester,
    ) async {
      await _pump(
        tester,
        router: _router(search: const SearchScreen(initialQuery: 'grace')),
        overrides: [
          initialSettingsOverride(),
          searchFilteredProvider((
            query: 'grace',
            instrumentSlug: ChordShapes.ukulele,
          )).overrideWith((ref) async => [_song('s1', 'Amazing Grace')]),
          currentUserProvider.overrideWith((ref) => _user()),
          webSearchProvider(
            'grace',
          ).overrideWith((ref) async => throw Exception('502')),
        ],
      );

      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('Web search is unavailable right now.'), findsOneWidget);
    });
  });
}

User _user() => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.utc(2026).toIso8601String(),
);
