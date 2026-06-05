# 002 - Wire dark mode toggle to actual theming

## Context
Settings has a Dark Mode switch backed by a Riverpod StateProvider, but the app does
not yet re-theme when it flips. Only the state changes.

## What to do
- Add an AppTheme.dark (peach/orange brand adapted to a dark surface set).
- Read the dark-mode provider at the MaterialApp.router level and set themeMode.
- Verify the toggle actually switches the app theme live.

## Acceptance
- Toggling Dark Mode in Settings re-themes the whole app immediately.
- Light theme remains the default.
