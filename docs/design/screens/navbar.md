# Navbar (Slide-out Menu)

**Source:** DesignImages/Navbar.png

## Purpose
The app's main navigation drawer / menu overlay. Opened from the hamburger icon on the main screens, it gives the user access to every top-level destination of the ukulele/guitar tabs app, plus a support call-to-action and account entry points. It is a full-screen overlay, not a bottom bar.

## Layout
Top to bottom:
- Status bar: system time on the left, signal / wifi / battery on the right.
- Top row over an orange band: a white "X" close button on the left and a rounded search bar with a magnifying-glass icon on the right.
- Body on a lighter orange / peach background: a vertical stack of menu items, each as centered text with a thin divider line beneath it.
- Below the menu list: a "SUPPORT US!" accent label.
- A mascot illustration: a round orange-headed character holding a small guitar / ukulele and waving, inside a white circle.
- Bottom: "LOG IN | REGISTER" text links separated by a vertical bar.

## Components
- Status bar icons (time, signal, wifi, battery).
- White "X" close button (top left).
- Rounded search bar with placeholder area and magnifying-glass icon (top right).
- Menu items, top to bottom: HOME, TRENDING, SAVED TABS, CHORDS, TUNER, SETTINGS (white text, centered, divider under each).
- "SUPPORT US!" label in the warm accent color.
- Mascot illustration in a white circle (orange character with a small guitar / uke).
- "LOG IN" link and "REGISTER" link separated by a "|" pipe.

## Interactions / behavior
- Tapping the "X" closes the drawer and returns to the previous screen.
- Tapping the search bar opens / focuses search for tabs.
- Tapping a menu item navigates to that destination (Home, Trending, Saved Tabs, Chords, Tuner, Settings) and closes the drawer.
- Tapping "SUPPORT US!" opens the support / donate flow.
- Tapping "LOG IN" opens the login screen; tapping "REGISTER" opens sign-up.
- The mascot is decorative (no documented action).

## Data shown
- Static: all menu labels (HOME, TRENDING, SAVED TABS, CHORDS, TUNER, SETTINGS), "SUPPORT US!", "LOG IN | REGISTER", search placeholder, mascot art, status bar.
- No dynamic per-user data is shown (login state could later swap the LOG IN / REGISTER links, but the mockup shows the logged-out state).

## Notes for implementation
- Two-tone orange theme: a saturated orange top band, a lighter peach body. Menu text is white; "SUPPORT US!" and the LOG IN / REGISTER links use the warm accent orange.
- Menu items are centered, evenly spaced, each with a full-width thin divider underneath.
- Use Phosphor Icons for the X (close) and magnifying glass (search) glyphs.
- Mascot sits in a white circular frame near the bottom, above the account links.
- Ambiguity: the destination of "SUPPORT US!" (in-app donate vs external link) is not specified. Whether the menu list scrolls or is fixed is not shown; it fits on one screen as drawn.
