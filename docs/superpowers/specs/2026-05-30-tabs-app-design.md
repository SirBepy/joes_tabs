# Ukulele/Guitar Tabs App - Design Spec

> Working title: `joes_tabs` (final name TBD). Single source of truth for the
> overnight build. Every plan file in `docs/superpowers/plans/` references this.

## 1. Product

A cross-platform app for browsing and **playing along to** ukulele and guitar
tabs/chord sheets. Start ukulele + guitar; architecture stays instrument-agnostic
so bass/others can be added later.

### MVP (v1) - what this overnight run builds
Functional wireframes (NOT polished UI) of the core experience:
- Browse a catalog (trending/home, by instrument)
- Search by title/artist
- Open a song -> render chord sheet, show chord diagrams, **transpose**,
  **autoscroll** with speed control
- Favorite/save songs (local, no account needed)
- Tuner screen (functional or scaffolded)
- Settings, Welcome/Splash, Support Us, Sign-up/Log-in screens
- Offline: favorites + last ~20 viewed songs cached locally

### Out of scope for v1 (later)
- UI polish / visual design from `DesignImages/` (done later, with Joe)
- Public user submission of tabs / user-authored music (v2-v3)
- Full account-gated features (accounts are optional in v1.1; v1 is anonymous)

## 2. Decisions (locked)

| Area | Choice | Why |
|---|---|---|
| Frontend | **Flutter** (web + iOS + Android, single codebase) | one codebase, top-tier animations/perf, matches Joe's toolchain |
| State | **Riverpod** | Joe's standard; `keepAlive` for session state |
| Routing | **go_router** | official, declarative, deep-link ready |
| Icons | **Phosphor** (`phosphor_flutter`) | global rule: always Phosphor, never inline SVG |
| Backend | **Supabase (Postgres)** | lowest maintenance: managed Auth + sync + storage for later accounts/UGC, first-class Flutter SDK, generous free tier, still real Postgres |
| DB | **Postgres** via Supabase; migrations in `supabase/migrations/` | proper relational; full-text search built in |
| Local cache | **Drift** (SQLite) | queryable offline store for favorites + recent songs |
| Monorepo | **Melos**-managed Dart workspace | one tool governs all Dart packages |
| Tab format | **ChordPro** (chords-over-lyrics) | enables transpose + autoscroll cleanly; tablature ASCII deferred |
| Content (v1) | seed from a **free, legal** chord API; fallback to hand-authored ChordPro | UGC is v2+ |

**Full-Dart (Dart Frog) was considered and rejected** for v1: Supabase removes the
need to hand-build auth/sync, which directly serves Joe's "minimal involvement"
priority. Revisit only if Supabase limits bite.

## 3. Monorepo layout

```
joes_tabs/
  apps/
    app/                # Flutter app (all platforms)
  packages/
    models/             # shared Dart domain models (Song, Tab, Instrument...)
    data/               # repositories, Supabase client, Drift cache, Riverpod providers
  supabase/
    migrations/         # SQL schema migrations
    seed/               # seed script + ChordPro fallback songs
    functions/          # edge functions (later)
  tools/
    add_song/           # CLI helper to author a ChordPro song file (later)
  docs/
    superpowers/specs/  # this spec
    superpowers/plans/  # implementation plans (consumed by /cron-run)
    night_run/          # queue + INDEX + log (managed by /cron-run)
    design/screens/     # one .md per DesignImages screen (what it has/does)
  DesignImages/         # source PNG mockups (provided by Joe)
  melos.yaml
  pubspec.yaml          # workspace root
```

## 4. Data model (Postgres)

- `instruments` (enum-ish lookup): `id`, `slug` (ukulele|guitar), `name`,
  `string_count`, `default_tuning`
- `songs`: `id` (uuid), `title`, `artist`, `created_at`, `updated_at`,
  `search_tsv` (generated tsvector over title+artist for FTS)
- `tabs`: `id`, `song_id` (fk), `instrument_id` (fk), `content` (ChordPro text),
  `original_key`, `capo` (int, nullable), `difficulty` (nullable),
  `source` (enum: `official` | `imported` | `community`),
  `status` (enum: `draft` | `published`), `author_id` (nullable, for future accounts),
  `created_at`, `updated_at`
- A song may have multiple tabs (per instrument / version). v1 seeds >=1 published tab/song.
- RLS: public `select` on `published` tabs + their songs; writes locked down
  (seeding uses the service role). Designed so account-scoped favorites/UGC slot in later.

## 5. Local cache (Drift) & offline

- Mirror tables for `songs` + `tabs` content of: (a) favorited songs,
  (b) last ~20 viewed songs (LRU eviction).
- `favorites` table: `song_id`, `created_at`. Local-only in v1.
- Recently-viewed: `song_id`, `viewed_at`; cap 20, evict oldest.
- Repos are **online-first**: fetch from Supabase, write-through to cache; on
  network failure, serve from cache. Favorited/recent content readable fully offline.
- **Accounts migration (future):** local favorites are pushed to the user's
  account on first sign-in (nothing lost). Schema keeps `song_id` stable to allow this.

## 6. Screens (from DesignImages + MVP)

Splash, Welcome, Sign-Up, Log-In, Navbar (bottom nav shell), Trending/Home,
Tabs Screen (song view: chords + diagrams + transpose + autoscroll), Chords,
Saved Tabs, Tuner, Settings, Support Us, Thank-You (TY). Plan `02` documents each
from the mockups; plans `07`/`08` build functional wireframes (no polish).

## 7. Quality floor (every plan)

- `dart analyze` clean; `dart format` applied.
- Unit/widget tests for non-trivial logic (ChordPro parse/transpose, cache LRU, repos).
- `flutter build web` succeeds.
- Process hygiene: no orphan node/dart processes; cap concurrency at 5.
- Packages: run the mandatory safety check before adding (personal project ->
  auto-add once check passes). Pinned standard packages are listed per plan.

## 8. Constraints for overnight agents

- Each plan is one `/cron-run tick`: fresh session, no inherited chat context.
  Read THIS spec first, then the plan.
- Stage changes; do NOT commit (the tick harness handles `/commit`).
- Never use the em dash character. Use Phosphor icons. Follow global CLAUDE.md.
- If a free/legal tab API can't be found, fall back to hand-authored ChordPro
  songs (a small set) and document the decision - do not scrape ToS-protected sites.
