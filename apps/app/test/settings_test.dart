import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/settings_screen.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

late WidgetRef _ref;
late AppDatabase _db;

Future<void> _pump(WidgetTester tester, {List<String>? instrumentSlugs}) async {
  _db = inMemoryAppDatabase();
  addTearDown(_db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseOverride(_db),
        initialSettingsOverride(instrumentSlugs: instrumentSlugs),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              _ref = ref;
              return const SettingsScreen();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders the 3-way theme selector and instrument multi-select', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('theme-mode-selector')), findsOneWidget);
    expect(find.byKey(const Key('instruments-multiselect')), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Ukulele'), findsOneWidget);
    expect(find.text('Guitar'), findsOneWidget);
  });

  testWidgets('theme selector updates and persists the provider', (
    tester,
  ) async {
    await _pump(tester);

    expect(_ref.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(_ref.read(themeModeProvider), ThemeMode.dark);
    // Wrote through to the repository.
    final record = await AppSettingsRepository(_db).read();
    expect(record.themeMode, 'dark');
  });

  testWidgets('font size stepper updates and persists the provider', (
    tester,
  ) async {
    await _pump(tester);

    expect(_ref.read(fontSizeProvider), 20);

    await tester.tap(find.text('FONT SETTINGS'));
    await tester.pump();

    await tester.tap(find.byTooltip('Increase font size'));
    await tester.pump();
    expect(_ref.read(fontSizeProvider), 21);

    final record = await AppSettingsRepository(_db).read();
    expect(record.fontSize, 21);
  });

  testWidgets('instrument multi-select adds and removes (min one enforced)', (
    tester,
  ) async {
    // Start with only ukulele so the toggle starts single-selected.
    await _pump(tester, instrumentSlugs: const [ChordShapes.ukulele]);

    expect(_ref.read(instrumentsProvider), {ChordShapes.ukulele});

    // Tapping the only selected chip must NOT clear it (min-one rule).
    await tester.tap(find.byKey(const Key('instrument-chip-ukulele')));
    await tester.pump();
    expect(_ref.read(instrumentsProvider), {ChordShapes.ukulele});

    // Adding guitar selects both.
    await tester.tap(find.byKey(const Key('instrument-chip-guitar')));
    await tester.pump();
    expect(_ref.read(instrumentsProvider), {
      ChordShapes.ukulele,
      ChordShapes.guitar,
    });

    final record = await AppSettingsRepository(_db).read();
    expect(record.instrumentSlugs.toSet(), {
      ChordShapes.ukulele,
      ChordShapes.guitar,
    });
  });
}
