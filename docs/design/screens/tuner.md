# Tuner (listening, note G, not yet in tune)

**Source:** DesignImages/Tuner.png

## Purpose
The Tuner screen lets the player tune their instrument by ear-assist: the app
listens through the microphone and shows the detected pitch against the target
string. This frame shows an active-listening state on note G where the string is
not yet in tune (the in-tune pointer is still orange, not green).

## Layout
Top to bottom:
- Status bar: standard mobile system status bar (time left, signal / wifi /
  battery right).
- App bar: title "TUNER" in all-caps orange, with a circular back chevron button
  at the top-left.
- Centerpiece: a large orange mascot (round head, holding a ukulele) inside a
  peach circle, filling the vertical middle of the screen. This is the visual
  focus, not a gauge or dial.
- String chips row: a horizontal row of circular orange string buttons labeled
  G C E A (ukulele tuning), sitting above the bottom note strip.
- Bottom: a horizontal note strip spanning the width, with note labels spread
  left to right and the current note (G) emphasized. Two triangle pointers mark
  the center target, one pointing down from the top of the strip and one pointing
  up from the bottom.

## Components
- Circular back chevron button (app bar, top-left).
- "TUNER" title text (app bar, orange, all-caps).
- Orange ukulele mascot in a peach circle (centerpiece / brand asset).
- Circular string chips: G, C, E, A.
- Horizontal note strip with multiple note labels and a highlighted current note.
- Top triangle pointer (orange) marking the target center.
- Bottom triangle pointer (orange in this frame) indicating not-yet-in-tune.

## Interactions / behavior
- Back chevron pops the screen.
- The microphone listens continuously while the screen is open; the strip and the
  emphasized note update in real time as pitch is detected.
- Tapping a string chip selects that string as the active tuning target; the
  detection compares the played pitch against that string's frequency.
- The note strip scrolls / shifts so the detected note aligns under the center
  triangle pointers; the bottom pointer changes color (orange to green) when the
  string lands in tune (see tuner-2.md).

## Data shown
- Static: the mascot, the string chip set (G C E A), the title, the strip scale.
- Dynamic: the currently detected note (G here), its position on the strip
  relative to the center target, which string chip is active, and the bottom
  pointer color (orange = off, green = in tune).

## Notes for implementation
- There is NO circular dial in this design. Tuning feedback is a horizontal note
  strip plus two center triangle pointers; build to that, not a needle gauge.
- Bottom pointer color is the load-bearing in-tune signal: orange = not in tune,
  green = in tune. This frame is orange (note G).
- String tuning shown is ukulele GCEA; guitar mode would need its own chip set
  (EADGBE), flag as future work.
- Brand palette: peach / cream background, orange accents, white-outlined bubble
  typography; reuse the shared orange mascot asset.
- Animate the strip shift and the pointer color change smoothly to avoid jitter
  as pitch fluctuates.
- Ambiguity worth flagging: confirm whether the active string is auto-selected
  from the detected note or must be tapped, and the cents tolerance for "in tune".
