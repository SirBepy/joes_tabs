# Welcome

**Source:** DesignImages/Welcome.png

## Purpose
Logged-in home / dashboard screen shown after the user signs in. Greets the user by name and surfaces their saved tabs and trending tabs as the main browsing hub. (Despite the filename, this is the home screen, not an auth landing page.)

## Layout
- Status bar: standard mobile status bar at the top (time "9:41" on the left; signal, wifi, battery on the right) over the orange header band.
- App bar / header: a solid orange band containing a hamburger menu icon on the left and a rounded search field filling the rest of the width (with a magnifier icon on the right).
- Body (white background, scrollable), top to bottom:
  - Centered heading "WELCOME BACK" with a lighter subheading "PLACEHOLDER NAME!" beneath it.
  - A large circular avatar showing the orange ukulele mascot, centered.
  - "SAVED TABS" section: a row of horizontally scrollable cards. A second column header "ALL SAVED TABS >" with a chevron sits to the right, and a partial third card peeks off the right edge.
  - "TRENDING" section: a rounded panel containing a vertical list of trending tab entries, each with a title and an artist/subtitle, separated by divider lines.

## Components
- Hamburger menu icon (top left).
- Search field with placeholder and magnifier icon (top, in the orange header).
- "WELCOME BACK" heading (orange bubble-style text).
- "PLACEHOLDER NAME!" subheading (muted/light orange).
- Circular mascot avatar.
- "SAVED TABS" section label.
- "ALL SAVED TABS >" link with chevron (section navigation).
- Saved-tab cards, each showing a song title (e.g. "Lost Boy", "Creep"), an artist (e.g. "Ruth B.", "Radiohead"), and a row of three small colored circle dots/chips at the bottom of the card.
- "TRENDING" section label.
- Trending list rows, each with a song title (e.g. "idontwannabeyouanymore", "Adventure Time Theme") and artist/category subtitle (e.g. "Billie Eilish", "Misc Cartoons"), divided by horizontal rules.

## Interactions / behavior
- Tapping the hamburger icon opens the app navigation drawer/menu.
- Tapping the search field focuses it and lets the user search tabs.
- Tapping a saved-tab card opens that tab.
- Tapping "ALL SAVED TABS >" navigates to the full saved-tabs list.
- The saved-tabs row scrolls horizontally; the page scrolls vertically to reach the trending list.
- Tapping a trending row opens that tab.

## Data shown
- Dynamic: the user's name (shown as "PLACEHOLDER NAME!"), the list of saved tabs (titles, artists, the colored chips), and the trending list (titles, artists/categories). The avatar mascot, section labels, and the "WELCOME BACK" heading are static.

## Notes for implementation
- Color palette: orange header band, white body, orange accent text for headings; saved-tab cards use a soft peach fill; the trending panel is a light peach rounded container.
- The three small circles on each saved-tab card appear to be color tags/markers (orange and a darker rust tone); their meaning (chord colors, difficulty, etc.) is not labeled and should be confirmed.
- Typography: bubble-style display font for the "WELCOME BACK" heading; standard sans-serif for list items.
- "PLACEHOLDER NAME!" is literal placeholder copy to be replaced by the real user's name at runtime.
- Ambiguity: exact behavior of the colored chips and whether the search lives in a persistent app bar across screens should be confirmed.
