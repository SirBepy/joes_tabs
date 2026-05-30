# Plan 10 - Verify, harden, and report

Read the spec (section 7). Depends on: all prior plans. This is the final sweep.

## Objective
Make sure the whole thing actually builds, analyzes, and tests green, then leave
Joe a clear morning status report.

## Tasks
1. Run the full quality floor at repo root:
   - `melos run analyze` (or `dart analyze` per package) -> must be clean.
   - `melos run format` / `dart format` -> apply.
   - `melos run test` (unit + widget) -> must pass; fix failures.
   - `flutter build web` in `apps/app` -> must succeed.
2. Fix any breakage introduced by integration between packages (version
   mismatches, codegen drift - re-run `build_runner` where needed).
3. Verify the happy path manually via a widget/integration smoke test: launch ->
   browse seeded songs -> open a song -> transpose -> favorite -> see it in Saved.
4. Process hygiene: confirm no orphan dart/node processes remain (per CLAUDE.md).
5. Write `.for_bepy/AI_MESSAGES_TO_TOMORROWS_AI.md` summarizing: what got built,
   what passed/failed, any plans that hit the failure side-branch, known gaps
   (especially anything needing Joe: Supabase cloud project creation, API keys,
   tuner mic testing on device, UI polish pass), and suggested next steps.
6. Add any genuine Joe-only manual tasks to `.for_bepy/BEPY_TODOS.md`
   (e.g. create Supabase cloud project, set env defines, device tuner test).

## Acceptance
- analyze + tests + web build all green (or remaining failures clearly listed in
  the report with reasons).
- Morning report + BEPY_TODOS written.

## Notes
Stage; do not commit. No em dashes.
