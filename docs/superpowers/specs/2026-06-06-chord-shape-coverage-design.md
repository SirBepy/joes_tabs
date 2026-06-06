# Chord-shape coverage expansion

Date: 2026-06-06
Status: approved (design)

## Context

The Chords library and the per-song chord diagrams are driven by a single
hand-written static map in `packages/models/lib/src/chordpro/chord_shapes.dart`
(`_ukulele` and `_guitar`, ~35 entries each). It is NOT an API. Because the set
was typed by hand it is patchy: `D#`/`Eb` is absent entirely, `C#` and `F#` have
only their minor, and most sharps/flats are missing their `7`/`m7`/`maj7`/`sus`/
`6`/`dim`/`aug`/`add9` variants. The Chords screen lists exactly the map keys
(`ChordShapes.namesFor`), so users see a sparse, inconsistent library.

Goal: a complete, uniform, human-curated chord library for the two supported
instruments, sourced from a reputable open dataset and baked into the app.

## Decision summary (approved)

- **Source:** `tombatossals/chords-db` (GitHub), MIT licensed, vetted safe. Ships
  both `guitar` (EADGBE) and `ukulele` (re-entrant high-G GCEA) with all required
  qualities. Tunings and string order match our existing data exactly.
- **Replace, not merge:** the new dataset is the single source of truth. The
  previously hand-audited voicings are overwritten so the whole library is
  consistent. A one-time diff report (old audited -> new) is produced and
  surfaced to Joe to eyeball any surprising common-chord changes.
- **Vendored + reproducible:** a checked-in Dart generator plus the two pinned
  chords-db JSON files. Regeneration is offline and deterministic; adding more
  qualities later is a one-line change.

## Coverage

- Roots (canonical, sharp-spelled): `C C# D D# E F F# G G# A A# B`.
- Qualities and our symbol suffix:
  | quality   | chords-db suffix | our symbol (root = C) |
  |-----------|------------------|-----------------------|
  | major     | `major`          | `C`                   |
  | minor     | `minor`          | `Cm`                  |
  | dom 7     | `7`              | `C7`                  |
  | minor 7   | `m7`             | `Cm7`                 |
  | major 7   | `maj7`           | `Cmaj7`               |
  | sus2      | `sus2`           | `Csus2`               |
  | sus4      | `sus4`           | `Csus4`               |
  | 6         | `6`              | `C6`                  |
  | dim       | `dim`            | `Cdim`                |
  | aug       | `aug`           | `Caug`                |
  | add9      | `add9`           | `Cadd9`               |
- 12 x 11 = **132 chords per instrument**, 264 total.
- Enharmonic flats (`Db`, `Eb`, `Gb`, `Ab`, `Bb`) and slash chords continue to
  resolve through the existing `lookup` logic; only sharp-spelled keys are stored.

## Data format & conversion

`ChordShape` is unchanged: `frets` are ABSOLUTE fret numbers (one per string,
`0` open, `-1` muted), `baseFret` is the diagram window start. chords-db stores
frets RELATIVE to `baseFret`, so the generator converts:

```
absolute = baseFret + relativeFret - 1   (for relativeFret >= 1)
0  -> 0   (open)
-1 -> -1  (muted)
```

It sets `ChordShape.baseFret` from the position's `baseFret`. The generator picks
`positions[0]` (the dataset's primary voicing) for each chord. **Every converted
voicing is validated against the position's shipped `midi` array** (open-string
MIDI + computed absolute fret must reproduce the sounding pitches); a mismatch
fails generation loudly. String order matches ours (index 0 = first tuning string:
low-E on guitar, high-G on ukulele).

**Storage change (required):** today the maps are `Map<String, List<int>>` with
`baseFret` defaulting to 1. Full coverage includes many barre voicings up the neck
(`baseFret > 1`), so each entry must now carry its own `baseFret`. The generated
maps therefore store full `const ChordShape` instances
(`Map<String, ChordShape>`) instead of bare fret lists. `lookup` returns the entry
directly (swapping `name` only for slash/enharmonic display), and `namesFor`
continues to read the keys. `ChordShape` is already `const`-constructible, so the
literals stay compile-time constants.

## Components

- `packages/models/tool/chords_db/guitar.json`, `ukulele.json` - vendored, pinned
  to a specific chords-db commit (SHA recorded in the generator header).
- `packages/models/tool/gen_chord_shapes.dart` - reads the vendored JSON, converts
  + validates, emits `chord_shapes_data.dart`. Also prints the old->new diff report
  for the chords that were previously hand-audited.
- `packages/models/lib/src/chordpro/chord_shapes_data.dart` - GENERATED, COMMITTED
  (not `.g.dart`, so not gitignored). Contains only the two
  `Map<String, ChordShape>` literals.
- `packages/models/lib/src/chordpro/chord_shapes.dart` - keeps the `ChordShape`
  class and `lookup`/`namesFor`/enharmonic/slash logic; its two map literals are
  replaced by references to the generated data file.
- `THIRD_PARTY_LICENSES.md` (repo root) - MIT attribution for chords-db / David
  Rubert.

## Testing

- Rewrite `packages/models/test/chord_shapes_test.dart`:
  - **Coverage:** all 132 root x quality symbols resolve for both instruments.
  - **Structure:** every shape has the right string count (4 uke / 6 guitar) and
    all fret values are in `{-1, 0..~20}`.
  - **Spot-check goldens:** a small set of exact-fret assertions taken from the
    regenerated data (regenerate-friendly), to catch accidental data corruption.
  - Keep the enharmonic, slash-chord, and unknown-symbol behavior tests.
- Quality floor: `dart run build_runner build` (models + data), `flutter analyze`
  clean, `dart format`, all tests pass, `flutter build web` succeeds.

## Out of scope (future)

- Letting users choose/save a preferred alternate voicing per chord (chords-db
  ships multiple `positions`; we only bake `positions[0]` now). Separate
  persistence + UI feature.
- Surfacing the third-party attribution in an in-app About/Support screen.
