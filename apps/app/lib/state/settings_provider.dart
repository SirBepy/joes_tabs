import 'package:data/data.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

/// App-wide user preferences, now PERSISTED via the Drift `AppSettings` table
/// (plan: onboarding + persisted preferences). The notifiers are write-through:
/// each setter persists to [AppSettingsRepository] first, then updates state, so
/// a restart restores the same values.
///
/// An "instrument" is a [ChordShapes] slug string (`ChordShapes.ukulele` /
/// `ChordShapes.guitar`). [ChordShapes] is a static data class, not an enum, so
/// the slug IS the typed value: no conversion layer is needed. The supported
/// set and display names live here ([kSupportedInstrumentSlugs],
/// [instrumentDisplayName]) so adding a third instrument later (e.g. Bass) is
/// one more entry, no model change.

/// The instrument slugs the app currently supports, in display order.
const List<String> kSupportedInstrumentSlugs = [
  ChordShapes.ukulele,
  ChordShapes.guitar,
];

/// Human label for an instrument slug, for pickers and settings.
String instrumentDisplayName(String slug) {
  switch (slug) {
    case ChordShapes.ukulele:
      return 'Ukulele';
    case ChordShapes.guitar:
      return 'Guitar';
    default:
      return slug;
  }
}

/// Maps a persisted `themeMode` string to a [ThemeMode]. Unknown values fall
/// back to [ThemeMode.system].
ThemeMode themeModeFromString(String raw) {
  switch (raw) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Encodes a [ThemeMode] back to the persisted string.
String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// The repository over the persisted settings row, built from the shared
/// [appDatabaseProvider] (the same database favorites use).
final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => AppSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// The settings record read once at startup. OVERRIDDEN in `main.dart` with the
/// value loaded before `runApp` (mirroring the favorites seed). The default
/// throws so a missing override is a loud programmer error rather than a silent
/// wrong value; tests that need it provide their own override.
final initialAppSettingsProvider = Provider<AppSettingsRecord>((ref) {
  throw UnimplementedError(
    'initialAppSettingsProvider must be overridden at the root ProviderScope '
    'with the AppSettingsRecord read at startup.',
  );
});

/// Persisted theme mode: System / Light / Dark. Default System. Seeded from the
/// startup record; [set] writes through to disk then updates state.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      themeModeFromString(ref.watch(initialAppSettingsProvider).themeMode);

  Future<void> set(ThemeMode mode) async {
    if (mode == state) return;
    await ref
        .read(appSettingsRepositoryProvider)
        .update(themeMode: themeModeToString(mode));
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Persisted set of instrument slugs the user plays. Always at least one: an
/// empty initial set (or an attempt to clear the last one) falls back to the
/// full supported set.
class InstrumentsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final slugs = ref
        .watch(initialAppSettingsProvider)
        .instrumentSlugs
        .where(kSupportedInstrumentSlugs.contains)
        .toSet();
    return slugs.isEmpty ? kSupportedInstrumentSlugs.toSet() : slugs;
  }

  /// Replaces the played-instruments set. Enforces at least one instrument:
  /// an empty request is ignored. Persists, then updates state, then keeps
  /// [selectedInstrumentProvider] valid (resets it to the first member if the
  /// currently-viewed instrument is no longer played).
  Future<void> set(Set<String> slugs) async {
    final next = slugs.where(kSupportedInstrumentSlugs.contains).toSet();
    if (next.isEmpty) return; // Min-one: ignore an attempt to clear the last.
    if (_sameSet(next, state)) return;
    await ref
        .read(appSettingsRepositoryProvider)
        .update(instrumentSlugs: next.toList());
    state = next;
    final selected = ref.read(selectedInstrumentProvider);
    if (!next.contains(selected)) {
      ref.read(selectedInstrumentProvider.notifier).state = next.first;
    }
  }

  /// Adds a single instrument to the played set.
  Future<void> add(String slug) => set({...state, slug});

  /// Removes a single instrument unless it is the last one (min-one rule).
  Future<void> remove(String slug) {
    if (state.length <= 1) return Future<void>.value();
    return set(state.where((s) => s != slug).toSet());
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

final instrumentsProvider = NotifierProvider<InstrumentsNotifier, Set<String>>(
  InstrumentsNotifier.new,
);

/// Persisted font size shown in Settings -> Font Settings. Seeded from the
/// startup record; [set] writes through to disk then updates state. Keeps the
/// same 20 default and value semantics the existing stepper relies on.
class FontSizeNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(initialAppSettingsProvider).fontSize;

  Future<void> set(int size) async {
    if (size == state) return;
    await ref.read(appSettingsRepositoryProvider).update(fontSize: size);
    state = size;
  }
}

final fontSizeProvider = NotifierProvider<FontSizeNotifier, int>(
  FontSizeNotifier.new,
);

/// Persisted "Maximal chords" flag. When true, the chord picker and the
/// browse-all library show every chords-db quality; when false, only the
/// balanced set. Seeded from the startup record; [set] writes through to disk
/// then updates state.
class MaximalChordsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialAppSettingsProvider).maximalChords;

  Future<void> set(bool value) async {
    if (value == state) return;
    await ref.read(appSettingsRepositoryProvider).update(maximalChords: value);
    state = value;
  }
}

final maximalChordsProvider = NotifierProvider<MaximalChordsNotifier, bool>(
  MaximalChordsNotifier.new,
);

/// The currently-VIEWED instrument used by the on-screen toggles (Chords, Tuner,
/// Search filter, Song controls). This is VIEW state, not a saved preference, so
/// it is intentionally IN-MEMORY only (a session [StateProvider]): switching the
/// toggle on Chords should not persist across an app restart. It replaces the
/// old `defaultInstrumentProvider` as the toggle's value.
///
/// The default is the first played instrument, but it is `read` (not `watch`):
/// changing the played-instruments set must NOT silently reset the user's
/// in-screen toggle. Instead [InstrumentsNotifier.set] explicitly resets this
/// only when the currently-viewed instrument is no longer played.
final selectedInstrumentProvider = StateProvider<String>(
  (ref) => ref.read(instrumentsProvider).first,
);

/// True when the user plays more than one instrument, i.e. the Ukulele/Guitar
/// picker should be shown. When false, the single played instrument is forced
/// and the picker is hidden everywhere.
final showInstrumentPickerProvider = Provider<bool>(
  (ref) => ref.watch(instrumentsProvider).length > 1,
);
