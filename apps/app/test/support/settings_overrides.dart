import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:models/models.dart';

/// An in-memory [AppDatabase] for tests that exercise write-through setters
/// (theme / font / instruments). Caller is responsible for closing it.
AppDatabase inMemoryAppDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());

/// Override that points [appDatabaseProvider] at an in-memory database.
Override appDatabaseOverride(AppDatabase db) =>
    appDatabaseProvider.overrideWithValue(db);

/// A default settings record for tests: both instruments, system theme, font 20.
AppSettingsRecord testSettingsRecord({
  bool onboardingComplete = true,
  String themeMode = 'system',
  List<String>? instrumentSlugs,
  int fontSize = 20,
}) => AppSettingsRecord(
  onboardingComplete: onboardingComplete,
  themeMode: themeMode,
  instrumentSlugs:
      instrumentSlugs ?? const [ChordShapes.ukulele, ChordShapes.guitar],
  fontSize: fontSize,
);

/// Override that seeds [initialAppSettingsProvider] so the persisted-preference
/// providers hydrate in tests (mirrors the startup override in `main.dart`).
Override initialSettingsOverride({
  bool onboardingComplete = true,
  String themeMode = 'system',
  List<String>? instrumentSlugs,
  int fontSize = 20,
}) => initialAppSettingsProvider.overrideWithValue(
  testSettingsRecord(
    onboardingComplete: onboardingComplete,
    themeMode: themeMode,
    instrumentSlugs: instrumentSlugs,
    fontSize: fontSize,
  ),
);
