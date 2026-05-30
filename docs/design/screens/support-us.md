# Support Us

**Source:** DesignImages/Support Us.png

## Purpose
A support/donation screen inviting the user to back the app, reachable from the app (likely Settings). Offers two ways to help: watching an ad or contributing directly. A successful action leads to the Thank You screen (ty-screen.md).

## Layout
Top to bottom:
- Status bar (time "9:41" left; signal, wifi, battery right).
- App bar: circular orange-outlined back button (left chevron) and bold orange "SUPPORT US" title.
- Thin divider under the app bar.
- Body copy paragraph in black text: "If you find our app useful and would love to support us you can do so here! Thank you! With love, Joe."
- A large circular pale-peach badge centered below the text containing the orange mascot character holding/playing a stringed instrument (ukulele/guitar), with one arm raised.
- Empty space, then two stacked full-width rounded buttons near the bottom:
  - "WATCH AD" button: pale peach fill, white bold caps text.
  - "SUPPORT US DIRECTLY" button: solid orange fill, white bold caps text.
- No bottom navigation bar.

## Components
- Circular back button (orange outline, chevron).
- "SUPPORT US" bold orange title.
- Intro/appreciation paragraph signed "With love, Joe."
- Circular peach badge with the orange mascot playing an instrument.
- "WATCH AD" button (peach, white text), the lower-emphasis option.
- "SUPPORT US DIRECTLY" button (solid orange, white text), the primary option.

## Interactions / behavior
- Tapping the back button returns to the previous screen.
- Tapping "WATCH AD" plays a rewarded ad as a no-cost way to support; on completion likely shows the Thank You screen.
- Tapping "SUPPORT US DIRECTLY" starts the direct contribution / in-app purchase flow; on success navigates to the Thank You screen (ty-screen.md).

## Data shown
- Static: the appreciation copy, mascot illustration, and button labels. No dynamic per-user data visible.

## Notes for implementation
- Orange brand theme on white background; primary action (SUPPORT US DIRECTLY) is solid orange, secondary (WATCH AD) is muted peach to de-emphasize.
- Buttons are full-width, rounded, stacked with the primary on the bottom.
- Mascot-with-instrument is a shared brand asset (related characters appear on settings-1.md and ty-screen.md). Use the asset, not inline SVG.
- Ambiguity to flag: confirm whether both buttons lead to the same Thank You screen, and whether direct support is an in-app purchase or external payment.
