import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/screens/saved_screen.dart';
import 'package:joes_tabs_app/state/favorites_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/song_tiles.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

Song _song(String id, String title) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

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
        // Non-empty favorites so the screen renders the list/grid, not the
        // empty state.
        favoritesProvider.overrideWith((ref) => FavoritesNotifier({'a', 'b'})),
        savedSongsProvider.overrideWith(
          (ref) async => [_song('a', 'Song A'), _song('b', 'Song B')],
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
}
