# Desktop / wide-screen layout language (first cut)

Status: PROPOSED first cut (2026-06-14, autopilot). This is a starting point for Joe
to refine, not a final design. The app is built mobile-first against the 390x844
mockups in `DesignImages/`; this doc defines how the same screens should behave as the
viewport grows, without changing the phone layout.

## Principles

1. Mobile is the source of truth. At the design width (390x844) every screen must look
   exactly as it does today. Wide-screen behavior is additive and gated behind
   breakpoints, never a rewrite of the narrow layout.
2. Reflow, don't fork. Prefer the same widgets reflowing (column count, max width) over
   separate mobile/desktop widget trees.
3. Reading flows stay narrow. Text- and form-heavy screens (reading a chord sheet,
   tweaking settings) read best in a single centered column. Extra width becomes margin,
   not longer line lengths.
4. Griddy content uses the width. Inherently griddy content (the chord library, search
   results, saved tabs) should add columns as the viewport grows instead of leaving a
   stretched single column.

## Breakpoints

Defined in `apps/app/lib/theme/app_breakpoints.dart`:

- `kBreakpointMedium = 600` - phone -> large phone / small tablet. Below this the layout
  is the untouched mobile layout.
- `kBreakpointExpanded = 1024` - tablet -> desktop.
- `kReadingMaxWidth = 600` - max width for single-column reading / form screens.
- `kPageMaxWidth = 1100` - outer cap for griddy screens, so ultra-wide windows do not
  stretch content edge to edge.

Helper: `gridColumnsForWidth(width, minTileWidth)` returns how many columns of at least
`minTileWidth` fit, clamped to >= 1. Screens use it so column count scales with the
available width rather than hardcoding "2 columns on desktop".

## Per-screen treatment

| Screen | Class | First-cut treatment |
| --- | --- | --- |
| Home dashboard | reading | Centered column (unchanged). Desktop multi-pane deferred to Joe. |
| Song detail / chord sheet | reading | Centered column (unchanged). Side-by-side lyrics/diagrams deferred. |
| Settings | form | Centered column (unchanged). |
| Tuner | presentation | Centered column (unchanged); presentation-first. |
| Chords - Pick picker | reading | Centered column (unchanged). |
| Chords - Browse-all library | griddy | Per-root horizontal carousel below `kBreakpointMedium`; wrapping grid of diagrams above it. |
| Search results | griddy | Single-column separated list below `kBreakpointMedium`; grid of song tiles above it. |
| Saved tabs | griddy | Single-column separated list below `kBreakpointMedium`; grid of song tiles above it. |

The griddy screens are allowed up to `kPageMaxWidth`; reading screens stay capped at
`kReadingMaxWidth`. The app shell centers content and applies the per-route cap.

## Implementation rule (no mobile regression)

Each griddy screen keeps BOTH layouts and switches on measured width via `LayoutBuilder`:

```
if (constraints.maxWidth < kBreakpointMedium) {
  return <the existing mobile widget, untouched>;
}
return <the new grid layout>;
```

Because the compact branch is the existing widget verbatim, the 390x844 render is
byte-identical. The grid branch only ever runs above 600px, which mobile never reaches.

## Deferred (needs Joe)

- Persistent left nav rail vs the current hamburger drawer on wide screens.
- Multi-pane reading layouts (Home dashboard, Song detail lyrics + diagrams).
- The exact `kReadingMaxWidth` / `kPageMaxWidth` values (placeholders here).
- Per-screen visual polish at desktop sizes (taste domain).
