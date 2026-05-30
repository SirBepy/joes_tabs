# Splash Screen

**Source:** DesignImages/Splash Screen.png

## Purpose
First screen shown while the app launches. Establishes the "Joe's Tabs" brand and mascot before routing into the app.

## Layout
- No status bar visible in this mock (full bleed background).
- Top region: the app wordmark "JOE'S TABS" on two stacked lines, centered horizontally in the upper third.
- Center/lower region: a large mascot illustration, an orange rounded blob character with two oval eyes, holding and strumming a ukulele, standing on two short legs. The mascot fills the middle and lower portion of the screen.
- No app bar, no buttons, no navigation bar.

## Components
- Wordmark text "JOE'S TABS": chunky rounded bubble lettering, orange fill with a thick white outline, set on two lines ("JOE'S" then "TABS").
- Mascot illustration: orange character holding a ukulele/guitar, with subtle shadow shading on the body and instrument.
- Solid peach/cream background fill spanning the full screen.

## Interactions / behavior
- No interactive elements. Screen is passive.
- Auto-advances after a short delay (or once startup checks finish) to the next screen in the flow.

## Data shown
- Static branding only: wordmark and mascot. No dynamic data.

## Notes for implementation
- Color palette: peach/cream background, orange (#F5A623-ish warm orange) for the mascot and lettering, white outline around the bubble text.
- Bubble/sticker-style display font with thick white stroke is the core brand typography; reuse it for headings elsewhere.
- Wordmark centered in the upper area; mascot centered below, occupying roughly the lower two thirds.
- Ambiguity: exact splash duration and whether the transition is timer-based or tied to init is not visible and should be defined in code.
