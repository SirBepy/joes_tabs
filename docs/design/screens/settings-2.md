# Settings - Font Settings Expanded

**Source:** DesignImages/Settings-2.png

## Purpose
The Settings screen with the "FONT SETTINGS" group expanded. Reveals font size, font color, and reset controls. This is a state of the base Settings screen (settings.md); the difference is the expanded font section.

## Layout
Top to bottom:
- Status bar (time "9:41" left; signal, wifi, battery right).
- App bar: circular orange-outlined back button (left chevron) and bold orange "SETTINGS" title.
- Divider under app bar.
- "FONT SETTINGS" row with an orange down-pointing triangle on the right (expanded state, versus the right-pointing triangle in the collapsed base).
- An orange divider, then the expanded font controls block:
  - "Font size:" label with a value "20" on the right preceded by a small up/down stepper (orange double-arrow).
  - "Font color:" label with a black color swatch (black square with a thin orange/yellow border) on the right.
  - "Reset font settings" label with an empty checkbox (white square outline) on the right.
- Light grey divider, then "DARK MODE" row with the orange toggle (off, handle on left).
- Light grey divider, then "MY TAGS" row.
- Empty white space below.
- Faint orange divider near bottom, then "LOG OUT" row with right-pointing orange triangle.
- No bottom navigation bar.

## Components
- Circular back button (orange outline, chevron).
- "SETTINGS" bold orange title.
- "FONT SETTINGS" row with orange down-triangle (expanded).
- "Font size:" label + up/down stepper arrows + numeric value "20".
- "Font color:" label + black color swatch.
- "Reset font settings" label + empty checkbox.
- "DARK MODE" row + orange toggle (off).
- "MY TAGS" row.
- "LOG OUT" row + orange right-triangle.
- Grey dividers between groups; orange dividers bracketing the font section and above LOG OUT.

## Interactions / behavior
- Tapping the back button returns to the previous screen.
- Tapping "FONT SETTINGS" collapses the section back (triangle returns to pointing right; see settings.md).
- Using the up/down stepper on "Font size:" increases/decreases the size value (currently 20).
- Tapping the "Font color:" swatch opens a color picker and updates the swatch.
- Tapping the "Reset font settings" checkbox triggers a reset of the font options to defaults.
- Toggling "DARK MODE" switches theme.
- Tapping "MY TAGS" opens tags management.
- Tapping "LOG OUT" opens the log out confirmation (settings-1.md).

## Data shown
- Static labels: FONT SETTINGS, Font size, Font color, Reset font settings, DARK MODE, MY TAGS, LOG OUT.
- Dynamic: font size value ("20"), the current font color swatch, the reset checkbox state (unchecked), and the dark mode toggle state (off).

## Notes for implementation
- Same orange brand theme and white background as base. The font sub-controls use sentence-case labels (e.g. "Font size:") in contrast to the uppercase top-level row labels.
- Font size uses a numeric stepper (up/down double-arrow) showing the current value; value "20" rendered in muted/grey.
- Font color swatch is currently black with a thin warm border, indicating selected color.
- Reset is a checkbox-style control rather than a button.
- Implement as the expanded state of the same Settings route, driven by an expand/collapse flag, not a separate screen.
- Cross-reference: settings.md (collapsed base), settings-1.md (log out confirmation).
