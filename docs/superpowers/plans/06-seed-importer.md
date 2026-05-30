# Plan 06 - Seed importer (free/legal content)

Read the spec (sections 1, 2, 8). Depends on: 03, 04.

## Objective
Populate the catalog with a starter set of ukulele + guitar songs in ChordPro,
from a **free and legally usable** source. This is how Joe + his sister get
content into v1 (UGC submission is v2+).

## Tasks
1. **Research first** (dispatch a subagent): find a free, legal API or open
   dataset for chords/chord sheets. Candidates to evaluate: Uberchord API
   (chord shapes), public-domain song lyric/chord datasets, ChordPro sample
   repos, MusicBrainz (metadata only). Record findings + license terms in
   `supabase/seed/SOURCES.md`. **Do NOT scrape Ultimate Guitar or any ToS-protected
   site.** If nothing suitable/legal is found, proceed to step 2 fallback.
2. **Fallback (always include):** author ~10-15 hand-written ChordPro songs
   (public-domain / traditional songs to avoid licensing issues, e.g. folk
   standards) as `.cho` files under `supabase/seed/songs/`, covering both ukulele
   and guitar, varied keys.
3. A Dart seed script `supabase/seed/seed.dart` (or a `tools/` entry) that:
   - parses `.cho` files (title/artist/key from ChordPro directives),
   - upserts songs + published tabs via the Supabase **service role** key
     (from env, never committed),
   - is idempotent (re-running does not duplicate).
4. Document `melos run seed` (or `dart run`) usage in `supabase/seed/README.md`,
   including chord-diagram data source (a static chord-shape map for uke + guitar
   if no API), used later by the Chords UI.

## Acceptance
- Seed script runs idempotently against local Supabase and inserts the fallback
  songs (and API songs if a legal source was found).
- `SOURCES.md` documents the legal basis for any imported content.

## Notes
Stage; do not commit. Legality is a hard gate. No em dashes.
