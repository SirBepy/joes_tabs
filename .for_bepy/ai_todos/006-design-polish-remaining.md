# 006 - Remaining design-fidelity polish

## Context
Phase B matched the core screens to DesignImages (brand Fredoka font, orange bubble
headers, Home dashboard, Song screen with FAB controls, and a back+title header on
section screens). These remaining items are lower-traffic or need Joe's input.

## Remaining (Claude-doable)
- Splash Screen: match DesignImages/Splash Screen.png (wordmark + mascot layout, timing).
- Log-In / Sign-Up: match DesignImages/Log-In Page.png + Sign-Up Page.png (field styling,
  mascot, bubble title, button styles). Currently functional but plain.
- TY Screen: match DesignImages/TY Screen.png more closely.
- Saved Tabs + Chords: the mockups (Saved Tabs.png, Chords.png) actually show the orange
  search bar AND a bubble title; we currently give them the back+title section header
  (no search). Decide which: if they should keep search, remove them from _sectionTitles
  in app_shell.dart (one line each) and add the title in-body.
- Chord-swatch dots on saved cards are decorative; derive the real first chords from the
  song's ChordPro tab content (needs a chord list on the catalog model or a parse step).
- General spacing/pixel polish against each mockup at 390x844.

## Needs Joe
- The orange ukulele MASCOT character art (currently a Phosphor placeholder everywhere a
  mascot appears). Provide the asset(s) and I will wire them in.
- Confirm the brand heading font (currently Fredoka as a stand-in for the mockup's bubble
  font) - swap the asset + family if you have a specific one.

## Acceptance
- Each screen visually matches its mockup at 390x844 (allowing for the mascot placeholder
  until art is supplied).
