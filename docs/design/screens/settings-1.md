# Settings - Log Out Confirmation

**Source:** DesignImages/Settings-1.png

## Purpose
The log out confirmation state of the Settings screen. Triggered by tapping "LOG OUT" on the base Settings screen (settings.md). A modal dialog asks the user to confirm or cancel logging out. This is a variant/state of the Settings screen.

## Layout
- Full-screen dimmed grey overlay covering the Settings screen behind it.
- Centered modal card with rounded corners on a light peach/cream background.
- Inside the card, top to bottom:
  - A round orange mascot face (orange circle with two black oval eyes, no mouth) centered in the upper portion, with a soft drop shadow.
  - A white speech bubble to the upper right of the mascot reading "Are you sure you want to log out?" in black text, with a tail pointing toward the mascot.
  - Two stacked full-width buttons in the lower portion of the card:
    - "LOG OUT" button: white fill, black bold caps text.
    - "NOPE!" button: solid orange fill, white bold caps text.

## Components
- Dimmed background scrim (semi-transparent grey).
- Rounded peach modal card.
- Orange mascot face with two black eyes and drop shadow.
- White speech bubble with tail: "Are you sure you want to log out?".
- "LOG OUT" confirm button (white, black text).
- "NOPE!" cancel button (orange, white text).

## Interactions / behavior
- Tapping "LOG OUT" confirms and logs the user out, then routes to the logged-out/login screen.
- Tapping "NOPE!" cancels and dismisses the dialog, returning to the Settings screen.
- Tapping outside the card (the scrim) likely also dismisses the dialog (to confirm).

## Data shown
- Entirely static: confirmation copy, mascot, and button labels. No dynamic data.

## Notes for implementation
- Modal over a dimmed scrim; do not navigate away from Settings, present as a dialog.
- Card background is pale peach; the cancel button uses the brand orange while the confirm (destructive) button is plain white, an inverted emphasis where the safe choice is the bright accent.
- Because LOG OUT is destructive, keep the confirmation explicit; the playful "NOPE!" is the cancel path.
- Mascot is a reusable orange-circle character used across the brand (also appears on support-us.md and ty-screen.md). Use the shared asset, not an inline SVG.
- Cross-reference: settings.md (base) is the screen behind this modal.
