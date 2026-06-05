import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/search_screen.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig:
            router ?? _router(search: const SearchScreen(initialQuery: '')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty query shows the friendly search prompt', (tester) async {
    await _pump(
      tester,
      overrides: [
        // Default to "all" so the filter bar starts on All.
        defaultInstrumentProvider.overrideWith((ref) => ChordShapes.ukulele),
      ],
    );

    expect(
      find.text('Search by song or artist to find a tab.'),
      findsOneWidget,
    );
  });

  testWidgets('results render and are tappable to the song detail', (
    tester,
  ) async {
    await _pump(
      tester,
      router: _router(search: const SearchScreen(initialQuery: 'grace')),
      overrides: [
        defaultInstrumentProvider.overrideWith((ref) => ChordShapes.ukulele),
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
        defaultInstrumentProvider.overrideWith((ref) => ChordShapes.ukulele),
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
        defaultInstrumentProvider.overrideWith((ref) => ChordShapes.ukulele),
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
        defaultInstrumentProvider.overrideWith((ref) => ChordShapes.ukulele),
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
}
