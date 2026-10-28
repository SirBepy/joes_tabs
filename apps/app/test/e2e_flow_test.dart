import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/router/app_router.dart';
import 'package:joes_tabs_app/router/app_routes.dart';
import 'package:joes_tabs_app/state/favorites_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

const _riptideUrl =
    'https://www.ukulele-tabs.com/uke-songs/vance-joy/riptide-uke-tab-1.html';

/// A song as the reader leaves it in memory after reading its page: id and
/// source are the page URL, nothing comes from our catalog.
SongWithTabs _readSong() {
  final now = DateTime.utc(2026);
  return SongWithTabs(
    song: webSongStub(_riptideUrl, title: 'Riptide', artist: 'Vance Joy'),
    tabs: [
      Tab(
        id: _riptideUrl,
        songId: _riptideUrl,
        instrumentId: ChordShapes.ukulele,
        content: '{key: G}\n[G]Lady running [C]down\n',
        originalKey: 'G',
        source: TabSource.imported,
        status: TabStatus.published,
        sourceUrl: _riptideUrl,
        sourceSite: 'ukulele-tabs',
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

void main() {
  testWidgets('read song -> transpose -> save the link -> Saved and Home', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final router = buildRouter(
      initialLocation: AppRoutes.songPath(_riptideUrl),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsOverride(),
          // The reader has already put the page's sheet in memory.
          webSongsProvider.overrideWith((ref) => {_riptideUrl: _readSong()}),
          favoritesProvider.overrideWith((ref) => FavoritesNotifier()),
          appDatabaseProvider.overrideWithValue(db),
          // Home's Recently opened is a Drift stream query, which leaves a timer
          // pending past the test; the lists are not under test here.
          recentSongIdsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 1. The song page renders the in-memory sheet, credited to its source.
    expect(find.text('RIPTIDE'), findsOneWidget);
    expect(find.text('Lady running '), findsOneWidget);
    expect(find.text('G'), findsWidgets);
    expect(find.text('G#'), findsNothing);

    // 2. Transpose up a semitone.
    await tester.tap(find.byTooltip('Song controls'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Up a semitone'));
    await tester.pumpAndSettle();
    expect(find.text('G#'), findsWidgets);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // 3. Save it: only the URL goes into favorites.
    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);

    // 4. Saved lists it, named from the URL.
    router.go(AppRoutes.saved);
    await tester.pumpAndSettle();
    expect(find.text('Riptide'), findsOneWidget);
    expect(find.text('Vance Joy'), findsOneWidget);

    // 5. Home lists it under Saved too.
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('Riptide'), findsWidgets);
  });
}
