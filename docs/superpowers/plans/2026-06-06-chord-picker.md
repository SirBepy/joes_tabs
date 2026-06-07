# Chord Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Commit rule (project-specific):** subagents must NOT commit (no Skill tool). Each task ends by STAGING changes; the main agent commits via the `/commit` skill between tasks. Dispatch prompts must say: "Stage your changes but do NOT commit."
>
> **Windows / PowerShell:** one command per shell call, no `&&`/`;`/`|` chaining. Run generator/build/test commands from the stated package dir.

**Goal:** Add a guided chord-picker landing screen (result diagram + four scrollable strips: Note / sharp-flat / Family / Type), keep the existing library as a "Browse all" tab, and add a persisted "Maximal chords" Settings toggle that unlocks the full chords-db quality set.

**Architecture:** Chord-quality knowledge (families, tiers) lives instrument-independent in `packages/models` as a generated catalog (`kChordQualities`) emitted by the existing `gen_chord_shapes.dart` tool, which also regenerates the per-instrument voicing maps. A new `maximalChords` boolean rides the existing `AppSettings` Drift row (write-through provider). The Chords screen splits into a tab host + the existing library view + a new picker view built from small, reusable widgets.

**Tech Stack:** Flutter, Riverpod 2 (manual providers), Drift, the chords-db-generated data, Phosphor icons.

**Spec:** `docs/superpowers/specs/2026-06-06-chord-picker-design.md`

---

## File structure

- `packages/models/lib/src/chordpro/chord_catalog.dart` — NEW. `ChordFamily` enum + `ChordQuality` class; re-exports `kChordQualities` from the generated data file.
- `packages/models/lib/src/chordpro/chord_qualities_data.dart` — NEW, GENERATED, committed. The `kChordQualities` list.
- `packages/models/lib/src/chordpro/chord_shapes_data.dart` — REGENERATED (more entries).
- `packages/models/tool/gen_chord_shapes.dart` — MODIFY: master quality table + emit the qualities file + completeness filter.
- `packages/models/lib/models.dart` — MODIFY: export `chord_catalog.dart`.
- `packages/models/test/chord_catalog_test.dart` — NEW.
- `packages/models/test/chord_shapes_test.dart` — MODIFY: counts.
- `packages/data/lib/src/drift/app_database.dart` — MODIFY: `maximalChords` column, schemaVersion 3, v2->v3 upgrade.
- `packages/data/lib/src/settings/app_settings_repository.dart` — MODIFY: field in record + update + decode.
- `packages/data/test/app_settings_repository_test.dart` (or existing settings test) — MODIFY/ADD: round-trip + migration.
- `apps/app/lib/state/settings_provider.dart` — MODIFY: `maximalChordsProvider`.
- `apps/app/lib/main.dart` — MODIFY: add `maximalChords: false` to the fallback `AppSettingsRecord`.
- `apps/app/lib/widgets/scrollable_chip_row.dart` — NEW reusable widget.
- `apps/app/lib/screens/chords/chord_picker_view.dart` — NEW picker.
- `apps/app/lib/screens/chords/chord_library_view.dart` — NEW (extracted from chords_screen).
- `apps/app/lib/screens/chords_screen.dart` — MODIFY: becomes the Pick/Browse-all tab host.
- `apps/app/lib/screens/settings_screen.dart` — MODIFY: "Maximal chords" switch.
- `apps/app/test/chord_picker_test.dart`, `apps/app/test/scrollable_chip_row_test.dart` — NEW.
- `apps/app/test/settings_test.dart` — MODIFY: maximal toggle.

---

## Task 1: Chord-quality catalog types + generator + regenerate

**Files:**
- Create: `packages/models/lib/src/chordpro/chord_catalog.dart`
- Modify: `packages/models/tool/gen_chord_shapes.dart`
- Create (generated): `packages/models/lib/src/chordpro/chord_qualities_data.dart`
- Regenerate: `packages/models/lib/src/chordpro/chord_shapes_data.dart`
- Modify: `packages/models/lib/models.dart`

- [ ] **Step 1: Write the catalog types (hand-written).**

Create `chord_catalog.dart`:

```dart
/// Chord families and the ordered quality catalog that drives the chord picker
/// and the "browse all" library. The `kChordQualities` list is GENERATED from
/// the same chords-db master table as the voicings (see
/// `tool/gen_chord_shapes.dart`); this file owns the public types and re-exports
/// the generated list.
library;

import 'chord_qualities_data.dart';

export 'chord_qualities_data.dart' show kChordQualities;

/// The six chord families, in display order. Each maps to a strip chip.
enum ChordFamily {
  major('Major'),
  minor('Minor'),
  dominant('Dominant'),
  suspended('Suspended'),
  diminished('Diminished'),
  augmented('Augmented');

  const ChordFamily(this.label);

  /// Human label shown on the Family strip.
  final String label;
}

/// One selectable chord quality (the "Type" within a family).
///
/// [suffix] is appended to a root to form a chord symbol resolvable by
/// `ChordShapes.lookup` (e.g. root `C` + suffix `m7` -> `Cm7`; the major triad
/// has an empty suffix). [label] is the chip text. [extended] is true for
/// qualities only shown when "Maximal chords" is on.
class ChordQuality {
  const ChordQuality({
    required this.suffix,
    required this.family,
    required this.label,
    required this.extended,
  });

  final String suffix;
  final ChordFamily family;
  final String label;
  final bool extended;
}

/// The balanced (default) qualities: everything not gated behind maximal mode.
List<ChordQuality> get kBalancedQualities =>
    kChordQualities.where((q) => !q.extended).toList();

/// Qualities for [family], filtered to the balanced tier unless [maximal].
List<ChordQuality> qualitiesFor(ChordFamily family, {required bool maximal}) =>
    kChordQualities
        .where((q) => q.family == family && (maximal || !q.extended))
        .toList();
```

- [ ] **Step 2: Add the master quality table to the generator.**

In `gen_chord_shapes.dart`, replace the existing `_qualities` list with a richer master table carrying family + tier + label + chords-db suffix. Add near the top:

```dart
/// (our suffix, chords-db suffix, family enum name, label, extended?).
/// Balanced tier first; extended (maximal-only) after. Order within a family is
/// the on-screen Type-strip order.
const List<({String suffix, String db, String family, String label, bool extended})>
    _catalog = [
  // Major
  (suffix: '', db: 'major', family: 'major', label: 'Major', extended: false),
  (suffix: 'maj7', db: 'maj7', family: 'major', label: 'maj7', extended: false),
  (suffix: '6', db: '6', family: 'major', label: '6', extended: false),
  (suffix: 'add9', db: 'add9', family: 'major', label: 'add9', extended: false),
  (suffix: 'maj9', db: 'maj9', family: 'major', label: 'maj9', extended: true),
  (suffix: 'maj11', db: 'maj11', family: 'major', label: 'maj11', extended: true),
  (suffix: 'maj13', db: 'maj13', family: 'major', label: 'maj13', extended: true),
  (suffix: '69', db: '69', family: 'major', label: '6/9', extended: true),
  // Minor
  (suffix: 'm', db: 'minor', family: 'minor', label: 'Minor', extended: false),
  (suffix: 'm7', db: 'm7', family: 'minor', label: 'm7', extended: false),
  (suffix: 'm6', db: 'm6', family: 'minor', label: 'm6', extended: false),
  (suffix: 'madd9', db: 'madd9', family: 'minor', label: 'madd9', extended: false),
  (suffix: 'm9', db: 'm9', family: 'minor', label: 'm9', extended: true),
  (suffix: 'm11', db: 'm11', family: 'minor', label: 'm11', extended: true),
  (suffix: 'mmaj7', db: 'mmaj7', family: 'minor', label: 'mMaj7', extended: true),
  // Dominant
  (suffix: '7', db: '7', family: 'dominant', label: '7', extended: false),
  (suffix: '9', db: '9', family: 'dominant', label: '9', extended: false),
  (suffix: '11', db: '11', family: 'dominant', label: '11', extended: false),
  (suffix: '13', db: '13', family: 'dominant', label: '13', extended: false),
  (suffix: '7b5', db: '7b5', family: 'dominant', label: '7b5', extended: true),
  (suffix: '7b9', db: '7b9', family: 'dominant', label: '7b9', extended: true),
  (suffix: '7#9', db: '7#9', family: 'dominant', label: '7#9', extended: true),
  (suffix: '9b5', db: '9b5', family: 'dominant', label: '9b5', extended: true),
  (suffix: '7sus4', db: '7sus4', family: 'dominant', label: '7sus4', extended: true),
  // Suspended
  (suffix: 'sus2', db: 'sus2', family: 'suspended', label: 'sus2', extended: false),
  (suffix: 'sus4', db: 'sus4', family: 'suspended', label: 'sus4', extended: false),
  // Diminished
  (suffix: 'dim', db: 'dim', family: 'diminished', label: 'dim', extended: false),
  (suffix: 'dim7', db: 'dim7', family: 'diminished', label: 'dim7', extended: false),
  (suffix: 'm7b5', db: 'm7b5', family: 'diminished', label: 'm7b5', extended: false),
  // Augmented
  (suffix: 'aug', db: 'aug', family: 'augmented', label: 'aug', extended: false),
  (suffix: 'aug7', db: 'aug7', family: 'augmented', label: 'aug7', extended: false),
  (suffix: 'aug9', db: 'aug9', family: 'augmented', label: 'aug9', extended: true),
];
```

Update `_emitMap` to iterate `_catalog` (using `entry.db` as the chords-db suffix and `entry.suffix` as our symbol suffix) instead of the old `_qualities`. Apply a **completeness rule**: a quality is emitted into the shape maps and the qualities catalog only if EVERY root resolves for BOTH instruments. For balanced entries, a missing resolution is a hard error (throw, as today). For `extended` entries, a missing resolution drops that quality from the output and prints a warning (so the catalog never offers an unrenderable chord). Implement a pre-pass: for each `_catalog` entry, try `_resolve` for all 12 roots on both datasets; collect the set of "complete" suffixes; balanced must all be complete or throw; build the final emitted catalog from balanced + complete-extended.

- [ ] **Step 3: Emit the qualities data file.**

Add an emitter that writes `chord_qualities_data.dart`:

```dart
String _emitQualities(List<({String suffix, String family, String label, bool extended})> emitted) {
  final buf = StringBuffer()
    ..writeln('// GENERATED by tool/gen_chord_shapes.dart - DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// The ordered chord-quality catalog (family, tier, label) used by')
    ..writeln('// the chord picker. Source: chords-db master table in the generator.')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'chord_catalog.dart';")
    ..writeln()
    ..writeln('const List<ChordQuality> kChordQualities = [');
  for (final e in emitted) {
    buf.writeln(
      "  ChordQuality(suffix: '${e.suffix}', family: ChordFamily.${e.family}, "
      "label: '${e.label}', extended: ${e.extended}),",
    );
  }
  buf.writeln('];');
  return buf.toString();
}
```

Write it to `lib/src/chordpro/chord_qualities_data.dart` in `main()` alongside the shapes file. Note the circular import (`chord_qualities_data.dart` imports `chord_catalog.dart`, which imports it back) — legal in Dart for const data; do not try to break it.

- [ ] **Step 4: Export the catalog and run the generator.**

Add to `packages/models/lib/models.dart`:

```dart
export 'src/chordpro/chord_catalog.dart';
```

Run (from `packages/models`):

```
dart run tool/gen_chord_shapes.dart
```

Expected: prints the shapes file + a count of emitted qualities (balanced 19 + however many extended passed completeness), and any dropped-extended warnings. Confirms both data files were written.

- [ ] **Step 5: Regenerate codegen and analyze.**

Run (from `packages/models`):

```
dart run build_runner build --delete-conflicting-outputs
```
```
dart analyze lib test tool
```
Expected: `No issues found!`

- [ ] **Step 6: Stage (main agent commits).**

```
git add packages/models/lib/src/chordpro/chord_catalog.dart packages/models/lib/src/chordpro/chord_qualities_data.dart packages/models/lib/src/chordpro/chord_shapes_data.dart packages/models/tool/gen_chord_shapes.dart packages/models/lib/models.dart
```
Main agent: `/commit` → `FEAT: generate chord-family quality catalog from chords-db`.

---

## Task 2: Catalog tests + update shape-count test

**Files:**
- Create: `packages/models/test/chord_catalog_test.dart`
- Modify: `packages/models/test/chord_shapes_test.dart`

- [ ] **Step 1: Write the catalog test.**

```dart
import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  const roots = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  const instruments = [ChordShapes.ukulele, ChordShapes.guitar];

  test('every family has at least one balanced quality', () {
    for (final family in ChordFamily.values) {
      final balanced =
          kBalancedQualities.where((q) => q.family == family).toList();
      expect(balanced, isNotEmpty, reason: '${family.name} has no balanced quality');
    }
  });

  test('balanced tier matches the spec set', () {
    final balanced = kBalancedQualities.map((q) => q.suffix).toSet();
    expect(balanced, {
      '', 'maj7', '6', 'add9', // major
      'm', 'm7', 'm6', 'madd9', // minor
      '7', '9', '11', '13', // dominant
      'sus2', 'sus4', // suspended
      'dim', 'dim7', 'm7b5', // diminished
      'aug', 'aug7', // augmented
    });
  });

  test('every catalog quality renders for every root on both instruments', () {
    for (final q in kChordQualities) {
      for (final r in roots) {
        for (final instrument in instruments) {
          final shape = ChordShapes.lookup('$r${q.suffix}', instrument);
          expect(shape, isNotNull,
              reason: '$instrument missing $r${q.suffix} (${q.family.name})');
        }
      }
    }
  });

  test('qualitiesFor filters by family and tier', () {
    final balancedMajor =
        qualitiesFor(ChordFamily.major, maximal: false).map((q) => q.suffix);
    expect(balancedMajor, containsAll(['', 'maj7', '6', 'add9']));
    expect(balancedMajor, isNot(contains('maj9'))); // extended hidden when off

    final maximalMajor =
        qualitiesFor(ChordFamily.major, maximal: true).map((q) => q.suffix);
    expect(maximalMajor, contains('maj9'));
  });
}
```

- [ ] **Step 2: Run it (expect FAIL until Task 1 generated data exists; if Task 1 done, PASS).**

Run (from `packages/models`): `dart test test/chord_catalog_test.dart`
Expected: PASS (Task 1 already generated the data).

- [ ] **Step 3: Update `chord_shapes_test.dart` hard-coded counts.**

The `coverage` and `namesFor` tests assert `roots.length * suffixes.length` (132) using a local `suffixes` list. Replace that expectation with the catalog-driven count. Change the `namesFor` test body to:

```dart
test('namesFor returns every catalog symbol, sorted; empty for unknown', () {
  final expectedCount = 12 * kChordQualities.length;
  for (final instrument in instruments) {
    final names = ChordShapes.namesFor(instrument);
    expect(names.length, expectedCount, reason: instrument);
    final sorted = [...names]..sort();
    expect(names, sorted, reason: '$instrument sorted');
  }
  expect(ChordShapes.namesFor('banjo'), isEmpty);
});
```

And in the `coverage` group, replace the local `suffixes` loop with iteration over `kChordQualities.map((q) => q.suffix)`. Keep the golden spot-checks, enharmonic, slash, and unknown tests unchanged.

- [ ] **Step 4: Run the full models suite.**

Run (from `packages/models`): `dart test`
Expected: All tests pass.

- [ ] **Step 5: Stage (main agent commits).**

```
git add packages/models/test/chord_catalog_test.dart packages/models/test/chord_shapes_test.dart
```
Main agent: `/commit` → `TEST: cover the chord-quality catalog and updated counts`.

---

## Task 3: Persist `maximalChords` in the data layer

**Files:**
- Modify: `packages/data/lib/src/drift/app_database.dart`
- Modify: `packages/data/lib/src/settings/app_settings_repository.dart`
- Modify/Add: `packages/data/test/` settings + migration tests

- [ ] **Step 1: Add the column + bump schema + upgrade.**

In `app_database.dart`, add to the `AppSettings` table (after `fontSize`):

```dart
  BoolColumn get maximalChords =>
      boolean().withDefault(const Constant(false))();
```

Bump the version:

```dart
  @override
  int get schemaVersion => 3;
```

Extend `onUpgrade` (keep the existing v1->v2 block; add v2->v3 before the trailing `_ensureAppSettingsRow()`):

```dart
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(appSettings);
      }
      if (from < 3) {
        // v2 -> v3: add the maximalChords flag with its default.
        await m.addColumn(appSettings, appSettings.maximalChords);
      }
      await _ensureAppSettingsRow();
    },
```

- [ ] **Step 2: Run codegen.**

Run (from `packages/data`): `dart run build_runner build --delete-conflicting-outputs`
Expected: regenerates `app_database.g.dart` with the new column; no errors.

- [ ] **Step 3: Thread the field through the repository.**

In `app_settings_repository.dart`: add `final bool maximalChords;` to `AppSettingsRecord` (and its constructor, `required this.maximalChords`); add `bool? maximalChords` to `update(...)` and set
`maximalChords: maximalChords == null ? const Value.absent() : Value(maximalChords)` in the companion; and in `_toRecord` add `maximalChords: row.maximalChords,`.

- [ ] **Step 4: Write the round-trip + migration tests.**

Add to the data settings test file:

```dart
test('maximalChords round-trips and defaults false', () async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = AppSettingsRepository(db);

  expect((await repo.read()).maximalChords, isFalse);
  await repo.update(maximalChords: true);
  expect((await repo.read()).maximalChords, isTrue);
});
```

Migration test (mirror the existing v1->v2 style; open a v2 schema, upgrade, assert the column exists and defaults false). If the repo has a `schema/` verifier use it; otherwise assert via a fresh `AppDatabase` that `schemaVersion == 3` and a read returns `maximalChords == false`.

- [ ] **Step 5: Run the data suite.**

Run (from `packages/data`): `dart test`
Expected: all pass.

- [ ] **Step 6: Stage (main agent commits).**

```
git add packages/data/lib/src/drift/app_database.dart packages/data/lib/src/settings/app_settings_repository.dart packages/data/test
```
Main agent: `/commit` → `FEAT: persist the maximal-chords preference (schema v3)`.

---

## Task 4: `maximalChordsProvider` + startup default

**Files:**
- Modify: `apps/app/lib/state/settings_provider.dart`
- Modify: `apps/app/lib/main.dart`
- Modify: `apps/app/test/` (settings provider test if present)

- [ ] **Step 1: Add the provider (mirrors `fontSizeProvider`).**

Append to `settings_provider.dart`:

```dart
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
```

- [ ] **Step 2: Add the field to the main.dart fallback record.**

In `main.dart`, the in-memory default `AppSettingsRecord(...)` gains `maximalChords: false,`:

```dart
  AppSettingsRecord initialSettings = const AppSettingsRecord(
    onboardingComplete: false,
    themeMode: 'system',
    instrumentSlugs: [ChordShapes.ukulele, ChordShapes.guitar],
    fontSize: 20,
    maximalChords: false,
  );
```

- [ ] **Step 3: Analyze to confirm every `AppSettingsRecord(...)` call site compiles.**

Run (from `apps/app`): `flutter analyze`
Expected: `No issues found!` (if a test constructs `AppSettingsRecord` directly, add `maximalChords: false` there too).

- [ ] **Step 4: Provider test.**

Add a test overriding `initialAppSettingsProvider` + `appSettingsRepositoryProvider` (with a memory `AppDatabase`) asserting `maximalChordsProvider` defaults false and `.set(true)` persists. Mirror the existing `fontSizeProvider` test.

- [ ] **Step 5: Run app tests.**

Run (from `apps/app`): `flutter test`
Expected: pass.

- [ ] **Step 6: Stage (main agent commits).**

```
git add apps/app/lib/state/settings_provider.dart apps/app/lib/main.dart apps/app/test
```
Main agent: `/commit` → `FEAT: maximal-chords provider seeded from persisted settings`.

---

## Task 5: `ScrollableChipRow` reusable widget

**Files:**
- Create: `apps/app/lib/widgets/scrollable_chip_row.dart`
- Create: `apps/app/test/scrollable_chip_row_test.dart`

- [ ] **Step 1: Write the failing widget test.**

```dart
import 'package:app/widgets/scrollable_chip_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label + options and reports taps', (tester) async {
    var picked = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScrollableChipRow(
          label: 'Note',
          options: const ['C', 'D', 'E'],
          selected: 'C',
          onSelected: (v) => picked = v,
        ),
      ),
    ));
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    await tester.tap(find.text('D'));
    expect(picked, 'D');
  });
}
```

- [ ] **Step 2: Run → FAIL (file/class missing).**

Run (from `apps/app`): `flutter test test/scrollable_chip_row_test.dart`
Expected: FAIL (Target of URI doesn't exist).

- [ ] **Step 3: Implement the widget.**

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A labelled, single-line horizontally-scrollable single-select chip row, with
/// a right-edge fade hinting more content. Used by the chord picker for Note,
/// sharp/flat, Family and Type. Pure presentation: it owns no selection state.
class ScrollableChipRow extends StatelessWidget {
  const ScrollableChipRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs,
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.92, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (final option in options) ...[
                  ChoiceChip(
                    label: Text(option),
                    selected: option == selected,
                    showCheckmark: false,
                    selectedColor: AppColors.orange,
                    backgroundColor: AppColors.peach,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: option == selected
                          ? AppColors.white
                          : AppColors.rust,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => onSelected(option),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
```

- [ ] **Step 4: Run → PASS.**

Run (from `apps/app`): `flutter test test/scrollable_chip_row_test.dart`
Expected: PASS.

- [ ] **Step 5: Stage (main agent commits).**

```
git add apps/app/lib/widgets/scrollable_chip_row.dart apps/app/test/scrollable_chip_row_test.dart
```
Main agent: `/commit` → `FEAT: reusable scrollable chip row`.

---

## Task 6: `ChordPickerView`

**Files:**
- Create: `apps/app/lib/screens/chords/chord_picker_view.dart`
- Create: `apps/app/test/chord_picker_test.dart`

- [ ] **Step 1: Write the failing widget test.**

```dart
import 'package:app/screens/chords/chord_picker_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

import 'helpers/settings_harness.dart'; // existing test harness that overrides initialAppSettingsProvider + appDatabaseProvider

void main() {
  testWidgets('defaults to C major and updates on selection', (tester) async {
    await tester.pumpWidget(settingsHarness(
      child: const ChordPickerView(instrumentSlug: ChordShapes.ukulele),
    ));
    await tester.pumpAndSettle();

    // Result card shows the default chord name.
    expect(find.text('C'), findsWidgets);

    // Pick the Minor family, then m7 -> result becomes Cm7.
    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('m7'));
    await tester.pumpAndSettle();
    expect(find.text('Cm7'), findsWidgets);

    // Sharpen the root -> C#m7 (ASCII '#', matching ChordShapes keys).
    await tester.tap(find.text('♯')); // the chip label is the unicode sharp
    await tester.pumpAndSettle();
    expect(find.text('C#m7'), findsWidgets);
  });
}
```

If `helpers/settings_harness.dart` does not exist, create a minimal `ProviderScope` wrapper in the test that overrides `initialAppSettingsProvider` with a const record (maximalChords:false) and `appDatabaseProvider` with `AppDatabase.forTesting(NativeDatabase.memory())`, mirroring an existing widget test's setup.

- [ ] **Step 2: Run → FAIL (missing file).**

Run (from `apps/app`): `flutter test test/chord_picker_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `ChordPickerView`.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

import '../../song/chord_diagram.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/scrollable_chip_row.dart';

/// Guided chord picker: a live result diagram on top, then four scrollable
/// strips (Note, sharp/flat, Family, Type). Selection is in-memory view state.
class ChordPickerView extends ConsumerStatefulWidget {
  const ChordPickerView({super.key, required this.instrumentSlug});

  final String instrumentSlug;

  @override
  ConsumerState<ChordPickerView> createState() => _ChordPickerViewState();
}

class _ChordPickerViewState extends ConsumerState<ChordPickerView> {
  static const _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const _accidentals = ['♮', '♯', '♭']; // natural sharp flat

  String _letter = 'C';
  String _accidental = '♮';
  ChordFamily _family = ChordFamily.major;
  String _suffix = ''; // major triad

  String get _root {
    switch (_accidental) {
      case '♯':
        return '$_letter#';
      case '♭':
        return '${_letter}b';
      default:
        return _letter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maximal = ref.watch(maximalChordsProvider);
    final qualities = qualitiesFor(_family, maximal: maximal);

    // Keep the selected suffix valid for the current family/tier.
    if (!qualities.any((q) => q.suffix == _suffix)) {
      _suffix = qualities.isEmpty ? '' : qualities.first.suffix;
    }
    final symbol = '$_root$_suffix';

    return ListView(
      children: [
        _ResultCard(symbol: symbol, instrumentSlug: widget.instrumentSlug),
        ScrollableChipRow(
          label: 'Note',
          options: _letters,
          selected: _letter,
          onSelected: (v) => setState(() => _letter = v),
        ),
        ScrollableChipRow(
          label: 'Sharp / Flat',
          options: _accidentals,
          selected: _accidental,
          onSelected: (v) => setState(() => _accidental = v),
        ),
        ScrollableChipRow(
          label: 'Family',
          options: [for (final f in ChordFamily.values) f.label],
          selected: _family.label,
          onSelected: (label) => setState(() {
            _family = ChordFamily.values.firstWhere((f) => f.label == label);
          }),
        ),
        ScrollableChipRow(
          label: 'Type',
          options: [for (final q in qualities) q.label],
          selected: _labelFor(qualities, _suffix),
          onSelected: (label) => setState(() {
            _suffix = qualities.firstWhere((q) => q.label == label).suffix;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  String _labelFor(List<ChordQuality> qs, String suffix) =>
      qs.firstWhere((q) => q.suffix == suffix, orElse: () => qs.first).label;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.symbol, required this.instrumentSlug});

  final String symbol;
  final String instrumentSlug;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardPeach,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              symbol,
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 30,
              ),
            ),
          ),
          ChordDiagram(
            chord: symbol,
            instrumentSlug: instrumentSlug,
            width: 96,
          ),
        ],
      ),
    );
  }
}
```

Note: `ChordDiagram` already renders a "no diagram" fallback for any symbol that does not resolve, so an enharmonic spelling that lacks an exact key still renders via `ChordShapes.lookup`'s enharmonic path.

- [ ] **Step 4: Run → PASS.**

Run (from `apps/app`): `flutter test test/chord_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Stage (main agent commits).**

```
git add apps/app/lib/screens/chords/chord_picker_view.dart apps/app/test/chord_picker_test.dart
```
Main agent: `/commit` → `FEAT: guided chord picker view`.

---

## Task 7: Pick / Browse-all tab host + extracted library view

**Files:**
- Create: `apps/app/lib/screens/chords/chord_library_view.dart`
- Modify: `apps/app/lib/screens/chords_screen.dart`
- Modify: `apps/app/test/` (existing chords test, if any) + tab test

- [ ] **Step 1: Extract the current library body into `ChordLibraryView`.**

Move the existing body of `_ChordsScreenState.build` (the instrument toggle row, search field, grouped `ListView`, `_RootSection`, `_groupByRoot`, `_rootOf`) verbatim into a new `ChordLibraryView extends ConsumerStatefulWidget` in `chord_library_view.dart`, taking `final String instrument`. Add a tier filter: build the displayed names from the catalog rather than raw `namesFor`, so the library respects maximal mode. Replace the names source:

```dart
final maximal = ref.watch(maximalChordsProvider);
final allowed = {
  for (final q in (maximal ? kChordQualities : kBalancedQualities)) q.suffix,
};
final names = ChordShapes.namesFor(instrument).where((n) {
  final suffix = n.replaceFirst(RegExp(r'^[A-G][#b]?'), '');
  return allowed.contains(suffix);
}).toList();
```

Keep the search `TextField` and grouping exactly as before.

- [ ] **Step 2: Rewrite `chords_screen.dart` as the tab host.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/instrument_toggle.dart';
import 'chords/chord_library_view.dart';
import 'chords/chord_picker_view.dart';

/// Chords landing: a "Pick / Browse all" tab host. Pick is the guided picker;
/// Browse all is the grouped-by-root library. Instrument is resolved the same
/// way both views need it (forced to the single played instrument, or the
/// on-screen toggle when more than one is played).
class ChordsScreen extends ConsumerStatefulWidget {
  const ChordsScreen({super.key});

  @override
  ConsumerState<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends ConsumerState<ChordsScreen> {
  bool _browse = false;

  @override
  Widget build(BuildContext context) {
    final showPicker = ref.watch(showInstrumentPickerProvider);
    final instrument = showPicker
        ? ref.watch(selectedInstrumentProvider)
        : ref.watch(instrumentsProvider).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
          ),
          child: Row(
            children: [
              _Tabs(
                browse: _browse,
                onChanged: (b) => setState(() => _browse = b),
              ),
              const Spacer(),
              if (showPicker)
                InstrumentToggle(
                  value: instrument,
                  onChanged: (slug) => ref
                      .read(selectedInstrumentProvider.notifier)
                      .state = slug,
                ),
            ],
          ),
        ),
        Expanded(
          child: _browse
              ? ChordLibraryView(instrument: instrument)
              : ChordPickerView(instrumentSlug: instrument),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.browse, required this.onChanged});

  final bool browse;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'Pick', selected: !browse, onTap: () => onChanged(false)),
          _Tab(label: 'Browse all', selected: browse, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update / add the tab widget test.**

Add a test: pump `ChordsScreen` (via the settings harness with both instruments), assert the picker's "Family" strip is present by default, tap "Browse all", assert the search field ("Search chords") appears, tap "Pick", assert it's gone again. Update any existing chords-screen test that assumed the old single-body layout.

- [ ] **Step 4: Run app tests + analyze.**

Run (from `apps/app`): `flutter test`
Run (from `apps/app`): `flutter analyze`
Expected: pass / `No issues found!`

- [ ] **Step 5: Stage (main agent commits).**

```
git add apps/app/lib/screens/chords/chord_library_view.dart apps/app/lib/screens/chords_screen.dart apps/app/test
```
Main agent: `/commit` → `FEAT: Pick/Browse-all tab host for the Chords screen`.

---

## Task 8: "Maximal chords" Settings toggle

**Files:**
- Modify: `apps/app/lib/screens/settings_screen.dart`
- Modify: `apps/app/test/settings_test.dart`

- [ ] **Step 1: Add the switch row.**

In `settings_screen.dart` `build`, read the flag near the others:

```dart
final maximalChords = ref.watch(maximalChordsProvider);
```

Insert after the INSTRUMENTS block's trailing `Divider`:

```dart
        SwitchListTile(
          key: const Key('maximal-chords-switch'),
          value: maximalChords,
          activeThumbColor: AppColors.orange,
          title: const Text(
            'MAXIMAL CHORDS',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: const Text(
            'Show advanced chord types (9ths, 11ths, altered, etc.)',
          ),
          onChanged: (v) => ref.read(maximalChordsProvider.notifier).set(v),
        ),
        const Divider(height: 1),
```

(If `activeThumbColor` is unavailable on the pinned Flutter, use `activeColor`.)

- [ ] **Step 2: Add the settings test.**

```dart
testWidgets('maximal-chords toggle persists', (tester) async {
  await tester.pumpWidget(settingsHarness(child: const SettingsScreen()));
  await tester.pumpAndSettle();

  final sw = find.byKey(const Key('maximal-chords-switch'));
  expect(tester.widget<SwitchListTile>(sw).value, isFalse);
  await tester.tap(sw);
  await tester.pumpAndSettle();
  expect(tester.widget<SwitchListTile>(sw).value, isTrue);
});
```

- [ ] **Step 3: Run → PASS.**

Run (from `apps/app`): `flutter test test/settings_test.dart`
Expected: PASS.

- [ ] **Step 4: Stage (main agent commits).**

```
git add apps/app/lib/screens/settings_screen.dart apps/app/test/settings_test.dart
```
Main agent: `/commit` → `FEAT: Maximal chords toggle in Settings`.

---

## Task 9: Full verification + live check

- [ ] **Step 1: Regenerate everything from clean (CI parity).**

Run (from `packages/models`): `dart run build_runner build --delete-conflicting-outputs`
Run (from `packages/data`): `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Analyze + format.**

Run (from repo root via each package) `flutter analyze` (apps/app) and `dart analyze` (packages/models, packages/data): expect clean.
Run `dart format` on all changed files.

- [ ] **Step 3: Full test suites.**

Run (from `packages/models`): `dart test` — all pass.
Run (from `packages/data`): `dart test` — all pass.
Run (from `apps/app`): `flutter test` — all pass.

- [ ] **Step 4: Web build.**

Run (from `apps/app`): `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
Expected: `Built build\web`.

- [ ] **Step 5: Live check (main agent).**

Restart the supervised app (`app-2:flutter-run-2`), open `/chords` at 390x844 via Playwright. Verify: Pick tab shows the result card + four strips; tapping Family swaps the Type strip; sharpening changes the result; Browse all shows the library; toggling Settings -> Maximal chords adds extended chips (e.g. maj9) to a family's Type strip. Throwaway screenshots to `.for_bepy/screenshots/`.

- [ ] **Step 6: Final commit if any formatting changed.**

Main agent: `/commit` → `STYLE: format chord picker files` (only if `dart format` changed anything).

---

## Notes for the executor

- The generator's `_resolve` already MIDI-validates each voicing; the new completeness filter only adds "drop extended quality if any root/instrument is missing." Do not weaken balanced-tier validation.
- Roots stay sharp-canonical; flats from the picker (`Db`, `Eb`, ...) resolve through `ChordShapes.lookup`'s existing enharmonic path — no new lookup logic.
- `selectedInstrumentProvider` / `showInstrumentPickerProvider` already exist; reuse them, don't reintroduce `defaultInstrumentProvider`.
- Keep files focused: the picker view, library view, tab host, and chip row are separate files by responsibility.
