# Tabs Screen

**Source:** DesignImages/Tabs Screen.png

## Purpose
The song play-along view. Shows a song's chord diagrams plus chord names positioned over lyric lines so the user can strum and sing along. Main performance surface of the app, reached by opening a saved tab.

## Layout
Top to bottom:
- Status bar: standard mobile status bar (time "9:41" left; signal, wifi, battery right). Sits on the orange header background.
- App bar (orange band): a hamburger menu icon on the left and a rounded search bar with a magnifier icon on the right.
- Chord diagram strip: a horizontal row of four chord diagram cards (C, D, Em, F) on tan/peach rounded cards, each showing the diagram for a chord used in this song.
- Title block: large bold orange song title ("LOREM IPSUM") centered, with a smaller muted orange subtitle ("Dolor") beneath it.
- Body: a vertically scrolling area of song sections. Section labels in dark text and brackets ("[Intro]", "[Verse 1]", "[Chorus]"). The Intro line shows a sequence of chord names inline ("A A F#m F#m D E7 A A"). Verse lines show chord names in orange placed above the lyric words where the change happens.
- Floating action button: a round orange button at the bottom right with a sliders / faders icon (controls / settings).

## Components
- Hamburger menu icon (top left).
- Search bar with magnifier icon (top right).
- Four chord diagram cards (C, D, Em, F), each: a 4-string fretboard grid with orange finger-position dots, chord name label at the top of the card.
- Song title text ("LOREM IPSUM", bold orange).
- Subtitle text ("Dolor", muted orange).
- Section labels in brackets ("[Intro]", "[Verse 1]", "[Chorus]").
- Inline chord-name sequence on the Intro line.
- Chord name labels (orange) positioned above lyric words in verse sections.
- Lyric text lines (dark gray) below the chord row.
- Floating round button with a sliders/faders icon (bottom right).

## Interactions / behavior
- Tapping the hamburger opens the app's main navigation drawer/menu.
- Tapping the search bar lets the user search for songs/tabs.
- Tapping a chord diagram card likely opens that chord in detail or jumps to the Chords reference.
- Scrolling the body moves through the song's sections, chords, and lyrics.
- Tapping the floating sliders button opens song controls (likely transpose and/or autoscroll settings; the controls panel itself is not shown in this mockup).

## Data shown
- Dynamic: song title, subtitle, the four chord diagrams used, section labels, the Intro chord sequence, the per-line chord names, and the lyric text.
- Static: the hamburger and search header, the card layout, and the floating button.

## Notes for implementation
- Palette is orange-forward: orange header and accents, tan/peach chord cards, white body, orange chord names, dark gray lyrics. Title is heavy bold orange; subtitle is a lighter muted orange.
- Chord-over-lyric alignment is the core typographic task: anchor each chord name over the syllable where the chord changes, and keep it stable across scroll. Verse lyrics that wrap to a second line keep the chord on the first line.
- Chord diagrams are 4-string (ukulele) grids; reuse the same diagram component as the Chords screen.
- The control affordance is a floating sliders FAB, not an inline bottom toolbar. The actual transpose/autoscroll UI is hidden behind it and not depicted here; confirm what the panel contains before building.
- Lyric copy is placeholder Lorem Ipsum, so real content will vary in length; design for variable line counts and wrapping.
