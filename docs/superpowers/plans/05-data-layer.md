# Plan 05 - Data layer (Supabase client + repos + providers)

Read the spec (sections 2, 4, 5). Depends on: 01, 03, 04.

## Objective
`packages/data`: Supabase client wiring, catalog repository, and Riverpod
providers the app consumes. Cache integration is stubbed here and completed in 09.

## Tasks
1. Add deps (after safety check): `supabase_flutter`, `flutter_riverpod`,
   `riverpod_annotation` (+ `riverpod_generator`/`build_runner` dev) or plain
   Riverpod providers - pick one and be consistent.
2. `SupabaseClient` init helper reading config from `--dart-define` /env
   (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); never hardcode keys. Provide a clear
   error if unset, and a `lib/src/env.dart` documenting the defines.
3. `CatalogRepository` interface + Supabase implementation:
   - `trending()` / `listSongs({instrumentSlug})` -> `List<Song>`.
   - `search(query)` -> calls `search_songs` RPC.
   - `getSong(id)` -> `SongWithTabs` (song + published tabs).
4. Riverpod providers: `supabaseClientProvider`, `catalogRepositoryProvider`,
   `trendingProvider`, `searchProvider(query)`, `songProvider(id)` (use
   `AsyncNotifier`/`FutureProvider`). Keep a `CatalogRepository` abstraction so the
   offline wrapper (plan 09) can decorate it.
5. Tests: repo against a faked Supabase response (or a thin interface mock) for
   list/search/get mapping.

## Acceptance
- `dart analyze` clean; codegen runs.
- Provider/repo tests pass.
- App can (in plan 07/08) read catalog data through these providers.

## Notes
Stage; do not commit. No secrets in repo. No em dashes.
