# Web tabs: search the web, parse on device, grow a shared catalog

Date: 2026-10-27
Status: approved (design)

## Context

The catalog is 30 hand-authored public-domain songs (`supabase/seed/`). Joe searched
"steven universe" and got nothing. No free, licensed source of in-copyright chord
sheets exists (`supabase/seed/SOURCES.md` covers the API/dataset survey; a second
survey on 2026-10-27 confirmed Musixmatch, LyricFind, Songsterr, Chordify, Hooktheory
and Ultimate Guitar offer nothing a hobby app can license).

Joe's direction: the app is essentially for him, he wants the tabs that already exist
on chord sites, with credit and a link back to the original page. Server-side bulk
scraping is out. What is in: find pages through a licensed search API, open the page
the user picked in a real in-app browser, read the chords out of that already-loaded
page on the device, and keep the parsed tab in a shared catalog that only signed-in
users can read.

## Decisions

| Topic | Decision |
| --- | --- |
| Discovery | Brave Search API via a Supabase Edge Function, `site:` filtered to the allowlist below. Brave's ToS allow showing results in our UI; they forbid storing or caching results, so the function never persists them. |
| Parsing | On device only, in an in-app WebView (`webview_flutter`), after the page has loaded for a real visit. One small JS adapter per site. |
| Storage | A parsed tab is upserted into the normal `songs` / `tabs` tables with `source = 'imported'` plus `source_url` / `source_site`. The viewer, favorites, Drift cache and search all work on it unchanged. Saving one privately = the existing favorites. |
| Visibility | RLS: `official` (public-domain) tabs stay readable by `anon`; `imported` tabs are readable by `authenticated` only. The public web build and logged-out users never see imported lyrics. |
| Who can search the web | Signed-in users only (protects the Brave quota and the card on file). Logged-out users see a "Sign in to search the web" row. |
| Results UI | Always shown, in a "From the web" section below the catalog results. A web result whose URL is already imported is shown as a catalog song instead. |
| Ultimate Guitar | External link only (opens the system browser). Never parsed, never framed. |
| Web build | `webview_flutter` has no web support and browsers block cross-site DOM reads (CORS), so on web every web result opens externally. |
| PD catalog | Kept as-is. |

## Site allowlist (ToS read 2026-10-27)

| Site | Terms | Parse? | Notes |
| --- | --- | --- | --- |
| ukulele-tabs.com | Silent (stub T&Cs, French law) | Yes | Chords-over-lyrics in `pre`, chords are `a.chord`. Has Steven Universe. |
| chordie.com | Silent (no terms page) | Yes | Inline `[Am]` in `.chordline`; `.textline` holds headers. |
| e-chords.com | Silent ("Study, Skill Development, and Scholarship only") | Yes, untested | Behind a Cloudflare challenge that blocks automation; a real WebView should pass. Selector unverified, adapter falls back to the generic `pre` extractor. |
| ultimate-guitar.com | Forbids copying, derivatives and framing (6.2, 6.4, 14(a)) | No | External link only. |

Excluded: guitartabs.cc (UG-clone terms), chordu.com and ukutabs.com (ban automated or
systematic extraction), cifraclub.com.br (bans extraction and framing), doctoruke.com
and ukulelehunt.com (PDF only, nothing in the DOM).

## Architecture

1. **Converter** (`packages/models`, pure Dart, tested): `ChordsOverLyrics.toChordPro`
   turns chords-over-lyrics text into ChordPro. A line is a chord line when every
   token parses as a chord (allowing `|`, `x2`, `N.C.`); its chords are inserted as
   `[X]` at the matching columns of the next lyric line, or emitted alone when the
   next line is blank, another chord line, or a section header. `[Intro]`-style
   headers become ChordPro section comments.
2. **Site rules** (`packages/models`, tested): host -> `WebTabSite` (id, display name,
   `parseable`, default instrument). Unknown hosts are not shown.
3. **Edge Function** `supabase/functions/web-search`: requires a user JWT, builds the
   `site:` query, calls Brave with `BRAVE_API_KEY` from Supabase secrets, returns
   `[{title, url, description}]`. No persistence.
4. **Migration**: `tabs.source_url` (unique where not null), `tabs.source_site`; RLS
   split by `source`; `import_web_tab(...)` SECURITY DEFINER RPC for `authenticated`
   that upserts the song (matched on normalised title + artist) and the tab (matched on
   `source_url`) and returns the song id; `imported_song_ids(urls text[])` to map known
   URLs to songs.
5. **App**: `webSearchProvider` (FutureProvider.family, overridable in tests); Search
   gets a "From the web" section; tapping a parseable result on Android/iOS opens
   `WebTabScreen` (WebView + "Reading chords" overlay) which runs the site adapter,
   converts, calls `import_web_tab`, then replaces itself with `/song/:id`. On a parse
   failure the page stays visible with a message and an "Open in browser" action.
   Everything else opens via `url_launcher`. The song viewer shows "Source: <site>"
   with a link when `source_url` is set.

## Build order

1. Converter + site rules with unit tests.
2. Migration + RPCs (verified on the local Supabase stack).
3. Edge Function.
4. Data layer: repository methods, providers, `Tab.sourceUrl` / `sourceSite`.
5. Search UI section, `WebTabScreen`, source credit in the viewer, widget tests.

## Needs Joe

- A Brave Search API account (card required, about 1,000 free queries a month) and its
  key, set as the `BRAVE_API_KEY` Supabase secret.
- OK before the migration and the Edge Function are deployed to the cloud project.
