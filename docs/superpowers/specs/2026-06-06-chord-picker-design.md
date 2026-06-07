# Chord picker landing screen

Date: 2026-06-06
Status: approved (design)

## Context

The Chords screen today is a browse-only library: every chord for an instrument
grouped by root in horizontal carousels (`apps/app/lib/screens/chords_screen.dart`,
data from `ChordShapes.namesFor`). It works, but as a *landing* it asks the user to
hunt. Joe wants a guided **chord picker** as the primary experience: assemble a
chord from a few simple choices and see its diagram, with the existing library kept
as a secondary "Browse all" view.

Two research sweeps (real chord apps + general selector UX) converged on: one
screen, not a wizard; a result that updates live; root chosen as letters with a
separate accidental control (not a 12-button chromatic row, which buries flats and
hits the enharmonic C#/Db trap); and the chord "type" disclosed progressively
(common first, advanced behind a reveal). The mockup iterations landed on a fully
uniform layout.

## Approved design

**Layout (single screen, portrait 390x844):**
- A **"Pick / Browse all" tab** at the top. "Pick" is the new picker (default);
  "Browse all" is today's grouped-by-root library, unchanged.
- **Result card on top**: the selected chord's name + a large `ChordDiagram`,
  updating live as selections change.
- **Four horizontally-scrollable chip strips** below, each a single line with a
  right-edge fade + chevron hinting "swipe for more":
  1. **Note** - the 7 letters C D E F G A B (single-select).
  2. **Sharp / Flat** - a `♮ / ♯ / ♭` single-select (default `♮`). Scrolls only as
     a narrow-screen fallback.
  3. **Family** - the 6 families (below). Scrolls by design so it reads as a calm
     strip, not a wrapped block.
  4. **Type** - the chords *within the selected family*; its contents change with
     the family. Selecting one sets the chord.
- The note + accidental compose the root (e.g. `D` + `♭` -> `Db`); the existing
  enharmonic resolution in `ChordShapes.lookup` maps it to the stored sharp shape,
  and the result card shows the user's chosen spelling.

**The 6 families and their chords (balanced tier = default):**

| Family | Chords (balanced) |
|---|---|
| Major | major, maj7, 6, add9 |
| Minor | minor, m7, m6, madd9 |
| Dominant | 7, 9, 11, 13 |
| Suspended | sus2, sus4 |
| Diminished | dim, dim7, m7b5 |
| Augmented | aug, aug7 |

**Maximal mode (Settings toggle "Maximal chords", default off):** unlocks the rest
of chords-db's standard qualities, each assigned to a family (e.g. Major gains
maj9/maj11/maj13/6add9; Minor gains m9/m11/mmaj7/madd9 variants; Dominant gains
9b5/7b9/7#9/etc.). Slash-bass suffixes and the ambiguous `alt` are excluded. When
on, both the picker's Type strips and the Browse-all library show the full set;
when off, only the balanced tier is shown. The setting persists across restarts.

## Data model

All chord-quality knowledge is instrument-independent and lives in
`packages/models`:

- `ChordFamily` enum: `major, minor, dominant, suspended, diminished, augmented`,
  each with a `label` ("Major", ...). Defines display order.
- `ChordQuality`: `{ suffix (our symbol suffix, e.g. '' | 'm' | 'm7' | '7' | '9'),
  family, label (chip text, e.g. 'Major' | 'm7' | 'maj7'), extended (bool: false =
  balanced, true = maximal-only) }`.
- `kChordQualities`: a const ordered list of every `ChordQuality`. This is the
  single source for what the picker offers and what "Browse all" shows. The
  balanced tier is `where((q) => !q.extended)`.

Voicings stay in the existing `Map<String, ChordShape>` tables
(`chord_shapes_data.dart`), regenerated to cover every `root x kChordQualities`
combination so `ChordShapes.lookup` renders any offered chord. `ChordShape`
(name/frets/baseFret) is unchanged.

### Generator (single source of truth)

`packages/models/tool/gen_chord_shapes.dart` is extended with the master quality
table (suffix -> chords-db suffix, family, tier, label) and now emits TWO committed
files:
- `chord_shapes_data.dart` (the per-instrument shape maps) - as today.
- `chord_qualities_data.dart` (the generated `kChordQualities` list).

`chord_catalog.dart` (hand-written) declares the `ChordFamily` enum + `ChordQuality`
class and re-exports `kChordQualities` from the generated data. Every voicing
remains MIDI-validated against the dataset at generation time. Roots stay
sharp-canonical; flats resolve via the existing enharmonic path.

## Persistence: the "Maximal chords" setting

Follows the established `AppSettings` pattern exactly (write-through, restart-safe):
- `packages/data` drift `AppSettings` table: add
  `BoolColumn get maximalChords => boolean().withDefault(const Constant(false))();`
  Bump `schemaVersion` 2 -> 3; add `onUpgrade` `v2->v3` that `m.addColumn(...)`
  (idempotent, guarded), keeping the existing `_ensureAppSettingsRow` safety net.
- `AppSettingsRecord` gains `maximalChords`; `AppSettingsRepository.update(...)`,
  `_toRecord`, and the seed include it.
- `apps/app` adds a `maximalChordsProvider` (`NotifierProvider<bool>`), seeded from
  `initialAppSettingsProvider`, write-through via the repository - mirroring
  `fontSizeProvider`.
- `main.dart` startup hydration already passes the full `AppSettingsRecord`; the new
  field rides along, no new startup read.

## UI components (apps/app)

Refactor `chords_screen.dart` into a small host + two views, so each file has one
job:
- `ChordsScreen` - hosts the **Pick / Browse all** tab (reuse the app's segmented
  style) and swaps between the two views. Keeps the instrument resolution it
  already has (`showInstrumentPickerProvider` / `selectedInstrumentProvider`,
  forced single instrument when only one is played).
- `ChordLibraryView` - today's grouped-by-root list, extracted verbatim, plus a
  tier filter (balanced unless `maximalChords`).
- `ChordPickerView` (new) - the result card + four strips. Selection is in-memory
  view state (local `ConsumerState`: note letter, accidental, family, quality),
  defaulting to C major. Builds the symbol and renders via `ChordDiagram`.
- `ScrollableChipRow` (new, reusable) - a labelled, single-line horizontally
  scrollable single-select chip row with the right-edge fade + chevron affordance.
  Used for all four strips. One clear responsibility, independently testable.
- Settings: add a `SwitchListTile` "Maximal chords" (with a one-line subtitle)
  bound to `maximalChordsProvider` in `settings_screen.dart`.

Data flow: `note + accidental -> root`; `family -> qualities = kChordQualities
filtered by family and tier`; `quality -> suffix`; `symbol = root + suffix`;
`ChordShapes.lookup(symbol, instrument) -> ChordDiagram`.

## Testing

- **models:** `chord_catalog` tests - every `ChordFamily` has >=1 balanced quality;
  every `kChordQualities` symbol resolves to a shape for both instruments (balanced
  and extended); balanced tier matches the table above. Update
  `chord_shapes_test.dart` counts to the new catalog size.
- **data:** `maximalChords` round-trips through `AppSettingsRepository`; a v2->v3
  migration test (open at v2 schema, upgrade, column present + default false) in the
  style of the existing migration tests.
- **app:** `ChordPickerView` widget tests - default renders C major; tapping a
  Family swaps the Type strip; tapping a Type updates the diagram; `♯` changes the
  root; the Pick/Browse-all tab switches views. Settings test - toggling "Maximal
  chords" persists and reveals extended qualities in the picker.
- **Quality floor:** `dart run build_runner build` (models + data), `flutter analyze`
  clean, `dart format`, all tests pass, `flutter build web` succeeds.

## Out of scope (future)

- Per-chord preferred alternate voicing picker (chords-db ships multiple positions).
- Audio playback of the selected chord.
- Search within the picker (Browse-all keeps its search field).
