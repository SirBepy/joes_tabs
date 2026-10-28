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

    test('instruments hydrate to ukulele only, dropping guitar', () {
      final empty = _container(instrumentSlugs: const []);
      expect(empty.read(instrumentsProvider), {ChordShapes.ukulele});

      final both = _container(
        instrumentSlugs: const [ChordShapes.ukulele, ChordShapes.guitar],
      );
      expect(both.read(instrumentsProvider), {ChordShapes.ukulele});
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
  });

  group('showInstrumentPickerProvider', () {
    test('never shows: the app is ukulele only', () {
      final both = _container(
        instrumentSlugs: const [ChordShapes.ukulele, ChordShapes.guitar],
      );
      expect(both.read(showInstrumentPickerProvider), isFalse);
    });
  });

  group('maximalChordsProvider', () {
    test('defaults to false from the seeded record', () {
      final c = _container();
      expect(c.read(maximalChordsProvider), isFalse);
    });

    test('set(true) updates state and persists', () async {
      final c = _container();
      await c.read(maximalChordsProvider.notifier).set(true);
      expect(c.read(maximalChordsProvider), isTrue);
      final record = await c.read(appSettingsRepositoryProvider).read();
      expect(record.maximalChords, isTrue);
    });

    test('set(false) is a no-op when already false', () async {
      final c = _container();
      await c.read(maximalChordsProvider.notifier).set(false);
      expect(c.read(maximalChordsProvider), isFalse);
    });
  });
}
