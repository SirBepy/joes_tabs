# Plan - Ukulele Tabs demo: strings nav bar, swipe between tabs, color schemes

Branch `ut-client`, worktree `C:\Users\tecno\Desktop\Projects\joes_tabs_ut`. Never the main checkout
(`develop`). Commits go through `/commit` by pathspec with `--expect-branch ut-client`. Run `fvm flutter` /
`fvm dart`, never bare. Never push without Joe asking.

## Where this comes from

The 2026-10-28 restyle session (`/impeccable` polish of the demo) landed on `ut-client` as c3bee84,
39206a3, 9b37f66 and 598671d: sky band with white text, deep-blue actions (`AppColors.rust` #176FA0),
white cards, Version N labels on repeated search results, artist name in the song page bar, chord strip
running to the screen edge, round song-controls FAB, Settings with one label font, Theme inline, the
rewarded-ad row back, and Account pinned to the bottom. None of the work below is coded yet.

## Decided by Joe (2026-10-28, do not re-ask)

1. **Bottom bar = "Four strings", no labels.** Four thin horizontal lines along the bar's top edge (the
   G C E A strings), a sky-blue dot sitting on them above the active tab, icons only (active icon filled,
   in the accent). No pill. Mockup: the `ut-nav-options` preview card from that session, option B.
2. **The dot slides.** It animates to the new tab on tap, and tracks the finger continuously while
   swiping between pages.
3. **Swipe left/right between the five tab pages.**
4. **Color schemes, user-pickable:**
   - `Ukulele-tabs`: yellow mostly, plus blue. Joe likes this one best.
   - `Ukulele-tabs yellow`: yellow, none of the blue.
   - `Ukulele-tabs blue`: the current look, unchanged.
   - Joe's own scheme(s): the original Joe's Tabs warm palette (see Assumptions).

## Assumptions - confirm with Joe in ONE question card before coding

Ask these together (`ask_user_question`, `ux` questions need previews), then build:

- **"My color schemes" = `develop`'s warm palette**, light and dark: orange #F5A623, rust #D9822B, peach
  #FFE6CC, cream #FFF6EC, cardPeach #FFEFD9, textDark #3D2B1F, textMuted #8A7866; dark: background
  #221A14, surface #2E241C, card #3A2D22, text #F3E9DD, muted #B7A48E
  (`git show develop:apps/app/lib/theme/app_colors.dart`). Is that one scheme, or does Joe have more?
- **Default scheme** for a fresh install: `Ukulele-tabs` (yellow + blue), since Joe prefers it.
- **Every scheme gets a dark variant.** The existing System / Light / Dark setting stays and applies
  on top of the chosen scheme.
- **Text on a yellow band is navy/dark, not white.** White on yellow is unreadable, roughly 1.5:1. On the
  blue scheme the band stays white-on-sky by Joe's choice (2.85:1, accepted 2026-10-28).
- **Picker UI:** a "COLOR SCHEME" row in Settings, under Theme, showing 4 tappable swatch circles
  (two-tone where a scheme has two colors), with the active one ringed. Show a mockup in the question.
- **The yellow hex:** sample ukulele-tabs.com's own yellow from their site CSS or the logo Joe has. The
  logo file is NOT committed (public repo). Propose the hex in the question.
- **Wide layout (600px+ side rail):** keep the NavigationRail but drop its pill to match (filled accent
  icon, no indicator). Strings on a vertical rail are out of scope unless Joe wants them.

## Task 1 - Four-strings bottom bar (`apps/app/lib/widgets/app_shell.dart`, `_TabBar`)

- Replace the `NavigationBar` with a custom bar: a `CustomPaint` strip (4 hairlines, about 13dp tall,
  string colour from the palette) plus a `Row` of five 48x48+ icon buttons (Android touch-target floor).
- The dot's horizontal position is driven by a `double` page value (Task 2's `PageController.page`), so
  it slides continuously during a swipe and animates on tap (`animateToPage`). Honor
  `MediaQuery.disableAnimations`: jump instead of animate.
- Icons only, but every destination keeps its name for accessibility: `Semantics(label:, selected:,
  button: true)` or `Tooltip(message: tab.label)`. Keep `Key('app-navigation-bar')` on the bar.
- Keep `_onSelect`'s current behavior: re-tapping the active tab pops its stack, then scrolls to top.
- Tests: `test/bottom_nav_test.dart` finds tabs by label text and by `NavigationBar` /
  `NavigationDestination`. Switch those finders to the tooltip/semantics label. Add tests for: no
  visible label text in the bar, the dot under the active index after a tap, and semantics names
  present.

## Task 2 - Swipe between tabs (`apps/app/lib/router/app_router.dart`, `app_shell.dart`)

- The shell is `StatefulShellRoute.indexedStack` (app_router.dart:53). Switch to
  `StatefulShellRoute(navigatorContainerBuilder: ...)` that lays the branch navigators in a `PageView`
  with a `PageController` shared with the bar. `onPageChanged` calls `navigationShell.goBranch(i)`, and
  a `goBranch` from a tap or a deep link animates the controller.
- Keep each branch's state alive (the PageView children must not rebuild or dispose: use
  `AutomaticKeepAlive` or keep all children mounted), so scroll positions and pushed pages survive, as
  with `indexedStack` today.
- Gesture conflicts: inner horizontal scrollables must win (the Chords note/quality chip rows, the
  Pick/Browse toggle, the tuner's ruler if it drags). Flutter's arena gives the inner scrollable
  the drag while it can still scroll. Verify each by hand on the emulator.
- Pushed pages are top-level routes (song, search, login, register: app_router.dart:119-143), so swiping
  only applies on the five tab roots and their in-branch pages (Trending, Support).
- Back behavior (`_AppShellState._onBack`) must keep working: non-Home tab goes to Home (now
  animated), Home scrolled scrolls to top, then the exit prompt. Run `test/back_navigation_test.dart`.
- Tests: a horizontal fling on Home lands on Saved (or Chords, by direction); the bar's selected
  index follows; branch state survives a swipe away and back.

## Task 3 - Color schemes (theme layer, settings persistence, Settings UI)

1. **Scheme model** (`apps/app/lib/theme/`): an enum `AppColorScheme { ukuleleTabs, ukuleleTabsYellow,
   ukuleleTabsBlue, joesTabs }`, each supplying a light and a dark `AppPalette` plus the `ThemeData`
   inputs. `AppTheme.light/dark` become `AppTheme.light(scheme)/dark(scheme)`.
2. **Move the remaining hard-coded brand colours onto palette roles.** 26 `AppColors.orange/rust` uses
   sit outside `lib/theme/` (`grep -rn "AppColors\.\(orange\|rust\)" lib | grep -v ^lib/theme`). Add
   roles to `AppPalette` so a scheme can recolour them: `band` + `onBand` (app bar, search band),
   `action` + `onAction` (filled buttons, FAB, selected chips/toggles, today `AppColors.rust`),
   `decor` (diagram dots, mascot, tuner border, strings dot, today `AppColors.orange`). The existing
   roles stay: `accent`, `sheet`, `card`, `chip`, `divider`, `ink`, `mutedInk`. Remove
   `AppColors` constants that end up unused.
3. **Persist the choice** (it must survive an app restart; Drift already stores themeMode):
   - `packages/data/lib/src/drift/app_database.dart:76` sits beside `themeMode`. Add
     `TextColumn colorScheme` with default `'ukulele-tabs'`, bump `schemaVersion` 4 -> 5, and add an
     `addColumn` migration step.
   - `packages/data/lib/src/settings/app_settings_repository.dart`: add the field, plus `update(colorScheme:)`.
   - Run `dart run build_runner build --delete-conflicting-outputs` in `packages/data` (generated
     files are gitignored, never force-add).
   - `apps/app/lib/state/settings_provider.dart`: add a `ColorSchemeNotifier` mirroring
     `ThemeModeNotifier` (line 92), with to/from-string helpers and an unknown value falling back to
     the default.
   - `main.dart`: build `theme`/`darkTheme` from the watched scheme.
   - Tests: a migration test in `packages/data/test` (v4 db opens and gains the default column),
     round-trip persistence, and provider fallback.
4. **Settings UI** (`apps/app/lib/screens/settings_screen.dart`): the COLOR SCHEME row from the
   Assumptions, with `_labelStyle` for the label and keys `color-scheme-<id>`. Tests: tapping a swatch
   updates and persists the provider; the active swatch is marked.
5. **Per-scheme contrast check**: body and placeholder text 4.5:1 or more, large text and icons 3:1, in
   light and dark, for every scheme. White on sky is the one accepted exception. Write the measured
   ratios into the commit body.

## Task 4 - Verify

- `fvm flutter analyze` clean, `fvm dart format` applied, the full app suite with `--concurrency=5
  --timeout 60s` (Drift `.watch()` providers hang `pumpAndSettle` unless overridden with `Stream.value`),
  plus the `packages/data` tests, `fvm flutter build web`, and `fvm flutter build apk --debug
  --dart-define-from-file=dart_define.local.json`.
- Emulator (`emulator-5554`, AVD `Medium_Phone_API_36.0`). The installed app has a higher version code,
  so install with `adb -s emulator-5554 install -r -d <apk>`. Drive it with the `android-drive` skill.
  Capture Home, Search, the song page, Settings and Chords for each of the 4 schemes, light and dark,
  plus a swipe recorded with `record-motion` showing the dot following the finger.
- Show Joe through `/preview`'s manifest gallery. In the inline `show_preview` iframe, use the
  `check OK:` URL that `build_gallery.py --check` prints, NOT the `render-url:` line (that one returns 404;
  see `~/.claude` todo 1246).

## Task 5 - Commit

One commit per task (nav bar, swipe, schemes), each with its tests, via `/commit` by pathspec with
`--expect-branch ut-client`. Do not push.

## Execution notes

- Joe's taste rules UI: show emulator screenshots, take short directional feedback, make minimal
  changes. No multiple-choice questions for pixel tweaks.
- Suggested split for subagents (sonnet, per the global preamble): Task 1+2 together (they share the
  PageController), Task 3.3 (data layer) on its own, then 3.1/3.2/3.4. The orchestrator owns
  screenshots and Joe's feedback loop.
