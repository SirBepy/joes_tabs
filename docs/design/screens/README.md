# Design Screens

Written descriptions of every mockup in `DesignImages/`, produced for plan 02 so
later UI polish stays faithful to the original design by Joe and his sister. Each
file describes what is actually visible in one PNG. UI polish is a later pass; the
overnight run builds functional wireframes only.

## Brand language (consistent across screens)
- Palette: peach / cream backgrounds, saturated orange accents, occasional white.
- Typography: white-outlined "bubble" display font for headings.
- Mascot: an orange blob character holding a ukulele, reused as a shared brand
  asset (home avatar, tuner centerpiece, support, thank-you, drawer).
- Icons: use Phosphor for glyphs (hamburger, search, close, chevrons, bookmark).

## Screens

| Doc | Screen | One-line summary |
|---|---|---|
| splash-screen.md | Splash | Branded launch screen shown briefly on app start. |
| welcome.md | Home / Dashboard | Logged-in home (despite the filename): greeting, saved-tabs row, trending list. |
| sign-up-page.md | Sign Up | Email + password + repeat-password fields, orange submit. |
| log-in-page.md | Log In | Mascot, email + password fields, submit, forgot-password link. |
| navbar.md | Nav Drawer | Full-screen slide-out menu (NOT a bottom bar): Home, Trending, Saved Tabs, Chords, Tuner, Settings, Support Us, Log In / Register. |
| trending-2.md | Trending / Home | Vertical song list with search + filter; bookmark per row. Orange-title variant. |
| trending-5.md | Trending / Home | Same screen, dark-title variant (typography only). |
| tabs-screen.md | Song View | The play-along view: chord cards, sectioned chords-over-lyrics, controls behind a floating sliders FAB. |
| chords.md | Chords | Chord-diagram library grouped by root note, horizontal variant carousels (4-string uke grids). |
| saved-tabs.md | Saved Tabs | Cards of favorited songs with chord-color dot swatches. |
| tuner.md | Tuner | Listening on G, not in tune (note strip + mascot, bottom pointer orange). |
| tuner-1.md | Tuner | Listening on E, not in tune. |
| tuner-2.md | Tuner | In tune on A (bottom pointer green). |
| settings.md | Settings | Font settings, dark-mode toggle, my tags, log out. |
| settings-1.md | Settings | Log-out confirmation modal. |
| settings-2.md | Settings | Font settings expanded (size stepper, color, reset). |
| support-us.md | Support Us | Donation screen: Watch Ad and Support Us Directly, signed "With love, Joe." |
| ty-screen.md | Thank You | Full-bleed thank-you / confirmation with mascot. |

## Inferred navigation flow
- App launch: **Splash** -> first run goes to auth (**Welcome** marketing is not a
  screen here; auth is **Sign Up** / **Log In**), returning users go to **Home**.
- Accounts are optional in v1.1 (v1 is anonymous, favorites local-only per the
  spec), so the auth screens can be skippable / deferred entry points.
- **Home (welcome.md)** is the hub: search, a horizontal Saved Tabs row
  ("All Saved Tabs >" -> **Saved Tabs**), and a **Trending** list.
- The **Nav Drawer (navbar.md)** opens from the hamburger on the main screens and
  reaches every top-level destination: Home, Trending, Saved Tabs, Chords, Tuner,
  Settings, plus Support Us and Log In / Register.
- **Trending / Home list** and **Saved Tabs** -> tap a song -> **Song View
  (tabs-screen.md)**, which links to **Chords** for diagrams.
- **Tuner** is a standalone utility reached from the drawer.
- **Settings** holds font settings, dark mode, tags, and log out (with the
  confirmation modal). **Support Us** -> **Thank You** after a contribution.

## Known ambiguities to resolve during the polish pass
- The colored dot swatches on saved-tab cards (chord colors? difficulty?).
- "Welcome" filename vs its actual logged-in-home content.
- Song View transpose / autoscroll controls live behind the sliders FAB and are
  not fully depicted; their exact UI needs design follow-up.
- Support Us button destinations (in-app vs external) and the Thank You dismiss.
