# Seed content sources and license audit

This file documents the legal basis for every piece of content seeded into the
catalog. Legality is a hard gate for this project. Nothing here is scraped from
Ultimate Guitar or any ToS-protected / copyrighted source.

## Research: free / legal chord APIs and datasets

Before falling back to hand-authored content, the following candidate sources
were evaluated (per plan 06, task 1):

- **Uberchord API** (`api.uberchord.com`) - returns guitar *chord shapes /
  fingerings* only, NOT song chord-sheets. Useful later for the Chords UI
  diagram data, but it does not provide song content. No song-licensing concern
  because it ships shapes, not arrangements.
- **The Chords API** (`chords.alday.dev`), **Scales-Chords API** - also chord
  shape / theory lookups, not licensed song sheets.
- **Chordonomicon** (arXiv 2410.22046) - a dataset of ~666k songs and chord
  progressions, but it is derived from Common Crawl scrapes of
  ultimate-guitar.com and similar sites. The underlying arrangements are
  third-party copyrighted works and the dataset carries a restrictive
  research-only license. NOT clean for redistribution in a shipped app. Rejected.
- **MusicBrainz** - metadata (titles, artists) only, no chords. Not needed for
  v1 seed content.
- **ChordPro sample repos / JustinGuitar community files** - mixed provenance;
  many contain in-copyright pop songs. Rejected to avoid per-file license review
  risk.

**Conclusion:** no clean, freely-redistributable *song chord-sheet* API or
dataset exists. We fall back (plan task 2) to hand-authored ChordPro
arrangements of public-domain traditional songs. The Uberchord-style chord-shape
data can be added separately for the diagram UI without any song-licensing
concern.

## Songs (all public domain)

Every song below is a traditional / folk work whose musical composition and
lyrics were published long before 1929 and are therefore in the public domain in
the United States (works published before 1929 are PD as of 2026). The artist is
recorded as "Traditional". The ChordPro *arrangements* (chord placement, key
choice, section layout) were authored from scratch for this project and are
released as part of this repository; they are not copied from any third-party
tab site.

| File | Title | Origin / first publication | Public-domain basis |
| --- | --- | --- | --- |
| `amazing-grace.cho` | Amazing Grace | Words John Newton, 1779; common tune "New Britain" pub. 1835 | Pre-1929 publication; long expired copyright |
| `scarborough-fair.cho` | Scarborough Fair | English traditional ballad, medieval origin; printed 19th c. | Traditional folk; no subsisting copyright |
| `house-of-the-rising-sun.cho` | House of the Rising Sun | American/English traditional folk ballad, 19th c. | Traditional folk; the *composition* is PD (modern recorded arrangements are not used here) |
| `greensleeves.cho` | Greensleeves | English traditional, registered 1580 | Centuries-old; PD |
| `oh-susanna.cho` | Oh! Susanna | Stephen Foster, 1848 | Pre-1929; expired copyright |
| `this-little-light-of-mine.cho` | This Little Light of Mine | Traditional African-American gospel/spiritual, 19th c. | Traditional; no subsisting copyright on the trad. version |
| `will-the-circle-be-unbroken.cho` | Will the Circle Be Unbroken | Hymn by Ada R. Habershon / Charles H. Gabriel, 1907 | Pre-1929; expired copyright (the trad. version, not the 1935 Carter Family "Can the Circle..." rewrite) |
| `down-in-the-valley.cho` | Down in the Valley | American traditional folk, 19th c. | Traditional folk; PD |
| `red-river-valley.cho` | Red River Valley | North American traditional folk, pub. by 1896 | Pre-1929; PD |
| `when-the-saints-go-marching-in.cho` | When the Saints Go Marching In | Traditional gospel, pub. early 1900s | Pre-1929; PD |
| `swing-low-sweet-chariot.cho` | Swing Low, Sweet Chariot | African-American spiritual, pub. by 1872 | Pre-1929; PD |
| `wayfaring-stranger.cho` | Wayfaring Stranger | American traditional folk/spiritual, 19th c. | Traditional folk; PD |
| `aura-lee.cho` | Aura Lee | Words W. W. Fosdick, music George R. Poulton, 1861 | Pre-1929; expired copyright |
| `oh-my-darling-clementine.cho` | Oh My Darling Clementine | Percy Montrose, pub. 1884 (earlier "Down by the River" 1863) | Pre-1929; expired copyright |
| `camptown-races.cho` | Camptown Races | Stephen Foster, 1850 | Pre-1929; expired copyright |
| `shenandoah.cho` | Shenandoah | American traditional folk/sea shanty, pub. by 1882 | Pre-1929; traditional folk; PD |
| `the-water-is-wide.cho` | The Water Is Wide | English traditional ("O Waly Waly"), collected by Cecil Sharp 1906 | Traditional folk; the trad. composition is PD |
| `simple-gifts.cho` | Simple Gifts | Shaker hymn by Joseph Brackett, 1848 | Pre-1929; expired copyright |
| `home-on-the-range.cho` | Home on the Range | Words Brewster Higley, music Daniel Kelley, c. 1872 | Pre-1929; ruled PD (1930s copyright claim invalidated) |
| `kumbaya.cho` | Kumbaya | African-American spiritual, pub. by 1926 | Pre-1929; traditional spiritual; PD |
| `beautiful-dreamer.cho` | Beautiful Dreamer | Stephen Foster, pub. posthumously 1864 | Pre-1929; expired copyright |
| `jeanie-with-the-light-brown-hair.cho` | Jeanie with the Light Brown Hair | Stephen Foster, 1854 | Pre-1929; expired copyright |
| `my-old-kentucky-home.cho` | My Old Kentucky Home | Stephen Foster, 1853 | Pre-1929; expired copyright |
| `danny-boy.cho` | Danny Boy | Lyrics Frederic Weatherly 1910 (set to tune 1913); melody "Londonderry Air" traditional Irish | Lyricist died 1929, words published pre-1931 and PD in the US; melody is centuries-old traditional. Original arrangement, not a modern recorded version |
| `drunken-sailor.cho` | Drunken Sailor | English/maritime traditional sea shanty, early 19th c. | Traditional folk; no subsisting copyright |
| `buffalo-gals.cho` | Buffalo Gals | American minstrel/folk song, pub. 1844 ("Lubly Fan" / Cool White) | Pre-1929; expired copyright |
| `man-of-constant-sorrow.cho` | Man of Constant Sorrow | Traditional Appalachian folk; first printed by Dick Burnett as "Farewell Song", 1913 | Pre-1929; traditional folk; PD (uses the traditional pre-1929 text, not the 2000 film arrangement) |
| `john-henry.cho` | John Henry | African-American traditional ballad, 19th c.; in print by early 1900s | Traditional folk; pre-1929; PD |
| `midnight-special.cho` | Midnight Special | Traditional Southern folk/prison song; in print 1923-1927 (Sandburg's "American Songbag", 1927) | Pre-1929; traditional; PD (the traditional version, not a specific later recorded arrangement) |
| `wabash-cannonball.cho` | Wabash Cannonball | From "The Great Rock Island Route", J. A. Roff 1882; rewritten by William Kindt 1904 | Pre-1929; both source publications PD; uses the traditional pre-1929 text |

## Candidates skipped on public-domain uncertainty

- **Wildwood Flower**: the underlying 1860 "I'll Twine 'Mid the Ringlets"
  (Webster/Irving) is PD, but the well-known Carter Family text is a 1928
  derivative with a 1930/1955 copyright registration by Peer International. To
  avoid accidentally seeding the copyrighted derivative lyric, this song was
  skipped rather than risk a per-line license review.
- **Goodnight Irene** (Lead Belly) and the 1964 recorded **House of the Rising
  Sun** arrangement are NOT public domain and were never used.

## Notes on "House of the Rising Sun" and "Will the Circle Be Unbroken"

- **House of the Rising Sun**: the famous 1964 arrangement is a copyrighted
  recording, but the underlying folk song is public domain. The arrangement here
  is an original simple chord layout authored for this project, not the 1964
  recorded arrangement.
- **Will the Circle Be Unbroken**: we use the 1907 Habershon/Gabriel hymn text
  (PD), NOT the 1935 A.P. Carter "Can the Circle Be Unbroken (Bye and Bye)"
  derivative, which may still carry copyright in some renewals. The seeded title
  and lyric reflect the older PD hymn.

## Chord-diagram data (future Chords UI)

No song-licensing concern: chord *shapes* (fingerings) are factual diagrams and
are not copyrightable as arrangements. A static chord-shape map for ukulele
(GCEA) and guitar (EADGBE) can be authored or sourced from Uberchord-style data
later; see `README.md`.
