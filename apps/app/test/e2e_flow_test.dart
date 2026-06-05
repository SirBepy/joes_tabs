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

/// In-memory catalog the whole flow runs against: a couple of seeded songs with
/// a published ukulele tab each, so trending, the song detail (chord render +
/// transpose), and the saved-back-fill all resolve without a network.
class _FakeCatalog implements CatalogRepository {
  _FakeCatalog(this._songs, this._details);

  final List<Song> _songs;
  final Map<String, SongWithTabs> _details;

  @override
  Future<List<Song>> trending({int limit = 20}) async => _songs;

  @override
  Future<List<Song>> listSongs({
    String? instrumentSlug,
    int limit = 50,
  }) async => _songs;

  @override
  Future<List<Song>> search(String query) async => _songs;

  @override
  Future<List<Song>> searchSongs(
    String query, {
    String? instrumentSlug,
  }) async => _songs;

  @override
  Future<SongWithTabs?> getSong(String id) async => _details[id];

  @override
  Future<List<Instrument>> instruments() async => const <Instrument>[];
}

SongWithTabs _seed(String id, String title, String content) {
  final now = DateTime.utc(2026);
  return SongWithTabs(
    song: Song(
      id: id,
      title: title,
      artist: 'Traditional',
      createdAt: now,
      updatedAt: now,
    ),
    tabs: [
      Tab(
        id: '$id-t1',
        songId: id,
        instrumentId: 'uke-id',
        content: content,
        originalKey: 'G',
        source: TabSource.official,
        status: TabStatus.published,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

void main() {
  testWidgets('full journey: home -> song -> transpose -> favorite -> saved', (
    tester,
  ) async {
    final grace = _seed(
      's1',
      'Amazing Grace',
      '{key: G}\n[G]Amazing [C]grace\n',
    );
    final river = _seed('s2', 'Moon River', '{key: G}\n[G]Moon [D]river\n');
    final details = {grace.song.id: grace, river.song.id: river};
    final songs = [grace.song, river.song];

    final router = buildRouter(initialLocation: AppRoutes.home);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Real provider graph, fake data source: trending / getSong /
          // instruments all flow through this one repository.
          catalogRepositoryProvider.overrideWithValue(
            _FakeCatalog(songs, details),
          ),
          // In-memory favorites (the base notifier, no Drift) so toggling on
          // the detail screen is observable on Home + Saved.
          favoritesProvider.overrideWith((ref) => FavoritesNotifier()),
          // In-memory Drift cache so the Saved screen's cache-first lookup
          // resolves (it back-fills the favorited song from trending). Without
          // this the default opens a file-backed sqlite db that never settles
          // under flutter test.
          appDatabaseProvider.overrideWithValue(
            AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Home shows the seeded trending list.
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('Moon River'), findsOneWidget);

    // 2. Tap a trending song -> lands on its detail (chord sheet renders).
    //    The trending panel can sit below the fold on the small test surface
    //    (the welcome mascot pushes it down), so scroll it into view first.
    await tester.ensureVisible(find.text('Amazing Grace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();
    expect(find.text('AMAZING GRACE'), findsOneWidget); // header (upper-cased)
    expect(find.text('Amazing '), findsOneWidget); // lyric run from the sheet
    expect(find.text('G'), findsWidgets); // chord G in strip + over the lyric
    expect(find.text('G#'), findsNothing); // not transposed yet

    // 3. Transpose up a semitone -> G becomes G# in the rendered sheet.
    await tester.tap(find.byTooltip('Up a semitone'));
    await tester.pumpAndSettle();
    final offset = tester.widget<Text>(
      find.byKey(const Key('transpose-offset')),
    );
    expect(offset.data, '+1');
    expect(find.text('G#'), findsWidgets);

    // 4. Favorite the song -> the heart tooltip flips to "Remove favorite".
    expect(find.byTooltip('Add favorite'), findsOneWidget);
    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);

    // 5. Back to the shell, open the drawer, go to Saved -> the favorited song
    //    is listed there.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Menu'), findsOneWidget); // back in the shell

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved Tabs'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.saved,
    );
    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('Moon River'), findsNothing); // only the favorited one

    // 6. Navigate to Trending and back to Home to confirm shell nav works.
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trending'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.trending,
    );
    expect(find.text('TRENDING'), findsWidgets);
    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('Moon River'), findsOneWidget);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
  });
}
