# Plan 08 - Core screens (catalog, song view, chords, tuner, etc.)

Read the spec (sections 1, 6) and `docs/design/screens/`. Depends on: 05, 06, 07.
**Functional wireframe only - no visual polish.**

## Objective
The screens that deliver the actual value: browse, play-along song view, chords,
saved, tuner, settings, support.

## Tasks
1. **Trending/Home:** list songs from `trendingProvider` + a search field bound to
   `searchProvider`. Tapping a song -> song view. Instrument filter (uke/guitar).
2. **Tabs Screen (song view) - the centerpiece:**
   - Parse ChordPro `content` into lines of lyrics with inline chord positions
     (write a small `ChordProParser` in `packages/data` or app; unit-test it).
   - Render chords above lyrics.
   - **Transpose** +/- semitones (transpose chord roots; unit-test the transposer).
   - **Autoscroll** with start/stop + speed control.
   - Favorite toggle (writes to local favorites - integrates with plan 09).
   - Show chord diagrams for the song's chords (from the chord-shape map / data
     in plan 06).
3. **Chords screen:** browse/lookup chord diagrams for ukulele + guitar.
4. **Saved Tabs:** list favorited songs (from local cache, plan 09).
5. **Tuner:** functional tuner if feasible (mic input + pitch detection via a
   vetted package after safety check, e.g. `pitch_detector_dart`/`flutter_audio_capture`)
   OR a scaffolded UI with reference-tone playback per string if mic detection is
   too heavy for the overnight run. Document which was done.
6. **Settings / Support Us / Thank-You:** functional screens (theme toggle in
   settings; Support Us with placeholder donation links + TY confirmation screen).

## Acceptance
- ChordPro parse + transpose + autoscroll work and are unit-tested.
- All listed screens reachable and functional with seeded data.
- `flutter build web` succeeds; `dart analyze` clean.

## Notes
Stage; do not commit. Phosphor icons. No em dashes.
