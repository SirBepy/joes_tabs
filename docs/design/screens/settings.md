# Settings

**Source:** DesignImages/Settings.png

## Purpose
Main Settings screen for the ukulele/guitar tabs app. Lets the user adjust font display, toggle dark mode, manage their tags, and log out. This is the default/collapsed state of the screen; settings-1.md (log out confirmation) and settings-2.md (font settings expanded) are other states of the same screen.

## Layout
Top to bottom:
- Status bar at top (time "9:41" left; signal, wifi, battery right).
- App bar: circular orange-outlined back button with left chevron on the left, and the title "SETTINGS" in bold orange caps.
- Thin horizontal divider under the app bar.
- Body: a vertical list of rows on a white background, each separated by a full-width light grey divider:
  - "FONT SETTINGS" with a right-pointing orange triangle (collapsed/expand affordance) on the right.
  - "DARK MODE" with an orange toggle switch (off / handle on left) on the right.
  - "MY TAGS" with no trailing control.
- Large empty white space in the middle/lower body.
- Near the bottom, separated by a faint orange divider: "LOG OUT" with a right-pointing orange triangle on the right.
- No bottom navigation bar.

## Components
- Circular back button (orange outline, orange left chevron).
- "SETTINGS" title, bold orange uppercase.
- "FONT SETTINGS" row label (black caps) with orange right-triangle expander.
- "DARK MODE" row label (black caps) with orange/peach toggle switch, currently off.
- "MY TAGS" row label (black caps), no trailing control.
- "LOG OUT" row label (black caps) with orange right-triangle.
- Light grey row dividers; a faint orange divider above the LOG OUT row.

## Interactions / behavior
- Tapping the back button returns to the previous screen.
- Tapping "FONT SETTINGS" expands the font controls (triangle rotates to point down; see settings-2.md for the expanded state).
- Toggling "DARK MODE" switches the app theme between light and dark and persists the choice.
- Tapping "MY TAGS" opens the user's tags management screen.
- Tapping "LOG OUT" opens a log out confirmation dialog (see settings-1.md).

## Data shown
- Static row labels: FONT SETTINGS, DARK MODE, MY TAGS, LOG OUT.
- Dynamic: DARK MODE toggle state (shown off here).

## Notes for implementation
- Brand color is orange (#F7941D-ish / amber). Title, chevron, triangles, and toggle accent all use this orange. Toggle off-track is a pale peach tint.
- White background, black uppercase row labels, light grey dividers.
- Row triangles point right when collapsed/navigable; the FONT SETTINGS triangle becomes a down triangle when expanded (see settings-2.md).
- Back button is a circular outlined chevron, not a bare icon. Use Phosphor caret-left inside an orange-outlined circle.
- LOG OUT is visually separated and pinned toward the bottom rather than sitting in the main list.
