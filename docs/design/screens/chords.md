# Chords

**Source:** DesignImages/Chords.png

## Purpose
The chord reference / diagram screen. Displays fretboard diagrams grouped by root note, with several variants (maj, min, 7, etc.) per note, so the user can look up how to form any chord. Supports the play-along Tabs Screen.

## Layout
Top to bottom:
- Status bar: standard mobile status bar (time "9:41" left; signal, wifi, battery right) on the orange header.
- App bar (orange band): hamburger menu icon on the left and a rounded search bar with magnifier on the right.
- Screen title: bold orange "CHORDS", with a thin horizontal divider beneath it.
- Body: a vertical stack of root-note sections. Each section has:
  - A large orange root-note label on the left ("C", "D", "E", ...).
  - A round orange circle button with a downward chevron on the far right of that section's header row (expand/collapse or "more variants" control).
  - A horizontally scrolling row of chord diagram cards for that root, one card per variant. Each card is labeled at the top ("maj", "min", "7", ...) and the row runs off the right edge, indicating more variants are scrollable.

## Components
- Hamburger menu icon (top left).
- Search bar with magnifier icon (top right).
- Screen title "CHORDS" with divider.
- Per root-note section header: large orange root letter (C/D/E...) and a round orange dropdown-chevron button.
- Chord diagram cards (tan/peach, rounded), each containing:
  - Variant label at top ("maj", "min", "7", ...).
  - A 4-string fretboard grid (vertical = strings, horizontal = frets).
  - Orange finger-position dots on the grid.
  - A thick orange bar on some cards (e.g. D "7") representing a barre across strings.
  - Dots above the top of the grid on some cards indicating open/fingered strings near the nut.

## Interactions / behavior
- Tapping the hamburger opens the main navigation menu.
- Tapping the search bar searches chords/songs.
- Scrolling a variant row horizontally reveals more chord variants for that root note.
- Scrolling the body vertically moves between root-note sections (C, D, E, ...).
- Tapping the round chevron button expands/collapses that root's section or reveals all its variants.
- Tapping a chord card likely opens a larger detail view of that chord.

## Data shown
- Dynamic: the set of root notes, the variants available per root, and each chord's finger-position dots, barres, and fret placement.
- Static: the grid scaffolding, the card and section layout, and the header.

## Notes for implementation
- Grids are 4-string, so this is a ukulele chord library. Render all diagrams with the same 4-string component.
- Standard diagram convention: vertical lines = strings, horizontal lines = frets, orange dots = pressed positions, thick orange bar = barre. Confirm whether open ("o") and muted ("x") string markers are intended; the mockup shows small dots near the nut but no explicit x marks.
- Layout is a vertical list of sections, each containing a horizontal carousel of variant cards. The chevron button per row implies a collapsible/expandable section; confirm exact behavior.
- Palette: orange header/labels/dots, tan/peach cards, white body. Variant labels sit at the top of each card in orange.
- Ambiguity: what the chevron expands (all variants vs collapse) and what tapping a card does are not shown; confirm before building.
