import 'package:data/data.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/song_detail_screen.dart';
import 'package:joes_tabs_app/theme/app_colors.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

SongWithTabs _fakeSong() {
  final now = DateTime.utc(2026);
  return SongWithTabs(
    song: Song(
      id: 's1',
      title: 'Amazing Grace',
      artist: 'Traditional',
      createdAt: now,
      updatedAt: now,
    ),
    tabs: [
      Tab(
        id: 't1',
        songId: 's1',
        instrumentId: 'uke-id',
        content: '{key: G}\n[G]Amazing [C]grace\n',
        originalKey: 'G',
        source: TabSource.official,
        status: TabStatus.published,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialSettingsOverride(),
        songProvider('s1').overrideWith((ref) async => _fakeSong()),
        // Instruments map empty -> falls back to ukulele shapes; fine for the
        // render assertions.
        instrumentsByIdProvider.overrideWith((ref) async => {}),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const SongDetailScreen(songId: 's1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The AppBar paints its resolved background on its own Material.
Color? _appBarColor(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(of: find.byType(AppBar), matching: find.byType(Material))
          .first,
    )
    .color;

void main() {
  testWidgets('light theme keeps the orange app bar', (tester) async {
    await _pump(tester, theme: AppTheme.light);

    expect(_appBarColor(tester), AppColors.orange);
    // The bar names the artist; the song's own name heads the page.
    expect(find.text('Ukulele Tabs'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Traditional'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the song controls button is round', (tester) async {
    await _pump(tester);

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.shape, isA<CircleBorder>());
  });

  testWidgets('dark theme uses the dark bar', (tester) async {
    await _pump(tester, theme: AppTheme.dark);

    expect(_appBarColor(tester), AppColors.darkSurface);
    expect(_appBarColor(tester), isNot(AppColors.orange));
  });

  testWidgets('renders the parsed chord sheet (title, lyric, chords)', (
    tester,
  ) async {
    await _pump(tester);

    // Header title (as written) and artist.
    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('Traditional'), findsWidgets);

    // Lyric runs from the parsed sheet.
    expect(find.text('Amazing '), findsOneWidget);
    expect(find.text('grace'), findsOneWidget);

    // Chord G appears both in the diagram strip and over the lyric.
    expect(find.text('G'), findsWidgets);
    // No G# until we transpose.
    expect(find.text('G#'), findsNothing);
  });

  testWidgets('transpose + shifts the displayed chord G -> G#', (tester) async {
    await _pump(tester);

    expect(find.text('G#'), findsNothing);

    // The controls now live in a bottom sheet behind the faders FAB; open it
    // before reaching the transpose buttons.
    await tester.tap(find.byTooltip('Song controls'));
    await tester.pumpAndSettle();

    // Tap the transpose-up control.
    await tester.tap(find.byTooltip('Up a semitone'));
    await tester.pumpAndSettle();

    // Offset readout updated and the chord over the lyric is now G#.
    expect(find.byKey(const Key('transpose-offset')), findsOneWidget);
    final offset = tester.widget<Text>(
      find.byKey(const Key('transpose-offset')),
    );
    expect(offset.data, '+1');
    // C should have become C#, G should have become G# in the sheet.
    expect(find.text('G#'), findsWidgets);
  });

  testWidgets('not-found renders a friendly empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsOverride(),
          songProvider('missing').overrideWith((ref) async => null),
          instrumentsByIdProvider.overrideWith((ref) async => {}),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SongDetailScreen(songId: 'missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Song not found.'), findsOneWidget);
  });
}
