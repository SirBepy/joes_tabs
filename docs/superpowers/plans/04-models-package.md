# Plan 04 - Shared models package

Read the spec (section 4). Depends on: 01, 03.

## Objective
Pure-Dart domain models in `packages/models`, mirroring the DB schema, usable by
both the app and any tooling.

## Tasks
1. Add `freezed` + `json_serializable` + `build_runner` (dev) after safety check.
2. Models (immutable, with `fromJson`/`toJson`):
   - `Instrument` (id, slug, name, stringCount, defaultTuning).
   - `Song` (id, title, artist, createdAt, updatedAt).
   - `Tab` (id, songId, instrumentId, content, originalKey, capo, difficulty,
     source enum, status enum, authorId, timestamps).
   - `SongWithTabs` convenience aggregate (song + its tabs).
   - Enums `TabSource`, `TabStatus`, mapped to/from the DB string values.
3. A `ChordPro` value layer is NOT here (lives in data/app); models stay data-only.
4. Unit tests: round-trip `fromJson`/`toJson` for each model with realistic
   Supabase-shaped JSON (snake_case keys).

## Acceptance
- `dart analyze` clean; `build_runner` generates without errors.
- All round-trip tests pass.

## Notes
Stage; do not commit. snake_case JSON keys (Supabase). No em dashes.
