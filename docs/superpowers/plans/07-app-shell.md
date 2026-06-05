# Plan 07 - App shell (theme, routing, nav, entry screens)

Read the spec (sections 2, 6) and `docs/design/screens/` (from plan 02). Depends
on: 01, 05. **Functional wireframe only - no visual polish.**

## Objective
The navigational skeleton: theming foundation, routes, a drawer-based shell, and
the entry screens (Splash, Home, Sign-Up, Log-In).

> **Navigation correction (per the design mockups).** This plan originally
> specified a bottom-tab `StatefulShellRoute`. That is WRONG per
> `docs/design/screens/navbar.md`: navigation is a FULL-SCREEN SLIDE-OUT DRAWER
> opened from a hamburger in the top app bar, not a bottom bar. The drawer
> destinations, in order, are: Home, Trending, Saved Tabs, Chords, Tuner,
> Settings; then a divider; then a "Support Us" call to action; the mascot; and
> "Log In | Register" account links at the bottom. Also note the "Welcome"
> screen (`welcome.md`) is actually the logged-in HOME / dashboard (greeting +
> saved-tabs row + trending list), NOT an auth landing page.

## Tasks
1. Add deps (after safety check): `go_router`, `phosphor_flutter`,
   `flutter_riverpod` (wire `ProviderScope` in `main`).
2. Theme foundation: a `lib/theme/` with light + dark `ThemeData`, basic color
   scheme + text theme + spacing tokens. Plain/neutral - polish comes later. No
   hardcoded colors in widgets; reference the theme.
3. `go_router` config with routes for every screen in spec section 6. A
   `ShellRoute` wraps the main destinations (Home, Trending, Saved, Chords,
   Tuner, Settings, Support) in a shared `AppShell` providing the top app bar
   (hamburger + search field) and the full-screen `AppDrawer`. Splash, Log In,
   Register, and the song detail route (`/song/:id`) sit OUTSIDE the shell.
4. Build these screens as functional wireframes (real widgets, placeholder data
   where downstream plans fill in): **Splash** (brief, auto-routes to Home),
   **Home** (the welcome/dashboard: greeting + saved-tabs + trending
   placeholders), **Sign-Up**, **Log-In** (forms stubbed with clear TODOs;
   Supabase auth is deferred since accounts are optional in v1), plus
   placeholders for Trending, Saved, Chords, Tuner, Settings, Support, and Song
   detail. Plan 08 fills these with real content.
5. Phosphor icons for all iconography (global rule).

## Acceptance
- `flutter build web` succeeds; app launches to Splash -> Home (inside the nav
  shell).
- Opening the drawer and tapping a destination navigates between screens.
- `dart analyze` clean; widget test that the shell renders, the drawer lists
  every destination, and tapping a destination navigates + closes the drawer.

## Notes
Stage; do not commit. No em dashes. Wireframe fidelity, not pixel-perfect.
