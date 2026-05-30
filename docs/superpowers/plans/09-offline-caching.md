# Plan 09 - Offline caching (Drift)

Read the spec (section 5). Depends on: 04, 05. Can land before/after 08 but the
song view + saved screen consume it.

## Objective
Local-first caching so favorites and the last ~20 viewed songs work offline.

## Tasks
1. Add `drift` + `sqlite3_flutter_libs` + `drift_dev`/`build_runner` (after safety check).
2. Drift DB in `packages/data` with tables:
   - `cached_songs` (song fields), `cached_tabs` (tab fields, content),
   - `favorites` (song_id, created_at),
   - `recent_views` (song_id, viewed_at).
3. `OfflineCatalogRepository` decorating the Supabase `CatalogRepository`:
   - reads write-through to cache; on network error, serve from cache,
   - `getSong` records a recent view; enforce **LRU cap of 20** (evict oldest,
     but never evict favorited songs' content),
   - favorite/unfavorite + `watchFavorites()` stream for the Saved screen.
4. Riverpod providers updated so the app uses the offline-decorated repo.
5. Tests: LRU eviction (cap 20, favorites protected), favorite add/remove,
   offline fallback when the remote throws.

## Acceptance
- Favorited + recently-viewed songs render with the network disabled.
- LRU + favorite-protection tests pass.
- `flutter build web` succeeds; `dart analyze` clean.

## Notes
Stage; do not commit. Design `song_id` keys to allow future account migration
(spec section 5). No em dashes.
