# 001 - Path URL strategy for shareable song links

## Context
Flutter web defaults to hash routing, so deep links like `/song/:id` fall back to
Home on direct load (in-app navigation works fine). For shareable/bookmarkable song
URLs this should use path-based routing.

## What to do
- Call `usePathUrlStrategy()` (package:flutter_web_plugins) in main before runApp.
- Ensure the web server / host serves index.html for unknown paths (SPA fallback);
  for `flutter run` it already does, for deploy add the host rewrite.
- Re-verify with Playwright that loading `/song/:id` directly renders the song.

## Acceptance
- Direct navigation to `http://host/song/<id>` renders the song view, not Home.
- No regression to in-app drawer/search navigation.
