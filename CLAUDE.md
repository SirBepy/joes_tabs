# Joes Tabs - project rules

Personal project. Ukulele/guitar tabs app. Read the design spec before any work:
`docs/superpowers/specs/2026-05-30-tabs-app-design.md`.

## Stack
- Flutter (web/iOS/Android), Riverpod, go_router, Phosphor icons.
- Supabase (Postgres) backend; migrations in `supabase/`.
- Drift for local/offline cache. ChordPro as the tab format.
- Native Dart pub workspace + Melos. Models in `packages/models`, data layer in
  `packages/data`.

## Conventions
- Never use the em dash character. Use Phosphor icons, never inline SVG.
- Packages: run the mandatory safety check before adding; auto-add allowed once it
  passes (personal project). Keep secrets (Supabase keys) in untracked `.env` /
  `--dart-define`, never committed.
- Quality floor before "done": `dart analyze` clean, `dart format` applied,
  tests pass, `flutter build web` succeeds. Cap concurrency at 5; leave no orphan
  processes.
- Commits go through the `/commit` skill. Stage by name, one purpose per commit.

## Night run
- Implementation plans live in `docs/superpowers/plans/`; execution state in
  `docs/night_run/INDEX.md`. Heavy commands (flutter create, pub get, build_runner,
  flutter build, supabase start) can exceed default command timeouts - use long
  timeouts when running them.
