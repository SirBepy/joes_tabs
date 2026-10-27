import 'package:data/data.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/song_detail_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

SongWithTabs _song({String? sourceUrl, String? sourceSite}) {
  final now = DateTime.utc(2026, 10, 27);
  return SongWithTabs(
    song: Song(
      id: 's1',
      title: 'Love Like You',
      artist: 'Steven Universe',
      createdAt: now,
      updatedAt: now,
    ),
    tabs: [
      Tab(
        id: 't1',
        songId: 's1',
        instrumentId: 'uke-id',
        content: '[C]If I could begin to be',
        originalKey: '',
        source: sourceUrl == null ? TabSource.official : TabSource.imported,
        status: TabStatus.published,
        sourceUrl: sourceUrl,
        sourceSite: sourceSite,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, SongWithTabs song) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialSettingsOverride(),
        songProvider('s1').overrideWith((ref) async => song),
        instrumentsByIdProvider.overrideWith((ref) async => {}),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const SongDetailScreen(songId: 's1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an imported tab credits its source site', (tester) async {
    await _pump(
      tester,
      _song(
        sourceUrl: 'https://ukulele-tabs.com/love.html',
        sourceSite: 'ukulele-tabs',
      ),
    );
    expect(find.text('Source: Ukulele-tabs.com'), findsOneWidget);
  });

  testWidgets('an unknown site id falls back to the host', (tester) async {
    await _pump(
      tester,
      _song(sourceUrl: 'https://example.org/x', sourceSite: 'gone'),
    );
    expect(find.text('Source: example.org'), findsOneWidget);
  });

  testWidgets('a catalog tab shows no source credit', (tester) async {
    await _pump(tester, _song());
    expect(find.textContaining('Source:'), findsNothing);
  });
}
