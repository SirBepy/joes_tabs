# Morning report - joes_tabs (autopilot run 2026-06-05)

Resumed from .for_bepy/TOMORROWS_AI_PROMPT.md. Ran the remaining plans 03-10 INLINE
(no overnight cron). All 8 remaining plans landed, quality floor is green, and the
app was verified running in a real browser against a live local Supabase backend.

## What got built (plans 03-10, all committed)

- 03 Supabase schema (2ab6933): instruments/songs/tabs tables, enums, RLS (anon reads
  only published tabs), `search_songs` RPC. Validated by applying to live Postgres.
- 04 Models (331627b): Instrument, Song, Tab, SongWithTabs + enums via freezed,
  snake_case JSON. 53 unit tests.
- 05 Data layer (3464ecb): CatalogRepository + SupabaseCatalogRepository, env via
  --dart-define, manual Riverpod 2 providers (trending/search/song/instruments).
- 06 Seed (1f7fe3e): 12 public-domain ChordPro songs (Traditional), license audit in
  supabase/seed/SOURCES.md, idempotent seed.dart. Seeded live: 12 songs / 24 tabs.
- 07 App shell (c192280): peach/orange theme, go_router, full-screen slide-out DRAWER
  nav (corrected from the plan's bottom-nav), Supabase init in main.dart.
- 08 Core screens (554f454, b00be3e): ChordPro parser + transposer + chord-shape
  engine + fretboard ChordDiagram; song view (chords-over-lyrics, instrument toggle,
  transpose, autoscroll + speed, favorite); Home/Trending/Search/Saved wired to live
  data; Tuner (note strip + dual triangle pointers + mascot, reference-tone);
  Chords dictionary; Settings; Support Us; Thank-You.
- 09 Offline caching (9c96974): Drift DB (cached_songs/tabs, favorites, recent_views),
  LRU cap 20 (favorites never evicted), OfflineCatalogRepository read-through fallback,
  PERSISTENT favorites. Web support via drift wasm worker (sqlite3.wasm +
  drift_worker.js in apps/app/web/) with in-memory fallback.

## Quality floor (plan 10) - ALL GREEN

- `flutter analyze` (whole workspace): No issues found.
- Tests: models 53 + data 23 + app 16 = 92 passing.
- `flutter build web`: builds successfully.
- No orphan processes left.

## Verified LIVE in a browser (Playwright)

- App boots, connects to local Supabase, Home loads all 12 seed songs.
- Song view renders Amazing Grace with chord diagrams; instrument toggle present.
- Transpose +1 -> Key G#, all chords shift correctly (G->G#, Em->Fm, G7->G#7).
- Favorite a song -> full page reload -> Saved still lists it (Drift web persistence).
- Tuner and Chords screens render per the design correction.
- Zero console errors throughout. Screenshots in .for_bepy/screenshots/ (gitignored).

## Decisions made without Joe (logged in COMMENTS_FOR_BEPY.md)

- Riverpod 2 + manual providers, no codegen (this Flutter SDK's analyzer 8.x cannot
  resolve Riverpod 3 + newest json_serializable). Revisit on SDK upgrade.
- drift 2.31 + sqlite3_flutter_libs 0.5.42 (the analyzer-8-compatible chain;
  drift_flutter/2.33 needs analyzer >=10). Revisit on SDK upgrade.
- Skipped melos; used native dart/flutter commands (workspace doesn't need it).

## Known gaps / suggested next steps (mostly polish, none blocking)

- UI polish pass from DesignImages/ - intentionally deferred to a session WITH Joe
  (his taste dominates). Current screens are functional wireframes at brand level.
- Path-based deep links fall back to Home (Flutter web default hash strategy). In-app
  nav works. To get shareable /song/:id URLs, switch to usePathUrlStrategy + add an
  index fallback. (ai_todo logged.)
- Live mic pitch detection in the Tuner is a documented stub; reference-tone mode
  works. Real mic tuning is best tested on a device. (ai_todo logged.)
- Dark-mode toggle writes state but does not yet re-theme the app. (ai_todo logged.)
- Auth (login/register) screens are stubs - v1 is anonymous/read-only by design.
- App name still "Joe's Tabs" placeholder in web title only; not hardcoded in copy.

## Needs Joe specifically (see BEPY_TODOS.md)

- A HOSTED Supabase project + keys IF you want a deployed/shared backend. The LOCAL
  Supabase stack works fully today; nothing is blocked without this.
- Decide the GitHub account (joephus321 vs josipmuzic vs SirBepy) before any GitHub
  push; origin currently points at the local bare remote.
- Finalize the app name when you're ready.

## How to run it next session

1. `supabase start` (repo root) if the local stack isn't up.
2. From apps/app: `flutter run -d chrome --dart-define-from-file=dart_define.local.json`
   (dart_define.local.json is gitignored and already holds the local URL + key).
</content>
