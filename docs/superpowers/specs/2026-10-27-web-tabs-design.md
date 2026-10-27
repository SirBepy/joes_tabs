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

## Status and pivot (end of 2026-10-27 session)

Built and committed on `develop` (not pushed): converter + site rules (`529a7b4`),
migration + SQL test (`2c9cd5c`), Brave `web-search` Edge Function (`2d631c6`), data
layer (`d26e04b`), Search "From the web" section + `WebTabScreen` + source credit
(`71cc73b`). The migration and the Brave `web-search` function are deployed to the cloud
project; `BRAVE_API_KEY` was never set, so web search returns 503 today.

Joe then dropped Brave (not worth a card-backed account) and decided:

- **Search runs on our backend.** The `web-search` Edge Function fetches the site's own
  search page server-side and stores the results in Supabase, fresh for **7 days**, with a
  manual "refresh web results" action that bypasses the cache. The Brave code is to be
  removed (repo and cloud deployment).
- **Ukulele-tabs.com only, for now.** Spike (2026-10-27): `GET
  https://www.ukulele-tabs.com/search-uke-chords.html?find=<q>` is allowed by robots.txt,
  server-rendered, no bot challenge from a residential IP (datacenter IPs untested), capped at
  50 songs, no pagination. Song links match `/uke-songs/<artist>/<title>-uke-tab-<n>.html`
  inside `div.song_res`, with a `span.tabtype` of `chrd` / `tab` / `mix`; titles need HTML
  entity decoding. Chordie was dropped: fuzzy results and its `/chord.pere/<host>/` pages
  mirror other sites, including excluded ones. E-Chords' robots.txt disallows `/search` and
  `?q=`.
- **New product direction (to brainstorm next):** position Joe's Tabs as an app for
  ukulele-tabs.com, use as much of their infrastructure (APIs, data) as possible while still
  using our Supabase, and pitch it to them when done. First step: research prior art (existing
  apps/sites doing this, including ukulele-tabs.com's own mobile apps) and what APIs or
  partner options ukulele-tabs.com offers.
