# Tuner (listening, note E, not yet in tune)

**Source:** DesignImages/Tuner-1.png

## Purpose
A variant of the Tuner screen showing active listening on note E where the string
is not yet in tune (the bottom pointer is still orange). It is one of the
listening frames alongside tuner.md (note G) and the in-tune frame tuner-2.md
(note A, green).

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
  current note E emphasized, and two center triangle pointers (orange top, orange
  bottom in this frame).

## Components
- Circular back chevron button (app bar, top-left).
- "TUNER" title text (app bar, orange, all-caps).
- Orange ukulele mascot in a peach circle (centerpiece / brand asset).
- Circular string chips: G, C, E, A.
- Horizontal note strip with multiple note labels and a highlighted current note
  (E).
- Top triangle pointer (orange) marking the target center.
- Bottom triangle pointer (orange in this frame) indicating not-yet-in-tune.

## Interactions / behavior
- Back chevron pops the screen.
- The microphone listens live; the strip and emphasized note (E) update as pitch
  is detected.
- Tapping a string chip re-targets detection to that string.
- As the user tunes the peg, the detected note slides toward the center pointers;
  when it lands in tolerance the bottom pointer turns green (see tuner-2.md).

## Data shown
- Static: the mascot, the string chips (G C E A), the title, the strip scale.
- Dynamic: detected note (E here), its offset from center on the strip, the active
  string, and the bottom pointer color (orange = off in this frame).

## Notes for implementation
- Same structure as tuner.md; only the detected note (E) and strip position
  differ. Bottom pointer is orange (not in tune).
- No circular dial: feedback is the horizontal strip plus the two center
  triangles.
- Reuse the identical strip, pointer, chip, and mascot components across all three
  tuner frames so state is a pure data/color toggle.
- Ambiguity worth flagging: confirm the cents threshold that flips the bottom
  pointer from orange to green, and whether any helper text accompanies the strip.
