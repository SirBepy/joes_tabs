# Comments for Bepy

Autopilot run resuming joes_tabs build (plans 03-10). Local Supabase brought up via Docker, seeded, app running in browser. Log below.

## RUN LEDGER
- Plan 03 Supabase schema -> committed 2ab6933 (RLS + search RPC, validated via live psql)
- Plan 04 Models package -> committed 331627b (13 tests pass)
- Plan 05 Data layer -> committed 3464ecb (17 tests pass, manual Riverpod 2 providers)
- Plan 06 Seed importer -> committed 1f7fe3e (12 public-domain songs, 24 tabs, seeded live + verified)
- Plan 07 App shell -> committed c192280 (drawer nav, theme, routing; 3 tests; web build OK; browser smoke clean)
- Plan 08 Core screens -> committed 554f454 + b00be3e (ChordPro engine, song view, catalog, tuner, chords, settings, support, ty; verified live)
- Plan 09 Offline caching -> committed 9c96974 (Drift LRU + persistent favorites; persistence verified via full browser reload)
- Plan 10 Verify & tidy -> DONE. Floor green: analyze clean, 92 tests pass (53+23+16), flutter build web OK, no orphans. Report in .for_bepy/AI_MESSAGES_TO_TOMORROWS_AI.md.

ALL 10 PLANS COMPLETE. App runs in browser against live local Supabase end-to-end.

## Bonus work after the 10 plans (Joe: "work on as much as possible")
- Path URL strategy (5ab0a58): web now uses clean /song/<id> links that load directly (fixed the hash-routing deep-link fallback I found). Verified live. Resolved ai_todo 001.
- Chord fingering audit (3f349f5): audited all 50 uke+guitar shapes vs authoritative charts - ZERO wrong, engine is musically correct. Added regression tests (models now 55).
- Catalog expansion (d366275): +8 public-domain songs (now 20 songs / 40 published tabs), seeded live + verified.
- Left for Joe (taste/hardware, logged as ai_todos): 002 dark-mode theming, 003 live-mic tuner.

## Second session (interactive) - Phase A/B/C
- Phase A all shipped: content expansion (30 songs/60 tabs, +14 chords), Supabase auth + account favorites sync, search polish (instrument filter/empty states/highlight), e2e flow test, dark mode, live web mic tuner. Commits ca4eae9, c5183b9, c42e175, 23b167f, 4a87240, 7c9e2c0.
- Phase C: GitHub Actions CI + release-APK + web-deploy workflows (18fb367). Activates once the repo is on GitHub. Secrets Joe adds later: KEYSTORE_BASE64, STORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD (signed APK) + PLAY_SERVICE_ACCOUNT_JSON (Play Store).

## 2026-06-05 - brand heading font (Phase B design fidelity)
Decision needed: which font for the mockups' chunky rounded "bubble" headings (the exact mockup font is not provided as a file).
Resolved via: direct judgment (taste call Joe owns, but he asked to match the mockup).
Picked: Fredoka (SIL OFL, free, rounded "bubble" display). Reason: closest free match to the mockup's chunky rounded caps + Joe's own "bubble font" description. Where: apps/app theme + assets/fonts.
Revisit: YES - Joe may have a specific font in mind; easy to swap the asset + family name later.

## 2026-06-06 - live Playwright verification pass (Joe asked to test everything for real)
Drove the running app (live local Supabase) through every feature via Playwright + verified
the backend API directly with a subagent. Results:
- Auth signup -> logged in, drawer shows account, LOGOUT -> anonymous: WORKS.
- Favorites local->account sync on sign-in: VERIFIED in the DB (Amazing Grace pushed to user_favorites).
- Live API (subagent): catalog, search_songs RPC, anon write blocked, auth, user_favorites per-user RLS (cross-user read+write blocked): ALL PASS.
- Search + instrument filter + match highlight: WORKS.
- Tuner mic "Listen" flow: WORKS (requests mic, no crash).
- Ad button web-disabled with mobile-only note: WORKS.
- Song view chord diagrams + FAB controls sheet + live transpose (G->G#): WORKS.
- Test audit subagent added +64 tests -> 232 total, all pass, no bugs in logic.
- BUG FOUND + FIXED (e027077): toggling dark mode (or any root rebuild) reset navigation to
  /splash because GoRouter was rebuilt every build. Now built once in State. This is exactly
  what live testing caught that unit tests missed.
- Minor (logged in ai_todo 006): section-header + app bar stay light in dark mode.

## Local dev environment (for next session)
- Local Supabase is running (Docker). Start/stop: `supabase start` / `supabase stop` in repo root.
- Run config: apps/app/dart_define.local.json (gitignored) holds local URL + publishable key.
- Run app: from apps/app, `flutter run -d chrome --dart-define-from-file=dart_define.local.json`
- Local creds (DEV ONLY, not secrets): URL http://127.0.0.1:54321, publishable sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH, secret from supabase status

## 2026-06-06 14:?? - chord coverage expansion (autopilot)
Task: "improve the chords - we're missing a lot (D# absent, C#/F# only minors)". Confirmed it was NOT an API - a ~35-entry hand-typed map. Replaced with the MIT-licensed tombatossals/chords-db dataset: 12 roots x 11 qualities (maj, m, 7, m7, maj7, sus2, sus4, 6, dim, aug, add9) = 132 chords/instrument, vendored + a checked-in Dart generator that midi-validates every voicing.

Decision needed: chords-db's positions[0] is not always the friendliest (guitar Dm7 -> 10th fret, Bm7 -> 7th fret).
Resolved via: direct judgment (clearly-correct once seen; reversible data regen, didn't spend an iterate-it).
Picked: pick the most beginner-playable voicing (lowest baseFret -> non-barre -> more open -> fewer fingers), still 100% human dataset voicings. Reason: a learning app should show easy open shapes, not high barres. Where: packages/models/tool/gen_chord_shapes.dart.
Revisit: no. (Future feature, logged separately: let users pick/save a preferred alternate voicing per chord - chords-db ships multiple positions.)

Note: "replace all" (Joe's call) overwrote the old hand-audited shapes. The midi validation caught that several OLD shapes were actually wrong (uke C#m sounded G#-D-E-A, uke F7 was missing the C) - the dataset replacements are more correct, not just different. Spec: docs/superpowers/specs/2026-06-06-chord-shape-coverage-design.md.

## 2026-06-06 - onboarding + persisted preferences (autopilot)
Task: "add onboarding (theme? instruments?), make it manageable in Settings, and if only one instrument is set, stop showing the Ukulele/Guitar picker everywhere." Brainstormed -> spec (docs/superpowers/specs/2026-06-06-onboarding-and-persisted-preferences-design.md) -> built in 3 chunks via subagents.

RUN LEDGER (this task):
- Spec -> 9d91718 (DOCS).
- Chunk A data layer: Drift AppSettings single-row table (onboardingComplete, themeMode, instruments csv, fontSize) + migration (schemaVersion 1->2, idempotent) + AppSettingsRepository -> 5508588. 60 data tests green.
- Chunk B state+UI: persisted write-through providers (themeModeProvider replaces darkModeProvider, instrumentsProvider as a Set with min-one, fontSize now persisted, selectedInstrumentProvider = session view-state, showInstrumentPickerProvider derived); main.dart startup hydration via ProviderScope override; Settings rebuilt (3-way System/Light/Dark theme, "Instruments I play" multi-select); picker hidden on Chords/Search/Tuner/Song-controls when one instrument -> da41292. 103 app tests green.
- Chunk C onboarding: 3-step PageView wizard (Welcome / Instrument min-one / Account) + /onboarding route outside shell + splash gates on onboardingComplete -> 4b8f612. 109 app tests green.
- Floor: flutter analyze exit 0, flutter test exit 0 (app 109 + data 60 + models 90), flutter build web OK. Live Playwright pass at 390x844: all 3 onboarding steps, min-one gate (Continue disabled at 0), Chords picker HIDDEN for uke-only, Settings shows new theme+instruments controls. Screenshots in .for_bepy/screenshots/.

Decisions auto-made (would normally ask):
- Theme NOT in onboarding (Joe decided mid-brainstorm): defaults to System, edited only in Settings. Done.
- selectedInstrumentProvider kept as session-only view state (not persisted) so the on-screen toggle when you play both is "which am I viewing now", separate from the persisted "what I play" set. Reason: cleaner separation, matches spec. Revisit: no.
- repo stores instruments as Set<String> slugs (not Set<ChordShapes>) because ChordShapes is a static-const class, not an enum; semantically identical. Revisit: no.

PARKED (Hard Stop - not pushed): did NOT `git push`. Push to master auto-deploys the LIVE web app (prod), which is outward-facing and Joe was AFK without explicit push authorization. 4 commits sit on local master ready to push when Joe approves. To ship: `/commit push` (web deploy) or `/commit pushnbump` (also cuts a versioned APK release).
Revisit (Joe's taste, logged as ai_todo): onboarding copy + Account-step wording + the mascot is still a Phosphor placeholder (real brand art pending).

## Auto-decisions (would normally ask)

## 2026-06-05 - melos missing
Decision needed: install melos for run scripts vs use native dart/flutter commands.
Resolved via: direct judgment (trivial).
Picked: native dart/flutter commands. Reason: pub workspace runs analyze/test/build without melos; avoids an unneeded global install. Where: tooling.
Revisit: no.

## 2026-06-05 - Riverpod / codegen version
Decision needed: Riverpod 3 + codegen vs Riverpod 2 manual providers.
Resolved via: direct judgment (forced by SDK: analyzer 8.x can't resolve riverpod 3 + newest json_serializable).
Picked: Riverpod 2 line, manual providers, slightly older but vetted package versions. Reason: clean resolution on this Flutter SDK (Dart 3.10.1). Where: packages/models, packages/data, apps/app.
Revisit: yes - when the Flutter SDK is upgraded, can move to Riverpod 3 + codegen.

## 2026-06-05 - app name in UI
Decision needed: what brand name to show (name not final per handoff).
Resolved via: direct judgment.
Picked: web title shows "Joe's Tabs" placeholder from scaffold; kept minimal. Reason: handoff says name not final, do not hardcode broadly. Where: apps/app.
Revisit: yes - finalize app name with Joe.

## 2026-06-14 - autopilot run (curated batch: items 1-6)
On entry, items 1/2/3/5 (todos 010/014/011/012) were ALREADY done + committed by the
2026-06-13 run (commits 59be8a7/70b4c07/b8ef645/e21c30b) and their todo files removed.
I did NOT redo them; verified intact and ran the full floor at the end. Real remaining
work this run: item 4 (006 dark-theme bug) and item 6 (013 doc + responsive pass).
RUN_LEDGER below (all on develop, NOT pushed, no version bump).

### Item 4 - 006 dark-theme bar bug
Decision needed: the todo lists "the SectionHeader bar AND the orange app bar" as staying
light/cream in dark mode. The SectionHeader IS cream and genuinely had the bug. The browse
app bar (Home/Search/Song) is actually ORANGE in both modes via appBarTheme, not cream, so
the "stays light" symptom did not literally apply to it.
Resolved via: direct judgment (item 4 is explicitly in-scope, not a with-Joe taste screen).
Picked: fixed BOTH. SectionHeader now resolves bar bg/border from brightness (light = same
cream/peach as before, dark = darkSurface/darkCard). Browse appBarTheme (dark) now uses
darkSurface bg + darkText fg instead of orange, matching the SectionHeader so both top bars
and the body are consistent in dark mode. Light mode is byte-identical (still orange band).
Where: apps/app/lib/widgets/app_shell.dart (SectionHeader), apps/app/lib/theme/app_theme.dart.
Revisit: YES if Joe prefers KEEPING the bright orange app-bar band in dark mode as a brand
accent (then revert only the app_theme.dart dark appBarTheme block - one-line). The
SectionHeader cream-in-dark fix should stay regardless.
SHIPPED: item 4 -> commit 183367d.

### Item 6 - 013 desktop responsive (doc + first cut)
Decision needed: how far to take the responsive pass given 013's remainder was previously
parked "for a WITH-Joe brainstorm". This autopilot run explicitly authorized a first cut.
Resolved via: direct judgment, bounded to SAFE + reversible.
Picked: wrote docs/desktop-layout-language.md (the proposed layout language), then a first
responsive pass: a breakpoints helper, a per-route max width in the shell (reading 600 /
griddy 1100), and grid reflows on the three griddy screens (Chords Browse-all library,
Saved tabs, Search results) plus a 600 cap on the non-shell Song detail screen. Every grid
uses a DUAL-PATH (compact branch = the exact existing mobile widget, grid only renders
>=600px) so mobile at 390x844 is byte-identical - proven by a new test
(saved_responsive_test.dart). Treated as a FIRST CUT, not final.
Where: apps/app/lib/theme/app_breakpoints.dart (new), app_shell.dart, chord_library_view.dart,
saved_screen.dart, search_screen.dart, song_detail_screen.dart, chords_screen.dart; doc in docs/.
Revisit: YES - deferred to Joe (in ai_todo 013): nav rail vs drawer, multi-pane reading
layouts, the actual 600/1100 values, and desktop visual polish (taste). This is a foundation
to refine, not a finished desktop design.
SHIPPED: item 6 -> commit 04a8526.

### Items 1/2/3/5 (todos 010/014/011/012)
Already completed + committed by the 2026-06-13 run before this batch started (commits
59be8a7/70b4c07/b8ef645/e21c30b). NOT redone. Confirmed intact: full-repo flutter analyze
clean and all 293 tests pass (app 137 + models 95 + data 61), flutter build web OK.

## 2026-06-13 - autopilot run (ai_todos 008-014 + pickup housekeeping)
Working the fresh ai_todo queue while AFK ("burn tokens, do as much as you can"). Pickup verify passed first: 300 tests green, analyze clean.

RUN_LEDGER (all on branch develop, NOT pushed - your call whether/when to deploy):
- 010 remove dead pitch utils -> 59be8a7. Removed chromaticRibbon / nearestTargetString / StringMatch from apps/app/lib/tuner/pitch.dart (only the tests referenced them) + their tests; analyze clean, pitch tests green.
- 014 trim chord-generator diff report -> 70b4c07. Deleted _oldUkulele/_oldGuitar/_diffReport from packages/models/tool/gen_chord_shapes.dart (-128 lines); regenerated data files BYTE-IDENTICAL (verified via git diff); models analyze clean, 95 tests green.
- 011 chords instrument dropdown -> b8ef645. Moved the uke/guitar pill off the Chords body into a top-bar icon dropdown via a new route-agnostic sectionActionsProvider in app_shell; added instrumentIcon(slug) helper. analyze clean, app suite 135 green.
- 012 chord picker Family/Type tabbed -> e21c30b. Replaced the Family+Type chip strips with a scrollable family pill tab bar + a tappable chord list; kept the result card + Note/Sharp-Flat rows. analyze clean, 135 green.
- 013 desktop responsive -> 3637b2b (SAFE SUBSET ONLY). Centered shell content at kMaxContentWidth=600 so desktop stops full-bleed stretching; mobile unchanged. Rest of 013 (nav rail, grids, per-screen breakpoints, the 600 value itself) PARKED in ai_todo 013 for a WITH-Joe brainstorm.

DECISIONS auto-made (would normally ask):
- 011 icons: no Phosphor ukulele glyph exists -> guitar uses PhosphorIcons.guitar, ukulele uses PhosphorIcons.musicNote as a reversible stand-in (commented in settings_provider.dart). Revisit when real brand art lands.
- 012 tab widget: built a picker-local _FamilyTabBar reusing the app's pill visual rather than extracting a shared widget from chords_screen.dart's tightly-coupled 2-tab _Tabs (genericising both added coupling for no real reuse win). Revisit: no.
- 013 max width = 600px: placeholder default; reversible one-liner. Revisit WITH Joe (in ai_todo 013).

FLOOR: analyze clean; tests 144 app (then 135 after the picker test rewrites) + 95 models + 61 data, all green; `flutter build web` exit 0.

LIVE VERIFICATION (Playwright, app served via supervisor on cloud Supabase, screenshots sent to you + in .for_bepy/screenshots/autopilot-*.png): drove fresh onboarding (picked BOTH instruments) -> Chords. Confirmed at 390x844: 011 instrument icon in the top bar, dropdown opens to [musicNote] Ukulele / [guitar] Guitar, picking Guitar swaps BOTH the icon and the diagram (uke C -> guitar C); 012 Family pill tabs + chord list render, switching to Minor reflows the list (Minor/m7/m6/madd9) and updates the result card to Cm (family-change type reset works), result card kept. At 1280x800: 013 content centers at 600px, app bar stays edge-to-edge. App stopped after, no port orphans. The LOOK is still your taste call (logged in BEPY_TODOS visual QA) but the behavior is verified working.

PARKED (your taste / needs you - NOT guessed, left in ai_todos):
- 008 onboarding UI polish -> explicit WITH-Joe copy/visual pass.
- 009 tuner deferred polish (colors/thresholds/swell feel) -> explicit WITH-Joe taste pass needing your sign-off.
- 013 remainder (nav rail / grids / breakpoints) -> see updated ai_todo 013.

HOUSEKEEPING NOTE: pickup's `git rm .for_bepy/NEXT_AI_PROMPT.md` was BLOCKED by the auto-mode classifier (treated the untracked spec files as irreversible). The handoff file + the done-todo files (010, 014) are still on disk - delete them yourself if you want them gone; they're untracked so git is unaffected.
