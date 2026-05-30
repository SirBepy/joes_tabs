# Plan 01 - Monorepo scaffold

Read `docs/superpowers/specs/2026-05-30-tabs-app-design.md` first (sections 3, 7, 8).

## Objective
Stand up the Melos-managed Dart/Flutter monorepo skeleton. No app logic yet -
just structure, tooling, and config that everything else builds on.

## Tasks
1. Create root `pubspec.yaml` as a Dart **workspace** (`workspace:` listing the
   member packages) targeting the installed Dart 3.10 SDK.
2. Add `melos.yaml` (name `joes_tabs`) with scripts: `analyze`, `format`,
   `test`, and a `get` bootstrap. Cap any concurrency at 5.
3. Create package dirs with minimal valid `pubspec.yaml` each:
   - `apps/app` (Flutter app - run `flutter create` into it, org `com.joestabs`,
     platforms: web, android, ios; remove default counter sample from
     `lib/main.dart`, leave a minimal `MaterialApp` placeholder).
   - `packages/models` (pure Dart).
   - `packages/data` (Flutter package - depends on models).
4. Add root `analysis_options.yaml` using `package:lints/recommended.yaml` (or
   `flutter_lints` for Flutter packages); enable strict-casts. Ensure
   `dart format` passes repo-wide.
5. Update `.gitignore` for Dart/Flutter: `.dart_tool/`, `build/`, `.flutter-plugins*`,
   `*.iml`, `.idea/`, `.fvm/`, `**/.env`, `**/*.g.dart` NOT ignored (we commit
   generated? -> DO ignore generated `*.g.dart`/`*.freezed.dart` is optional; keep
   them ignored and rely on build_runner). Keep existing `.DS_Store node_modules/ dist/ .env`.
6. Root `README.md`: one-paragraph project description + how to bootstrap
   (`dart pub get` / `melos bootstrap`) + link to the spec.
7. Add a project `CLAUDE.md` at repo root noting: personal project (auto-add
   packages after safety check), Flutter+Supabase stack, link to spec, and the
   `@import ~/.claude/...` lines are NOT needed - just summarize key rules.

## Acceptance
- `dart pub get` (or `melos bootstrap`) succeeds at root.
- `dart analyze` is clean across all packages.
- `flutter build web` succeeds in `apps/app` (placeholder app).
- No orphan processes left running.

## Notes
Stage everything; do not commit. Use Phosphor later, not here. No em dashes.
