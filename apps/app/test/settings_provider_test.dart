import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

/// Builds a ProviderContainer wired like the app: an in-memory database and a
/// seeded settings record. Closes both on tear-down.
ProviderContainer _container({
  String themeMode = 'system',
  List<String>? instrumentSlugs,
  int fontSize = 20,
}) {
  final db = inMemoryAppDatabase();
  final container = ProviderContainer(
    overrides: [
      appDatabaseOverride(db),
      initialSettingsOverride(
        themeMode: themeMode,
        instrumentSlugs: instrumentSlugs,
        fontSize: fontSize,
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(db.close);
  return container;
}

void main() {
  group('hydration from the seeded record', () {
    test('themeMode + fontSize hydrate from initialAppSettingsProvider', () {
      final c = _container(themeMode: 'dark', fontSize: 28);
      expect(c.read(themeModeProvider), ThemeMode.dark);
      expect(c.read(fontSizeProvider), 28);
    });

    test('instruments hydrate; empty falls back to both', () {
      final both = _container(instrumentSlugs: const []);
      expect(both.read(instrumentsProvider), {
        ChordShapes.ukulele,
        ChordShapes.guitar,
      });

      final single = _container(instrumentSlugs: const [ChordShapes.guitar]);
      expect(single.read(instrumentsProvider), {ChordShapes.guitar});
    });
  });

  group('write-through setters', () {
    test('themeMode.set persists and updates state', () async {
      final c = _container();
      await c.read(themeModeProvider.notifier).set(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
      final record = await c.read(appSettingsRepositoryProvider).read();
      expect(record.themeMode, 'light');
    });

    test('fontSize.set persists and updates state', () async {
      final c = _container();
      await c.read(fontSizeProvider.notifier).set(33);
      expect(c.read(fontSizeProvider), 33);
      final record = await c.read(appSettingsRepositoryProvider).read();
      expect(record.fontSize, 33);
    });
  });

  group('instrumentsProvider min-one + selection reset', () {
    test('cannot clear the last instrument', () async {
      final c = _container(instrumentSlugs: const [ChordShapes.ukulele]);
      await c.read(instrumentsProvider.notifier).remove(ChordShapes.ukulele);
      expect(c.read(instrumentsProvider), {ChordShapes.ukulele});

      // An empty set request is ignored too.
      await c.read(instrumentsProvider.notifier).set(<String>{});
      expect(c.read(instrumentsProvider), {ChordShapes.ukulele});
    });

    test(
      'removing the selected instrument resets selectedInstrument',
      () async {
        final c = _container(); // both, selected defaults to ukulele (first)
        expect(c.read(selectedInstrumentProvider), ChordShapes.ukulele);

        // Drop ukulele -> only guitar remains, selection must move to guitar.
        await c.read(instrumentsProvider.notifier).set({ChordShapes.guitar});
        expect(c.read(instrumentsProvider), {ChordShapes.guitar});
        expect(c.read(selectedInstrumentProvider), ChordShapes.guitar);
      },
    );

    test('keeps the selection when it is still in the set', () async {
      final c = _container();
      c.read(selectedInstrumentProvider.notifier).state = ChordShapes.guitar;

      // Re-set to both: guitar is still present, so selection is untouched.
      await c.read(instrumentsProvider.notifier).set({
        ChordShapes.ukulele,
        ChordShapes.guitar,
      });
      expect(c.read(selectedInstrumentProvider), ChordShapes.guitar);
    });
  });

  group('showInstrumentPickerProvider', () {
    test('false for a single instrument, true for two', () {
      final single = _container(instrumentSlugs: const [ChordShapes.ukulele]);
      expect(single.read(showInstrumentPickerProvider), isFalse);

      final both = _container();
      expect(both.read(showInstrumentPickerProvider), isTrue);
    });
  });
}
