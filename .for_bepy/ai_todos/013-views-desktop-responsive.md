# Make the app's views desktop/wide-screen responsive

## STATUS (2026-06-14, autopilot): FIRST CUT SHIPPED (doc + grid reflows)
Layout language doc written: `docs/desktop-layout-language.md`. First responsive
pass shipped (commit 04a8526), building on the earlier max-width win (3637b2b):
- New breakpoints helper `apps/app/lib/theme/app_breakpoints.dart` (kBreakpointMedium=600,
  kBreakpointExpanded=1024, kReadingMaxWidth=600, kPageMaxWidth=1100, gridColumnsForWidth).
- App shell now applies a PER-ROUTE max width (reading routes 600, griddy routes 1100).
- Griddy GRIDS shipped with a dual-path (compact branch = the exact mobile widget, grid
  branch only >=600px, so 390x844 is byte-identical and proven by a test):
  Chords Browse-all library carousel -> wrapping grid; Saved tabs and Search results
  lists -> responsive grids. Song detail (non-shell) now caps at 600 centered.
Floor green: analyze clean, 293 tests pass, flutter build web OK.

REMAINING (deferred for a WITH-Joe brainstorm - taste/structural, not guessed):
- Persistent left nav RAIL vs the current hamburger drawer on wide screens.
- Multi-PANE reading layouts (Home dashboard, Song detail lyrics + diagrams side by side).
- Per-screen breakpoint tuning + the actual kReadingMaxWidth / kPageMaxWidth values
  (600 / 1100 are placeholder defaults).
- Desktop visual polish at wide sizes (taste domain - review the first cut and refine).

## Goal

The app is laid out mobile-first (designed against the 390x844 mockups). On
desktop / wide browser windows the screens stretch awkwardly. Make the main views
adapt to wide viewports (constrain content width, use multi-column / grid layouts
where it makes sense) so the hosted web build looks intentional on a desktop.

## Context

- Live web app: https://sirbepy.github.io/joes_tabs/ . It is a Flutter web build
  that currently renders the phone layout full-bleed on desktop.
- Everything is built around the 390x844 design (`DesignImages/`), so widths,
  paddings, and single-column lists assume a narrow viewport.
- High-traffic screens to address (in `apps/app/lib/screens/`): Home dashboard,
  Search, the Song detail / chord sheet view, the Chords screen (Pick picker +
  Browse-all library), the Tuner, Settings. The app shell / nav is
  `apps/app/lib/widgets/app_shell.dart` (drawer-based nav today).
- Deferred: this is a broad cross-cutting pass, best done deliberately after the
  current chord-picker feature work settles. It likely wants its own brainstorm
  (desktop layout language: max content width? persistent side nav vs drawer?
  grid for the chord library and saved tabs?).

## Approach

- Start with a short design pass (what does "desktop" look like for this app):
  a max content width (e.g. center a ~480-600px column on Home/Song/Settings),
  multi-column grids for inherently griddy content (the Browse-all chord library,
  Saved tabs, Search results), and decide whether wide screens get a persistent
  left nav rail instead of the hamburger drawer.
- Use `LayoutBuilder` / `MediaQuery` breakpoints (or a small responsive helper) so
  the same widgets reflow; avoid forking mobile vs desktop widget trees where a
  reflow suffices.
- The Chords Browse-all (`chord_library_view.dart`) is a natural early win: its
  per-root horizontal carousels could become a wrapping grid on wide screens.
- Keep mobile (390x844) pixel-faithful to the mockups - desktop adapts, mobile
  must NOT regress.

## Acceptance

- On a wide desktop browser, the main screens use the extra width sensibly
  (constrained columns and/or grids), not a stretched phone layout.
- Mobile at 390x844 is unchanged vs the current mockup-matched look.
- `flutter analyze` clean, all tests pass, `flutter build web` OK. Verify at a
  desktop width (e.g. 1280x800) AND at 390x844 with Playwright.
