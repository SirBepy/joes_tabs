# Plan 07 - App shell (theme, routing, nav, entry screens)

Read the spec (sections 2, 6) and `docs/design/screens/` (from plan 02). Depends
on: 01, 05. **Functional wireframe only - no visual polish.**

## Objective
The navigational skeleton: theming foundation, routes, bottom-nav shell, and the
entry screens (Splash, Welcome, Sign-Up, Log-In).

## Tasks
1. Add deps (after safety check): `go_router`, `phosphor_flutter`,
   `flutter_riverpod` (wire `ProviderScope` in `main`).
2. Theme foundation: a `lib/theme/` with light + dark `ThemeData`, basic color
   scheme + text theme + spacing tokens. Plain/neutral - polish comes later. No
   hardcoded colors in widgets; reference the theme.
3. `go_router` config with routes for every screen in spec section 6. Bottom-nav
   shell (StatefulShellRoute) matching the Navbar mockup tabs (e.g. Trending,
   Saved, Tuner, Settings - confirm against `docs/design/screens/navbar.md`).
4. Build these screens as functional wireframes (real widgets, placeholder data
   where downstream plans fill in): **Splash** (brief, routes onward),
   **Welcome**, **Sign-Up**, **Log-In** (forms wired to Supabase auth optionally;
   if auth deferred, stub the buttons with clear TODOs and route through).
5. Phosphor icons for all iconography (global rule).

## Acceptance
- `flutter build web` succeeds; app launches to Splash -> Welcome -> nav shell.
- Navigating between bottom-nav tabs works.
- `dart analyze` clean; basic widget test that the shell renders + tabs switch.

## Notes
Stage; do not commit. No em dashes. Wireframe fidelity, not pixel-perfect.
