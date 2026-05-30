# Tuner (in tune, note A, green)

**Source:** DesignImages/Tuner-2.png

## Purpose
A variant of the Tuner screen showing the in-tune confirmation state on note A:
the played string has reached its target pitch, so the bottom triangle pointer is
green. This is the success end-state of the tuning flow whose listening frames are
tuner.md (note G) and tuner-1.md (note E).

## Layout
Top to bottom:
- Status bar: standard mobile system status bar (time left, signal / wifi /
  battery right).
- App bar: title "TUNER" in all-caps orange, with a circular back chevron button
  at the top-left.
- Centerpiece: the large orange ukulele mascot inside a peach circle, filling the
  vertical middle.
- String chips row: a horizontal row of circular orange string buttons labeled
  G C E A (ukulele tuning).
- Bottom: a horizontal note strip with note labels spread left to right, the
  current note A emphasized and aligned under the center pointers. Two center
  triangle pointers: orange top, and a green bottom pointer signaling in tune.

## Components
- Circular back chevron button (app bar, top-left).
- "TUNER" title text (app bar, orange, all-caps).
- Orange ukulele mascot in a peach circle (centerpiece / brand asset).
- Circular string chips: G, C, E, A.
- Horizontal note strip with the current note (A) centered.
- Top triangle pointer (orange) marking the target center.
- Bottom triangle pointer (green in this frame) confirming in tune.

## Interactions / behavior
- Back chevron pops the screen.
- When the live pitch lands within the in-tune tolerance, the bottom pointer turns
  green and the detected note (A) sits centered under the pointers.
- The microphone keeps listening, so if the string drifts the bottom pointer falls
  back to orange (the listening state in tuner.md / tuner-1.md).
- Tapping the next string chip moves the target on to continue tuning.

## Data shown
- Static: the mascot, the string chips (G C E A), the title, the strip scale.
- Dynamic: detected note (A here, centered), the green in-tune pointer state, and
  which string is currently confirmed.

## Notes for implementation
- This is the success frame: the bottom triangle pointer is green; everything else
  matches the listening frames. There is no circular dial.
- Keep the strip, pointers, chips, and mascot identical to tuner.md / tuner-1.md
  so the in-tune state is purely the bottom-pointer color plus note centering.
- Consider a brief positive cue (subtle pulse or optional haptic) on entering the
  green state, with hysteresis on the tolerance band so it does not flicker at the
  boundary.
- Ambiguity worth flagging: confirm the exact green hue and tolerance, and whether
  the app auto-advances to the next string after confirmation or waits for a tap.
