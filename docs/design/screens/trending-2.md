# Trending (Variant 2)

**Source:** DesignImages/Trending 2.png

## Purpose
The Trending screen: a scrollable list of currently popular ukulele/guitar tabs the user can browse, filter, save, and open. This is one of two color/typography variants of the same screen (see trending-5.md).

## Layout
Top to bottom:
- Status bar: time on the left, signal / wifi / battery on the right.
- App bar over an orange band: a hamburger menu icon on the left and a rounded search bar with a magnifying-glass icon on the right.
- Body on a white background.
- Section header row: large "TRENDING" heading on the left, a funnel / filter icon on the right.
- Vertical list of song rows, each separated by a thin divider, scrolling down past the bottom of the viewport.

## Components
- Status bar icons (time, signal, wifi, battery).
- Hamburger menu icon (top left) that opens the slide-out drawer.
- Rounded search bar with magnifying-glass icon (top right).
- "TRENDING" section heading in the accent orange.
- Funnel / filter icon (top right of the list area).
- Song rows, each with: song title (top line), artist name (second line), and a bookmark / ribbon icon on the right. The bookmark is filled orange when saved and an outline when not saved.

## Interactions / behavior
- Tapping the hamburger opens the navigation drawer (Navbar.png).
- Tapping the search bar opens / focuses tab search.
- Tapping the funnel icon opens filtering / sorting options for the list.
- Tapping a song row opens that song's tab detail.
- Tapping the bookmark icon toggles saved state (outline becomes filled orange, and vice versa), adding / removing the song from Saved Tabs.
- The list scrolls vertically.

## Data shown
- Dynamic: the song list rows, each with a title and artist, and a per-row saved/unsaved bookmark state. Visible entries: Lost Boy / Ruth B. (saved), Hold The Line / Toto, Random Song / John Doe, Another One / John Doe (saved), Sultans Of Swing / Dire Straits, Cecily Smith / Will Connolly (saved), The Muffin Song / Ruth B.
- Static: "TRENDING" heading, search placeholder, status bar, the hamburger and funnel icons.

## Notes for implementation
- Orange app-bar band over a white list body. Saved-state bookmark uses a filled warm orange; unsaved uses an orange outline.
- Each list row is two lines (title over artist) with a trailing bookmark icon and a full-width divider beneath.
- Use Phosphor Icons for the hamburger, magnifying glass, funnel (filter), and bookmark glyphs.
- Relationship to variant 5: same layout, same content, same saved/unsaved states. The only difference is row text color. In this variant, song TITLES are orange and artist names are gray. (In trending-5 the titles are dark and the artists are orange.) Pick one as the production style.
- Ambiguity: exact behavior of the funnel filter (categories, sort order) is not shown and should be confirmed.
