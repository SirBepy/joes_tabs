import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/saved_screen.dart';
import 'package:joes_tabs_app/state/favorites_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/song_tiles.dart';

import 'support/settings_overrides.dart';

const _urlA =
    'https://www.ukulele-tabs.com/uke-songs/some-band/song-a-uke-tab-1.html';
const _urlB =
    'https://www.ukulele-tabs.com/uke-songs/some-band/song-b-uke-tab-2.html';

/// Minimal router so SongListTile's `context.push('/song/:id')` resolves; Saved
/// is mounted at `/saved`.
GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.saved,
  routes: [
    // Wrap in a Scaffold so SongListTile's ListTile has a Material ancestor,
    // mirroring how the AppShell hosts the screen in the real app.
    GoRoute(
      path: AppRoutes.saved,
      builder: (_, _) => const Scaffold(body: SavedScreen()),
    ),
    GoRoute(
      path: AppRoutes.song,
      builder: (_, _) => const Scaffold(body: Text('SONG')),
    ),
  ],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialSettingsOverride(),
        // Two saved links so the screen renders the list/grid, not the empty
        // state.
        favoritesProvider.overrideWith(
          (ref) => FavoritesNotifier({_urlA, _urlB}),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'compact branch: at a narrow (mobile) surface Saved renders the separated '
    'list with dividers, not a grid',
    (tester) async {
      // Force a phone-width surface so the dual-path picks the mobile branch.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(tester);

      // Mobile branch: the untouched separated list (Divider) and no grid.
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Divider), findsWidgets);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(SongListTile), findsNWidgets(2));
    },
  );

  testWidgets(
    'wide branch: at a wide surface Saved renders a grid of the same tiles, '
    'no separated-list dividers',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(tester);

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
      expect(find.byType(SongListTile), findsNWidgets(2));
    },
  );

  testWidgets('lists saved links by their URL slug and skips catalog ids', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsOverride(),
          favoritesProvider.overrideWith(
            (ref) => FavoritesNotifier({_urlA, 'catalog-uuid'}),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SongListTile), findsOneWidget);
    expect(find.text('Song A'), findsOneWidget);
    expect(find.text('Some Band'), findsOneWidget);
  });
}
