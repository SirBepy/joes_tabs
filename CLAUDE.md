# Joes Tabs - project rules

Personal project. Ukulele/guitar chord-sheet app. Design spec:
`docs/superpowers/specs/2026-05-30-tabs-app-design.md`. The 10 build plans in
`docs/superpowers/plans/` are all complete. Live web app:
https://sirbepy.github.io/joes_tabs/

## Stack
- Flutter (web/iOS/Android), Riverpod 2 (manual providers, no codegen for
  providers), go_router, Phosphor icons. Dart 3.10.1 / Flutter 3.38.3.
- Supabase (Postgres) backend; migrations in `supabase/`. Auth is email-based.
- Drift for local/offline cache. ChordPro tab format (parser/transposer/chord
  shapes live in `packages/models`).
- Native Dart pub workspace. Models in `packages/models`, data + auth in
  `packages/data`, app in `apps/app`. NO Melos - use plain `flutter` / `dart`.

## Code generation (IMPORTANT)
- freezed / json_serializable (models) and drift (data) generate `*.g.dart` /
  `*.freezed.dart`, which are GITIGNORED on purpose. After a clean checkout or a
  model/table change, run `dart run build_runner build --delete-conflicting-outputs`
  in `packages/models` AND `packages/data` before analyze/test/build. CI does this.
- Do NOT force-add generated files.

## Backends
- LOCAL dev: `supabase start` (Docker). Creds in gitignored
  `apps/app/dart_define.local.json`. Analytics is disabled in `config.toml`
  (avoids a Windows container conflict). Email confirmations are off locally.
- CLOUD (prod): Supabase project `joes-tabs` (ref `cqvcgeyxlcofnohlpfjr`). Creds in
  gitignored `.env.local`. Used by the hosted web build + release APK via GitHub
  secrets `SUPABASE_URL` / `SUPABASE_ANON_KEY`. The app uses `publishableKey`, so
  `SUPABASE_ANON_KEY` is the `sb_publishable_...` key.
- Run the seed against either via `supabase/seed/seed.dart`
  (`SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`). Idempotent. Content is
  public-domain only - NEVER scrape Ultimate Guitar or ToS-protected sites.

## Conventions
- Never use the em dash character. Use Phosphor icons, never inline SVG (CustomPaint
  is fine for fretboard/tuner drawings).
- Packages: run the mandatory safety check before adding; auto-add allowed once it
  passes (personal project). Keep secrets in untracked `.env.local` /
  `dart_define.local.json` / GitHub secrets, never committed. Scan tracked files
  before any public push.
- Quality floor before "done": `flutter analyze` clean, `dart format` applied,
  all tests pass (~232 currently), `flutter build web` succeeds. Cap concurrency at
  5; leave no orphan processes (kill `flutter run` web-server and check for stray
  dart.exe).
- Commits go through the `/commit` skill. Stage by name, one purpose per commit.

## GitHub + releases
- Repo: `SirBepy/joes_tabs` (public). Use the `SirBepy` gh account (it has the
  `workflow` scope; `josipmuzic` does not). `gh auth switch --user SirBepy` if needed.
- Push to `master` auto-deploys the web (deploy-web.yml).
- Releases are VERSION-DRIVEN: `/commit pushnbump` bumps root `package.json`, and
  the release-apk workflow publishes a `v<version>` GitHub Release with an APK when
  the version's tag does not yet exist. Plain pushes do not release.

## Testing the running app
- For user-facing changes, verify in a real browser with Playwright at 390x844 (the
  design mockups' size, in `DesignImages/`). Flutter web needs accessibility enabled
  to interact: click the `flt-semantics-placeholder` via evaluate, and full-reload
  (about:blank then the URL) to pick up new code. Throwaway shots go in
  `.for_bepy/screenshots/` (gitignored).

## Open follow-ups
- `.for_bepy/ai_todos/` - design polish (006), native mic (003), and the mascot
  character art (a brand asset Joe will supply; placeholders are Phosphor icons).
- UI polish vs `DesignImages/` is Joe's taste domain - do it WITH him.
