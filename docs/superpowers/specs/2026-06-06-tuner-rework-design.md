# Tuner rework design

Date: 2026-06-06
Status: approved for planning (pending Joe's spec review)
Supersedes the tuner portions of the original app design spec.

## Problem

The tuner a previous AI built misread the intended UX:

- You must **manually tap** a string chip (G/C/E/A). Tapping just runs a
  `Future.delayed(450ms)` that **fakes** the string settling to green. No pitch
  is detected, no audio plays. It is a visual simulation, not a tuner.
- Real mic detection exists but is **web-only, experimental**, and buried behind
  a secondary "Listen" toggle. Native (iOS/Android) is a stub returning
  `unsupported`.
- The gauge shows the target note with **two** triangle pointers (a fixed orange
  one and a moving one) and only a binary orange/green state.

What Joe actually wants:

1. **Mic auto-detection is the whole point.** Open the tuner, pluck a string, and
   it instantly knows which string you are tuning. No tapping to select.
2. A **continuous chromatic ribbon** (A · A# · B · C · …) that slides left/right
   under a fixed center pointer as you play.
3. **One** indicator, **color-coded**: green = in tune, amber = close, red = off.
4. The **G/C/E/A chips are demoted** to "play a reference tone" so you can tune by
   ear. They no longer select anything.

## Goals

- Replace the fake reference-tone settling with real, always-on pitch detection.
- New sliding chromatic gauge with a single color-coded pointer + lock celebration.
- Auto-detect the target string with no manual selection, and make it feel
  rock-solid (no jumping to the wrong string).
- Native mic capture on iOS/Android (closes ai_todo 003), web path unchanged.
- Reference-tone playback from the chips using sampled plucks (new; no audio
  output exists today).
- Split the oversized `tuner_screen.dart` into a presentational gauge widget +
  controller (closes ai_todo 007).

## Non-goals / out of scope

- Polyphonic (all-strings-at-once) tuning like PolyTune. One string at a time.
- Alternate/custom tunings UI. Keep the existing ukulele/guitar toggle only.
- Mascot character art (Joe supplies later; Phosphor placeholder stays).
- Final color values and the exact swell timing: locked to sensible defaults now,
  fine-tuned with Joe later (see "Deferred polish").

## UX design (decided via visual mockups with Joe)

### Layout (390x844 portrait)

Top to bottom: app shell chrome, instrument toggle (Ukulele / Guitar), mascot
placeholder, **big target-note letter** with octave superscript, **cents readout**,
the **sliding chromatic gauge**, the **reference-tone chips** row.

### The gauge

- A horizontal **chromatic ribbon** of note letters (… F · F# · G · G# · A …).
  Sharps render smaller/dimmer than naturals.
- The ribbon **slides under a fixed center pointer** (a downward triangle on the
  center line). In tune = the target note sits dead center under the pointer.
  Flat pulls the ribbon one way, sharp the other. (Chosen over a swinging needle.)
- **Single pointer**, color-coded. No second pointer.
- **Scrolling chromatic scale**, ~3-5 notes visible (not a one-note ±50¢ zoom and
  not a second precision bar; Joe rejected both). Spacing: one semitone ≈ gauge
  width / 3.6 so neighbors stay readable as letters scroll by.
- A faint **green detent band** marks the in-tune zone around center.

### Color coding

Based on the **smoothed** cents-to-target:

| Range | Color | Meaning |
|-------|-------|---------|
| ≤ ±5¢ | green (`#3FA34D`) | in tune |
| ±5–15¢ | amber (`#E8B23C`) | close |
| > ±15¢ | red (`#D9534F`) | off |

The pointer triangle, the big note letter, and the cents number all share this
color. Transition is a short color lerp (~120ms), not a hard snap. Thresholds and
exact hex are **tunable later** with Joe.

### In-tune celebration

When smoothed cents enters ±5¢:

- The big note letter does a **glow + pulse**: scale to 1.12x over 300ms with a
  green text-shadow, then settle back to 1.0 and hold steady. (Joe picked this
  over a checkmark and over a ring burst. The 1.12x/300ms timing is a placeholder
  to fine-tune later.)
- A single **light haptic tap** (`HapticFeedback.lightImpact()`), debounced so it
  fires once on entry, not repeatedly while hovering the boundary.

### States

- **Idle / silence:** "Listening… play a string." Ribbon centered, neutral color,
  no pointer color.
- **Detecting:** ribbon slides to the locked string, note + cents + color update.
- **Permission denied / mic unavailable / unsupported:** friendly message (reuse
  existing `MicTunerStatus` copy). Reference-tone chips still work so the screen
  is useful without a mic.

### Reference-tone chips

- The G/C/E/A (uke) / E A D G B E (guitar) chips **play a sampled pluck** of that
  open string when tapped. They do **not** select a tuning target.
- Playing a tone **pauses mic listening** for the tone's duration, then resumes
  (prevents the mic from locking onto the speaker output - a real feedback risk).

## Auto-detection architecture

The hard part. Pure pitch math already exists in `apps/app/lib/tuner/pitch.dart`
(`estimatePitch`, `frequencyToNoteName`, `nearestTargetString`,
`openStringFrequencies`). What is missing is a **target-locking layer** so the
display does not jump to the wrong string when one is badly out of tune.

New pure class `TunerEngine` (no Flutter deps, fully unit-testable) that consumes
raw `PitchSample`s and emits a `TunerState { lockedStringIndex, smoothedCents,
color, isInTune, isListening }`:

1. **Snap to nearest OPEN STRING of the active tuning**, not the nearest chromatic
   note. (`nearestTargetString` already does this.) This is what makes it "just
   know" which string. The chromatic ribbon is the *visual*; the *target* is
   always one of the instrument's open strings.
2. **Confidence + power gating.** Drop frames below an RMS/clarity threshold
   (`estimatePitch` already returns clarity). Silence never moves the pointer.
3. **Octave-error guard.** Reject/divide-down candidates that fall outside the
   instrument's plausible open-string frequency range (kills harmonic octave
   jumps).
4. **Stability debounce.** Require N consecutive frames (start N=3) agreeing on the
   same string before committing a new lock.
5. **Target lock + hysteresis.** Once locked to a string, keep showing it even as
   the pitch drifts toward a neighbor (wide acquire window, narrower+margin
   release). Solves "a flat A reads closer to G# and the display jumps to G#."
6. **Silence reset.** A short silence (~300–500ms below the power gate) releases
   the lock, so moving to a new string re-acquires cleanly.
7. **Cents smoothing.** Smooth the cents value before it drives the gauge so the
   pointer glides. Start with an EMA (~120–150ms time constant); upgrade to a
   1-Euro adaptive filter if it still feels jittery. On-screen motion is tweened
   via an `AnimationController` so the needle always glides regardless of frame
   noise.

All thresholds (N frames, gate level, hysteresis widths, smoothing constant) are
constants on `TunerEngine`, tunable without touching UI.

## Audio

### Native mic capture (closes 003)

- Add `record: ^7.0.0` (publisher `cow-level.ovh` / llfbandit, BSD-3, OSV clean -
  see Packages). Rewrite `apps/app/lib/tuner/mic_io.dart` to replace the stub:
  `startStream(RecordConfig(encoder: AudioEncoder.pcm16bits, numChannels: 1,
  sampleRate: 44100))` → decode PCM16 LE to normalized doubles → feed
  `estimatePitch` with the **same** sample rate → emit `PitchSample`. Wire
  `hasPermission()` into the existing `MicTunerStatus` flow.
- **Web path unchanged.** `record`'s PCM16 stream is not supported on web; the
  conditional import already keeps `record` out of the web build, so `mic_web.dart`
  (Web Audio) and the GitHub Pages build stay exactly as-is.
- Manifests: `NSMicrophoneUsageDescription` (iOS `Info.plist`),
  `<uses-permission android:name="android.permission.RECORD_AUDIO" />` (Android).

### Reference-tone playback (new)

- Add `just_audio: ^0.10.5` (publisher `ryanheise.com`, OSV clean). Ship one short
  **sampled pluck WAV per open string** (uke: G4 C4 E4 A4; guitar: E2 A2 D3 G3 B3
  E4 = 10 files) in `apps/app/assets/tones/`, registered in pubspec. A small
  `TonePlayer` service plays the matching asset on chip tap.
- **Assets must be public-domain / CC0** (project rule: never scrape ToS-protected
  sources). Source CC0 single-note uke/guitar samples, or, if no clean CC0
  recording is available, render Karplus-Strong plucks offline to WAV and commit
  those (documented, fully owned). The runtime only ever plays these fixed pitches,
  so no runtime synthesis is needed.
- Mic-in and tone-out are **mutually exclusive** (pause listening during playback)
  to avoid feedback. Default iOS audio session categories are fine; no
  background-audio entitlement.

## File structure (closes 007)

`tuner_screen.dart` is 581 lines mixing gauge painting, detection wiring, and
layout. Split into:

- `apps/app/lib/tuner/tuner_gauge.dart` — **pure presentation**. Takes the active
  ribbon notes, locked index, smoothed cents, color, and in-tune flag; draws the
  sliding ribbon + single pointer + detent + celebration. No business logic.
- `apps/app/lib/tuner/tuner_engine.dart` — the pure detection/locking state machine
  above (unit-testable, no Flutter).
- `apps/app/lib/tuner/tone_player.dart` — reference-tone playback service.
- `apps/app/lib/screens/tuner_screen.dart` — thin composition: owns the
  `MicTuner` + `TunerEngine` + `TonePlayer` lifecycle, auto-starts listening on
  open, feeds the gauge. Reads as composition.
- `pitch.dart`, `mic_tuner.dart`, `mic_web.dart` unchanged in shape; `mic_io.dart`
  rewritten.

## Packages (safety-checked)

| Package | Pin | Why | Safety |
|---------|-----|-----|--------|
| `record` | `^7.0.0` | native iOS/Android PCM mic stream | publisher cow-level.ovh/llfbandit, BSD-3, 881 likes, OSV clean, no typosquat |
| `just_audio` | `^0.10.5` | reference-tone playback (all platforms incl. web) | publisher ryanheise.com, 4.1k likes, OSV clean |

Both confirmed via OSV + pub.dev publisher/maintenance during research. Personal
project → auto-add allowed once safe (it is). Re-run the check at install time.

## Testing

- **`TunerEngine` unit tests** (the high-value ones, all pure Dart): open-string
  snapping, octave-error rejection, lock + hysteresis (a flat A stays locked to A,
  does not jump to G#), N-frame debounce, silence reset, cents smoothing
  monotonicity, color thresholds at ±5/±15 boundaries.
- **`pitch.dart`**: existing behavior retained; add direct tests for
  `nearestTargetString` edge cases if not already covered.
- **Widget tests**: gauge renders the active instrument's notes; updating
  cents/lock moves the ribbon and recolors; chips trigger the tone player (mocked);
  instrument toggle swaps note set. Adapt the existing `tuner_test.dart` (its
  "reference-tone settling" test for the old fake flow is removed).
- **Native mic + real audio playback**: not unit-testable by Claude (hardware +
  platform audio). Hand to Joe for device QA; everything feeding off the mic is
  tested via injected `PitchSample`s into `TunerEngine`.
- Quality floor: `flutter analyze` clean, `dart format`, all tests pass,
  `flutter build web` succeeds. Run `build_runner` in `packages/models` +
  `packages/data` first if needed.

## Deferred polish (with Joe, later)

- Exact color hex + the ±5/±15 thresholds.
- The swell celebration timing/curve (current 1.12x/300ms is a placeholder; Joe
  felt the "timing" was slightly off but the speed was right).

## Acceptance

- Open tuner → it auto-listens (after one permission grant) and shows
  "Listening…".
- Pluck any string → the correct string locks instantly and stays locked while you
  turn the peg; no jumping to neighbors. Ribbon slides, single pointer recolors
  green/amber/red, note glows + haptic on in-tune.
- Tapping a chip plays that string's sampled pluck; mic pauses then resumes.
- Works on web (unchanged path) and on a real iOS/Android device (native mic).
- `tuner_screen.dart` reads as composition; gauge widget has no business logic.
- ai_todos 003 and 007 deleted.
- Quality floor green.
