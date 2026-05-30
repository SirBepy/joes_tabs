# Plan 03 - Supabase schema & local dev

Read the spec (sections 4, 5). Depends on: 01.

## Objective
Define the Postgres schema via Supabase migrations and a local dev setup.

## Tasks
1. Initialize Supabase in repo: `supabase init` (creates `supabase/config.toml`).
   Do NOT require a cloud project at build time - everything must work against
   `supabase start` (local Docker) so the overnight run can apply + verify migrations.
   If Docker is unavailable, still author the migration SQL and validate it with
   `dart`/`psql` against a throwaway local Postgres if possible; otherwise document
   that migrations are authored but unapplied and mark acceptance accordingly.
2. Migration `0001_init.sql` implementing spec section 4:
   - `instruments` lookup table seeded with `ukulele` (4 strings, GCEA) and
     `guitar` (6 strings, EADGBE).
   - `songs` with generated `search_tsv` tsvector (title + artist) + GIN index.
   - enums: `tab_source` (`official`,`imported`,`community`),
     `tab_status` (`draft`,`published`).
   - `tabs` with fks, `content` text (ChordPro), key/capo/difficulty, source,
     status, nullable `author_id`, timestamps. Index on `(song_id)` and `(status)`.
3. RLS: enable on `songs` + `tabs`. Public `select` policy limited to
   `tabs.status = 'published'` and their parent songs. No public insert/update/delete.
4. A SQL view or RPC `search_songs(query text)` using FTS for the app to call.
5. Document in `supabase/README.md`: how to `supabase start`, apply migrations,
   and where the service-role key is used (seeding only, never in the app).

## Acceptance
- Migrations apply cleanly to a local Supabase/Postgres (or documented blocker).
- RLS verified: anon can read published tabs only.
- `search_songs` returns rows for a title substring.

## Notes
Stage; do not commit. Keep secrets out of the repo (.env is gitignored). No em dashes.
