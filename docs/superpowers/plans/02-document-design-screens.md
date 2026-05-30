# Plan 02 - Document the design screens

Read the spec (section 6). This is a **documentation-only** plan - no app code.

## Objective
Turn the mockups in `DesignImages/*.png` into written screen specs so later UI
polish work is faithful to Joe + his sister's original design.

## Approach
Dispatch parallel subagents (one per image, or batched) to **view** each PNG and
write a markdown file. Each subagent must actually read the image with the Read
tool (images are supported) and describe what it literally sees.

For each `DesignImages/<Name>.png` produce `docs/design/screens/<kebab-name>.md`:

```
# <Screen name>

**Source:** DesignImages/<Name>.png

## Purpose
<what this screen is for in the app flow>

## Layout
<top-to-bottom description of regions: app bar, body, nav, etc.>

## Components
- <each visible element: buttons, lists, cards, inputs, icons, art>

## Interactions / behavior
- <what tapping/scrolling each element should do>

## Data shown
- <what dynamic data appears: song titles, chords, etc.>

## Notes for implementation
- <colors, spacing, anything notable; flag ambiguities>
```

## Tasks
1. Glob `DesignImages/*.png` (18 images: Chords, Log-In Page, Navbar, Saved Tabs,
   Settings/-1/-2, Sign-Up Page, Splash Screen, Support Us, Tabs Screen,
   Trending 2/5, Tuner/-1/-2, TY Screen, Welcome).
2. One screen doc each. Settings-1/-2 and Tuner-1/-2 are variants - document each
   variant and note how they relate in the base screen's doc.
3. Write `docs/design/screens/README.md` indexing all screens + a one-line summary
   each, plus the inferred navigation flow (Splash -> Welcome -> auth -> nav shell).

## Acceptance
- One `.md` per image, all populated (no TBD/empty sections).
- Index README lists every screen and a plausible nav flow.

## Notes
Stage; do not commit. Pure docs, no dependencies on other plans. No em dashes.
