# Saved Tabs

**Source:** DesignImages/Saved Tabs.png

## Purpose
The user's library of saved songs. Lists each saved song as a card so the user can reopen its play-along Tabs Screen. Likely the home / landing surface.

## Layout
Top to bottom:
- Status bar: standard mobile status bar (time "9:41" left; signal, wifi, battery right) on the orange header.
- App bar (orange band): hamburger menu icon on the left and a rounded search bar with magnifier on the right.
- Screen title: bold orange "SAVED TABS".
- Body: a vertical scrolling list of large rounded tan/peach song cards, evenly spaced. The last card is partially cut off at the bottom edge, showing the list continues. No bottom navigation bar is visible.

## Components
- Hamburger menu icon (top left).
- Search bar with magnifier icon (top right).
- Screen title "SAVED TABS" (bold orange).
- Song cards (tan/peach, rounded), each containing:
  - Song title in white/cream bold text.
  - Artist name in orange beneath the title.
  - A row of small colored circle swatches at the bottom of the card, in shades of orange, red, and brown, one per chord used in the song (count varies by song).
- Visible cards: "Running Up That Hill" / Kate Bush (2 swatches), "Don't Stop Believin'" / Dire Straits (2 swatches), "Big In Japan" / Alphaville (1 swatch), "More Than A Feeling" / Boston (3 swatches), "Don't Stop Me Now" / Queen (4 swatches).

## Interactions / behavior
- Tapping the hamburger opens the main navigation menu.
- Tapping the search bar searches the library.
- Tapping a song card opens that song in the Tabs Screen play-along view.
- Scrolling the body moves through the full list of saved songs.
- The chord swatch dots are likely an at-a-glance preview of the chords in the song (decorative/informational, not necessarily tappable).

## Data shown
- Dynamic: the list of saved songs, each song's title and artist, and the per-song row of chord swatch colors and their count.
- Static: the header, the screen title, and the card layout structure.

## Notes for implementation
- Palette: orange header and title, tan/peach cards, white/cream song titles, orange artist names, multicolor (orange/red/brown) chord swatch dots.
- Cards are large with generous vertical spacing and rounded corners; title sits top-left, artist directly under it, swatch row at the bottom-left.
- The swatch dots vary in count per card (1 to 4 visible) and appear to map to the song's chords; confirm the color-to-chord mapping rule before building.
- No bottom nav bar is present, so navigation between sections is via the hamburger menu, not tabs.
- An empty state (no saved songs) is not shown but will be needed.
