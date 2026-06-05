# Seed content (free / legal starter catalog)

Loads a starter set of public-domain ukulele + guitar songs (ChordPro) into the
local Supabase backend. This is how Joe + his sister get content into v1 (user
submission is v2+).

- `songs/*.cho` - hand-authored ChordPro arrangements of public-domain
  traditional songs.
- `SOURCES.md` - license audit: the legal basis for every song (all PD).
- `seed.dart` - idempotent loader that upserts songs + published tabs.

All content is public domain. Nothing is scraped from Ultimate Guitar or any
ToS-protected site. See `SOURCES.md` for the full audit and the research on why
no free/legal song-sheet API was usable.

## Prerequisites

- Local Supabase stack running (`supabase start`), with migrations applied
  (`supabase db reset`). The migration seeds the `ukulele` and `guitar`
  instruments; the seed script looks them up by slug.
- Dart on PATH (the script is standalone: only `dart:io` + `dart:convert`, no
  `pub get` required).

## Run

The script reads its connection config from the environment. The `service_role`
key bypasses RLS and is used for seeding ONLY - it is never committed and never
shipped in the Flutter app (the app uses the `anon` key).

PowerShell (local stack):

```powershell
$env:SUPABASE_URL = "http://127.0.0.1:54321"
$env:SUPABASE_SERVICE_ROLE_KEY = "<service_role key from `supabase start`>"
dart run supabase/seed/seed.dart
```

It is **idempotent**: songs and tabs use deterministic UUIDs and are upserted
with `Prefer: resolution=merge-duplicates`, so re-running updates rows in place
and never duplicates.

### What it does

1. Resolves the `ukulele` / `guitar` instrument ids by slug.
2. Parses each `.cho` file's `{title:}`, `{artist:}`, `{key:}` directives.
3. Upserts one row per song into `songs`.
4. Upserts one **published** tab per instrument per song into `tabs`
   (`source = official`, `status = published`), so the rows are anon-visible
   under RLS.

## Verify

```powershell
docker exec supabase_db_joes_tabs psql -U postgres -c "select count(*) from songs;"
docker exec supabase_db_joes_tabs psql -U postgres -c "select count(*) from tabs where status = 'published';"
docker exec supabase_db_joes_tabs psql -U postgres -c "select title, artist from search_songs('amazing');"
```

## Adding a song

1. Drop a new `name.cho` under `songs/` with `{title:}`, `{artist: Traditional}`,
   `{key:}` and inline `[Chord]` markers. Use only public-domain material and add
   a row to `SOURCES.md`.
2. Add a deterministic UUID for the song slug to `songIds`, and for each
   instrument to `tabIds`, in `seed.dart`.
3. Re-run the seed.

## Chord-diagram data (future Chords UI)

The Chords UI will render chord *shapes* (fingerings) for ukulele (GCEA) and
guitar (EADGBE). Chord shapes are factual diagrams, not copyrightable
arrangements, so a static shape map can be authored locally or sourced from an
Uberchord-style chord API without any song-licensing concern. This is separate
from the song sheets seeded here and is tracked for the Chords UI plan.
