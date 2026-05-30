# Thank You Screen

**Source:** DesignImages/TY Screen.png

## Purpose
A full-screen thank-you / welcome screen. The copy reads "THANK YOU FOR SIGNING UP!", so it celebrates the user joining (and likely doubles as the confirmation after a Support Us action). It acknowledges the user warmly with the brand mascot.

## Layout
Top to bottom, on a full-bleed pale peach/orange background:
- Large heading "THANK YOU" in bold orange caps with a thick white outline/sticker effect, centered near the top.
- Subheading "FOR SIGNING UP!" in white bold caps directly below.
- A white speech bubble with a tail, upper-right area, reading "Glad to have you here!" in black text.
- A large centered orange mascot: a round-headed character with two black oval eyes (no mouth), a body, arms, and legs, holding and strumming a ukulele/guitar.
- An elliptical light shadow/ground beneath the mascot's feet.
- No app bar, no status bar elements visible, no bottom navigation; full-screen celebratory layout.

## Components
- "THANK YOU" sticker-style heading (orange fill, white outline).
- "FOR SIGNING UP!" white subheading.
- White speech bubble with tail: "Glad to have you here!".
- Full-body orange mascot playing a stringed instrument.
- Soft elliptical floor shadow under the mascot.

## Interactions / behavior
- No explicit button is visible. This screen likely auto-dismisses after a delay, or advances on tap, into the main app.
- It serves as a terminal confirmation in the onboarding/support flow.

## Data shown
- Entirely static: headings, speech-bubble copy, and mascot illustration. No dynamic per-user data.

## Notes for implementation
- Full-bleed warm peach background (distinct from the white settings screens); orange and white typography.
- Heading uses a sticker/outlined treatment, bold orange with a heavy white stroke; subheading is plain white caps.
- Mascot is the shared brand character (same family as settings-1.md and support-us.md), here full-body with an instrument. Use the shared asset.
- Ambiguity to flag: no visible dismiss control, confirm whether it auto-advances on a timer or requires a tap, and whether this same screen is reused after the Support Us flow versus only at sign-up.
