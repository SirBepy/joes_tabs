# Tuner Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fake tap-to-select tuner with an always-on mic tuner that auto-detects which string you're playing and shows it on a sliding chromatic gauge with one color-coded pointer.

**Architecture:** Pure, time-free `TunerEngine` consumes detected frequencies and produces a stable locked-string + smoothed-cents state (open-string snapping + lock/hysteresis/debounce/silence-reset/octave-fold). A presentational `TunerGauge` widget renders the sliding ribbon + single pointer + lock glow. The screen owns the mic + engine + tone-player lifecycle, auto-starts listening, drives the engine from a periodic ticker, and plays sampled-pluck reference tones from the chips. Native mic capture (`record`) closes ai_todo 003; the screen split closes ai_todo 007.

**Tech Stack:** Flutter, Riverpod, `record ^7.0.0` (native PCM mic), `just_audio ^0.10.5` (tone playback), existing pure-Dart autocorrelation in `pitch.dart`, existing Web Audio path in `mic_web.dart` (unchanged).

**Spec:** `docs/superpowers/specs/2026-06-06-tuner-rework-design.md`

---

## File Structure

- Create `apps/app/lib/tuner/tuner_engine.dart` — pure detection/locking state machine (`TunerEngine`, `TunerState`). No Flutter imports.
- Modify `apps/app/lib/tuner/pitch.dart` — add `centsBetween`, `TuneZone`, `tuneZoneForCents`, `chromaticRibbon` (all pure).
- Create `apps/app/lib/tuner/tone_player.dart` — reference-tone playback via `just_audio`.
- Create `apps/app/lib/tuner/tuner_gauge.dart` — presentational sliding-ribbon gauge widget. No business logic.
- Rewrite `apps/app/lib/tuner/mic_io.dart` — native PCM capture via `record` (replaces the `unsupported` stub).
- Rewrite `apps/app/lib/screens/tuner_screen.dart` — thin composition: auto-listen, ticker-driven engine, gauge, chip->tone, haptic, mic/tone mutual exclusion.
- Create `apps/app/tool/generate_tones.dart` — offline Karplus-Strong WAV renderer for the 10 open-string plucks.
- Create `apps/app/assets/tones/*.wav` — generated pluck assets (committed).
- Modify `apps/app/pubspec.yaml` — add deps + register `assets/tones/`.
- Modify `apps/app/ios/Runner/Info.plist` — `NSMicrophoneUsageDescription`.
- Modify `apps/app/android/app/src/main/AndroidManifest.xml` — `RECORD_AUDIO`.
- Create `apps/app/test/tuner_engine_test.dart` — engine unit tests (the high-value ones).
- Modify `apps/app/test/pitch_test.dart` (or create if absent) — tests for the new pitch helpers.
- Modify `apps/app/test/tuner_test.dart` — widget tests for the new screen behavior.
- Unchanged: `apps/app/lib/tuner/mic_tuner.dart`, `apps/app/lib/tuner/mic_web.dart`.

**Unchanged contracts to rely on (already in the codebase):**
- `MicTuner` interface + `PitchSample{frequencyHz}` + `MicTunerStatus` enum + `createMicTuner()` in `mic_tuner.dart`.
- `estimatePitch(List<double> samples, int sampleRate, {...})` returns `double?` Hz in `pitch.dart`.
- `openStringFrequencies(List<String> targetNotes, String instrument)` returns `List<double>` in `pitch.dart`.
- `ChordShapes.ukulele` / `ChordShapes.guitar` slugs from `package:models/models.dart`.

---

## Task 1: Add dependencies + native permission entries

**Files:**
- Modify: `apps/app/pubspec.yaml`
- Modify: `apps/app/ios/Runner/Info.plist`
- Modify: `apps/app/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add the two packages to dependencies**

In `apps/app/pubspec.yaml`, under `dependencies:` (after the `web: ^1.1.1` block), add:

```yaml
  # Native (iOS/Android/desktop) microphone PCM stream for the live tuner.
  # Web is unaffected: record's PCM16 stream is unsupported on web, and the
  # conditional import in mic_tuner.dart keeps record out of the web build.
  record: ^7.0.0

  # Reference-tone playback (all platforms incl. web): plays a sampled-pluck WAV
  # for each open string from the tuner's string chips.
  just_audio: ^0.10.5
```

- [ ] **Step 2: Register the tone assets folder**

In `apps/app/pubspec.yaml`, in the `flutter:` section, replace the commented-out `# assets:` block with:

```yaml
  assets:
    - assets/tones/
```

- [ ] **Step 3: Add iOS mic permission string**

In `apps/app/ios/Runner/Info.plist`, inside the top-level `<dict>`, add:

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>Joe's Tabs uses the microphone to tune your ukulele or guitar.</string>
```

- [ ] **Step 4: Add Android mic permission**

In `apps/app/android/app/src/main/AndroidManifest.xml`, add as a direct child of `<manifest>` (above `<application>`):

```xml
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
```

- [ ] **Step 5: Resolve dependencies**

Run: `flutter pub get` (from `apps/app`)
Expected: resolves with `record 7.x` and `just_audio 0.10.x`, no version conflicts.

- [ ] **Step 6: Commit**

Stage `apps/app/pubspec.yaml`, `apps/app/pubspec.lock`, `apps/app/ios/Runner/Info.plist`, `apps/app/android/app/src/main/AndroidManifest.xml`. Do NOT commit directly — the main agent runs `/commit` (prefix `CHORE`). Subagents: stage only and report back.

---

## Task 2: Pure pitch helpers (TDD)

**Files:**
- Modify: `apps/app/lib/tuner/pitch.dart`
- Test: `apps/app/test/pitch_test.dart` (create if it does not exist)

- [ ] **Step 1: Write the failing tests**

Create/extend `apps/app/test/pitch_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/pitch.dart';

void main() {
  group('centsBetween', () {
    test('zero when equal', () {
      expect(centsBetween(440, 440), closeTo(0, 1e-9));
    });
    test('one semitone up is +100 cents', () {
      expect(centsBetween(466.163_761_5, 440), closeTo(100, 0.5));
    });
    test('an octave down is -1200 cents', () {
      expect(centsBetween(220, 440), closeTo(-1200, 1e-6));
    });
    test('non-positive input returns 0', () {
      expect(centsBetween(0, 440), 0);
      expect(centsBetween(440, 0), 0);
    });
  });

  group('tuneZoneForCents', () {
    test('green within +/-5', () {
      expect(tuneZoneForCents(0), TuneZone.green);
      expect(tuneZoneForCents(5), TuneZone.green);
      expect(tuneZoneForCents(-5), TuneZone.green);
    });
    test('amber between 5 and 15', () {
      expect(tuneZoneForCents(6), TuneZone.amber);
      expect(tuneZoneForCents(-15), TuneZone.amber);
    });
    test('red beyond 15', () {
      expect(tuneZoneForCents(16), TuneZone.red);
      expect(tuneZoneForCents(-40), TuneZone.red);
    });
  });

  group('chromaticRibbon', () {
    test('centers on the given note with perSide neighbors each way', () {
      expect(chromaticRibbon('G', 2), ['F', 'F#', 'G', 'G#', 'A']);
    });
    test('wraps around the octave boundary', () {
      expect(chromaticRibbon('C', 1), ['B', 'C', 'C#']);
    });
    test('unknown note returns empty', () {
      expect(chromaticRibbon('H', 2), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/pitch_test.dart` (from `apps/app`)
Expected: FAIL — `centsBetween`, `TuneZone`, `tuneZoneForCents`, `chromaticRibbon` undefined.

- [ ] **Step 3: Implement the helpers**

Append to `apps/app/lib/tuner/pitch.dart` (the file already imports `dart:math as math`):

```dart
/// Signed cents from [hz] up to [targetHz] (positive = [hz] is sharp of target).
/// Returns 0 for non-positive / non-finite input so callers never get NaN.
double centsBetween(double hz, double targetHz) {
  if (!hz.isFinite || hz <= 0 || !targetHz.isFinite || targetHz <= 0) return 0;
  return 1200 * (math.log(hz / targetHz) / math.ln2);
}

/// How in-tune a reading is, for color-coding the gauge.
enum TuneZone { green, amber, red }

/// Buckets a signed cents offset: green within +/-[greenCents], amber out to
/// +/-[amberCents], red beyond. Defaults match the design (5 / 15).
TuneZone tuneZoneForCents(
  double cents, {
  double greenCents = 5,
  double amberCents = 15,
}) {
  final a = cents.abs();
  if (a <= greenCents) return TuneZone.green;
  if (a <= amberCents) return TuneZone.amber;
  return TuneZone.red;
}

/// Chromatic note letters centered on [centerNote] with [perSide] neighbors on
/// each side, wrapping across the octave (e.g. `chromaticRibbon('C', 1)` =>
/// `['B','C','C#']`). Returns empty if [centerNote] is not a chromatic letter.
List<String> chromaticRibbon(String centerNote, int perSide) {
  final c = _noteNames.indexOf(centerNote);
  if (c < 0) return const [];
  final out = <String>[];
  for (var i = -perSide; i <= perSide; i++) {
    out.add(_noteNames[(c + i) % 12]); // Dart % is non-negative for +divisor.
  }
  return out;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/pitch_test.dart`
Expected: PASS (all groups green).

- [ ] **Step 5: Commit**

Stage `apps/app/lib/tuner/pitch.dart`, `apps/app/test/pitch_test.dart`. Report back for `/commit` (prefix `FEAT`). Do NOT commit directly.

---

## Task 3: TunerEngine — locking state machine (TDD)

**Files:**
- Create: `apps/app/lib/tuner/tuner_engine.dart`
- Test: `apps/app/test/tuner_engine_test.dart`

This is the heart of the rework. It is pure and time-free: the caller invokes `update(hz)` once per frame (passing `null` for a silent/no-pitch frame). Frame counting drives the silence reset, so there are no timers here.

- [ ] **Step 1: Write the failing tests**

Create `apps/app/test/tuner_engine_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/pitch.dart';
import 'package:joes_tabs_app/tuner/tuner_engine.dart';

// Ukulele open strings G4 C4 E4 A4.
final ukeFreqs = openStringFrequencies(['G', 'C', 'E', 'A'], 'ukulele');
double freqOf(String n, String inst) => openStringFrequencies([n], inst).first;

TunerEngine engine() => TunerEngine(stringFrequencies: ukeFreqs);

void main() {
  test('starts idle with no lock and no signal', () {
    final s = engine().update(null);
    expect(s.lockedIndex, isNull);
    expect(s.hasSignal, isFalse);
  });

  test('locks onto a string after stabilityFrames of agreement', () {
    final e = engine();
    final c4 = ukeFreqs[1];
    // Two frames: not locked yet (stabilityFrames = 3).
    e.update(c4);
    var s = e.update(c4);
    expect(s.lockedIndex, isNull);
    // Third frame commits the lock to the C string (index 1).
    s = e.update(c4);
    expect(s.lockedIndex, 1);
    expect(s.isInTune, isTrue);
    expect(s.zone, TuneZone.green);
  });

  test('a badly flat string stays locked and does NOT jump to the neighbor', () {
    final e = engine();
    final a4 = ukeFreqs[3];
    // Lock onto A.
    for (var i = 0; i < 3; i++) {
      e.update(a4);
    }
    expect(e.update(a4).lockedIndex, 3);
    // Now play A very flat (down ~80 cents) - still must read as A (index 3),
    // never jump to G/E even though absolute distance shifts.
    final flatA = a4 * 0.955; // ~ -80 cents
    for (var i = 0; i < 5; i++) {
      final s = e.update(flatA);
      expect(s.lockedIndex, 3, reason: 'flat A must stay locked to A');
      expect(s.cents, lessThan(0), reason: 'reads flat');
    }
  });

  test('octave error while locked is folded back to the locked string', () {
    final e = engine();
    final g4 = ukeFreqs[0];
    for (var i = 0; i < 3; i++) {
      e.update(g4);
    }
    expect(e.update(g4).lockedIndex, 0);
    // Detector reports the octave (2x) - should fold to G, near 0 cents, not red.
    final s = e.update(g4 * 2);
    expect(s.lockedIndex, 0);
    expect(s.cents.abs(), lessThan(10));
  });

  test('silence for silenceResetFrames releases the lock', () {
    final e = engine(); // silenceResetFrames default 8
    final e4 = ukeFreqs[2];
    for (var i = 0; i < 3; i++) {
      e.update(e4);
    }
    expect(e.update(e4).lockedIndex, 2);
    // Brief silence keeps the lock...
    expect(e.update(null).lockedIndex, 2);
    // ...sustained silence clears it.
    for (var i = 0; i < 8; i++) {
      e.update(null);
    }
    final s = e.update(null);
    expect(s.lockedIndex, isNull);
    expect(s.hasSignal, isFalse);
  });

  test('switches lock to a clearly different string after silence + restab', () {
    final e = engine();
    final c4 = ukeFreqs[1];
    final a4 = ukeFreqs[3];
    for (var i = 0; i < 3; i++) {
      e.update(c4);
    }
    expect(e.update(c4).lockedIndex, 1);
    // Move to A: needs stabilityFrames of agreement to switch the lock.
    e.update(a4);
    e.update(a4);
    final s = e.update(a4);
    expect(s.lockedIndex, 3);
  });

  test('cents are smoothed toward the target (no instant jumps)', () {
    final e = TunerEngine(stringFrequencies: ukeFreqs, emaAlpha: 0.5);
    final g4 = ukeFreqs[0];
    for (var i = 0; i < 3; i++) {
      e.update(g4); // locks, snaps cents to ~0
    }
    // Feed a sharp reading; smoothed cents should move partway, not all the way.
    final sharpG = g4 * 1.01; // ~ +17 cents
    final s = e.update(sharpG);
    expect(s.cents, greaterThan(0));
    expect(s.cents, lessThan(17));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/tuner_engine_test.dart`
Expected: FAIL — `TunerEngine` / `TunerState` undefined.

- [ ] **Step 3: Implement the engine**

Create `apps/app/lib/tuner/tuner_engine.dart`:

```dart
/// Pure, time-free tuner state machine.
///
/// The screen calls [update] once per frame with the detected fundamental in Hz
/// (or `null` when the frame is silent / has no clear pitch). The engine snaps to
/// the nearest OPEN STRING of the active tuning, then LOCKS onto it so a badly
/// out-of-tune string never makes the display jump to a neighbor. It debounces
/// lock changes, folds octave errors back to the locked string, resets on
/// sustained silence, and EMA-smooths the cents value that drives the gauge.
///
/// No Flutter / timer imports: frame counting (not wall-clock) drives the
/// silence reset, which keeps the whole class unit-testable.
library;

import 'pitch.dart';

/// Immutable snapshot the gauge renders.
class TunerState {
  const TunerState({
    this.lockedIndex,
    this.cents = 0,
    this.zone = TuneZone.red,
    this.isInTune = false,
    this.hasSignal = false,
  });

  /// Index into the tuning's open strings, or null when nothing is locked.
  final int? lockedIndex;

  /// Smoothed signed cents from the locked string (negative = flat).
  final double cents;

  /// Color bucket for [cents].
  final TuneZone zone;

  /// True when [cents] is within the in-tune window and a string is locked.
  final bool isInTune;

  /// True when the current frame carried a usable pitch.
  final bool hasSignal;
}

class TunerEngine {
  TunerEngine({
    required this.stringFrequencies,
    this.stabilityFrames = 3,
    this.switchMarginCents = 120,
    this.silenceResetFrames = 8,
    this.emaAlpha = 0.25,
    this.inTuneCents = 5,
    this.octaveFoldCents = 600,
  });

  /// Equal-tempered frequencies of the active tuning's open strings, in strip
  /// order (e.g. ukulele G4 C4 E4 A4).
  final List<double> stringFrequencies;

  /// Frames of agreement required before acquiring or switching a lock.
  final int stabilityFrames;

  /// A different string must beat the current lock by this many cents (abs) to
  /// be considered for a switch (hysteresis).
  final double switchMarginCents;

  /// Consecutive silent frames that release the lock.
  final int silenceResetFrames;

  /// EMA factor for cents smoothing (higher = snappier, lower = smoother).
  final double emaAlpha;

  /// In-tune (green) half-window in cents.
  final double inTuneCents;

  /// While locked, a reading more than this many cents from the locked string is
  /// folded by octaves back toward it (kills 2x/0.5x harmonic errors).
  final double octaveFoldCents;

  int? _locked;
  double _smoothed = 0;
  int _silent = 0;
  int? _candidate;
  int _candidateCount = 0;
  bool _hasSignal = false;

  /// Clears all state (call when the tuning changes).
  void reset() {
    _locked = null;
    _smoothed = 0;
    _silent = 0;
    _candidate = null;
    _candidateCount = 0;
    _hasSignal = false;
  }

  /// Advances one frame. Pass the detected Hz, or null for a silent frame.
  TunerState update(double? hz) {
    if (hz == null || !hz.isFinite || hz <= 0) {
      _hasSignal = false;
      _silent++;
      if (_silent >= silenceResetFrames) {
        _locked = null;
        _candidate = null;
        _candidateCount = 0;
      }
      return _state();
    }

    _hasSignal = true;
    _silent = 0;

    if (_locked != null) {
      hz = _foldOctave(hz, stringFrequencies[_locked!]);
    }

    final nearest = _nearestIndex(hz);

    if (_locked == null) {
      // Acquire: require stabilityFrames of agreement on the same nearest string.
      if (_candidate == nearest) {
        _candidateCount++;
      } else {
        _candidate = nearest;
        _candidateCount = 1;
      }
      if (_candidateCount >= stabilityFrames) {
        _locked = nearest;
        _smoothed = centsBetween(hz, stringFrequencies[nearest]); // snap on lock
        _candidate = null;
        _candidateCount = 0;
      }
      return _state();
    }

    // Locked: consider a switch only if another string is clearly closer.
    final centsToLocked = centsBetween(hz, stringFrequencies[_locked!]);
    if (nearest != _locked) {
      final centsToNearest = centsBetween(hz, stringFrequencies[nearest]);
      if (centsToNearest.abs() < centsToLocked.abs() - switchMarginCents) {
        if (_candidate == nearest) {
          _candidateCount++;
        } else {
          _candidate = nearest;
          _candidateCount = 1;
        }
        if (_candidateCount >= stabilityFrames) {
          _locked = nearest;
          _smoothed = centsToNearest;
          _candidate = null;
          _candidateCount = 0;
          return _state();
        }
      } else {
        _candidate = null;
        _candidateCount = 0;
      }
    } else {
      _candidate = null;
      _candidateCount = 0;
    }

    // Stay on the locked string; ease the displayed cents toward the reading.
    _smoothed = _smoothed + emaAlpha * (centsToLocked - _smoothed);
    return _state();
  }

  int _nearestIndex(double hz) {
    var best = 0;
    var bestAbs = double.infinity;
    for (var i = 0; i < stringFrequencies.length; i++) {
      final a = centsBetween(hz, stringFrequencies[i]).abs();
      if (a < bestAbs) {
        bestAbs = a;
        best = i;
      }
    }
    return best;
  }

  /// Halves/doubles [hz] until it is within +/-[octaveFoldCents] of [target].
  double _foldOctave(double hz, double target) {
    var f = hz;
    var guard = 0;
    while (centsBetween(f, target) > octaveFoldCents && guard++ < 8) {
      f /= 2;
    }
    while (centsBetween(f, target) < -octaveFoldCents && guard++ < 16) {
      f *= 2;
    }
    return f;
  }

  TunerState _state() {
    final locked = _locked;
    if (locked == null) {
      return TunerState(hasSignal: _hasSignal);
    }
    return TunerState(
      lockedIndex: locked,
      cents: _smoothed,
      zone: tuneZoneForCents(_smoothed),
      isInTune: _smoothed.abs() <= inTuneCents,
      hasSignal: _hasSignal,
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/tuner_engine_test.dart`
Expected: PASS (all 8 tests). If the smoothing test is flaky on the snap-on-lock value, confirm `_smoothed` is set exactly on lock and EMA only runs on subsequent frames.

- [ ] **Step 5: Commit**

Stage `apps/app/lib/tuner/tuner_engine.dart`, `apps/app/test/tuner_engine_test.dart`. Report back for `/commit` (prefix `FEAT`). Do NOT commit directly.

---

## Task 4: Generate sampled-pluck WAV assets

**Files:**
- Create: `apps/app/tool/generate_tones.dart`
- Create: `apps/app/assets/tones/*.wav` (output of the script)

Renders one short Karplus-Strong plucked-string WAV per open string. These are committed, fixed-pitch assets (the design's "pre-rendered files" choice). Real CC0 recordings can replace them later with no code change — that swap is flagged for Joe in Task 10.

- [ ] **Step 1: Write the generator script**

Create `apps/app/tool/generate_tones.dart`:

```dart
// Offline generator for the tuner's reference-tone assets. Run with:
//   dart run tool/generate_tones.dart
// Writes mono 44.1kHz 16-bit WAVs to assets/tones/. Karplus-Strong plucked
// string so each note sounds string-like rather than a clinical sine.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;
const double durationSec = 2.0;

// (filename, frequencyHz) for ukulele G4 C4 E4 A4 and guitar E2 A2 D3 G3 B3 E4.
const tones = <String, double>{
  'uke_g4': 392.00,
  'uke_c4': 261.63,
  'uke_e4': 329.63,
  'uke_a4': 440.00,
  'guitar_e2': 82.41,
  'guitar_a2': 110.00,
  'guitar_d3': 146.83,
  'guitar_g3': 196.00,
  'guitar_b3': 246.94,
  'guitar_e4': 329.63,
};

List<double> karplusStrong(double freq) {
  final total = (sampleRate * durationSec).round();
  final n = (sampleRate / freq).round();
  final buf = List<double>.generate(
    n,
    (_) => math.Random(42).nextDouble() * 2 - 1,
  );
  final out = List<double>.filled(total, 0);
  var idx = 0;
  for (var i = 0; i < total; i++) {
    final cur = buf[idx];
    final next = buf[(idx + 1) % n];
    final sample = 0.5 * (cur + next) * 0.996; // decay
    out[i] = sample;
    buf[idx] = sample;
    idx = (idx + 1) % n;
  }
  // Fade out the last 10% so it does not click on loop/stop.
  final fade = (total * 0.1).round();
  for (var i = 0; i < fade; i++) {
    out[total - 1 - i] *= i / fade;
  }
  return out;
}

Uint8List toWav(List<double> samples) {
  final dataLen = samples.length * 2;
  final b = BytesBuilder();
  void s(String x) => b.add(x.codeUnits);
  void u32(int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) =>
      b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  s('RIFF');
  u32(36 + dataLen);
  s('WAVE');
  s('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  s('data');
  u32(dataLen);
  final pcm = ByteData(dataLen);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    pcm.setInt16(i * 2, v, Endian.little);
  }
  b.add(pcm.buffer.asUint8List());
  return b.toBytes();
}

void main() {
  final dir = Directory('assets/tones')..createSync(recursive: true);
  tones.forEach((name, freq) {
    final wav = toWav(karplusStrong(freq));
    File('${dir.path}/$name.wav').writeAsBytesSync(wav);
    stdout.writeln('wrote $name.wav (${wav.length} bytes)');
  });
}
```

- [ ] **Step 2: Run the generator**

Run: `dart run tool/generate_tones.dart` (from `apps/app`)
Expected: prints 10 lines and creates `assets/tones/uke_g4.wav` … `assets/tones/guitar_e4.wav`.

- [ ] **Step 3: Verify the files exist**

Run: `dir assets\tones` (Windows) or `ls assets/tones`
Expected: 10 `.wav` files.

- [ ] **Step 4: Commit**

Stage `apps/app/tool/generate_tones.dart` and `apps/app/assets/tones/*.wav` by name. Report back for `/commit` (prefix `FEAT`, e.g. "FEAT: add generated reference-tone pluck assets"). Do NOT commit directly.

---

## Task 5: TonePlayer service

**Files:**
- Create: `apps/app/lib/tuner/tone_player.dart`
- Test: `apps/app/test/tone_player_test.dart`

- [ ] **Step 1: Write the failing test (asset-path mapping is the testable part)**

Create `apps/app/test/tone_player_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/tone_player.dart';
import 'package:models/models.dart';

void main() {
  test('maps ukulele strings to the right tone assets', () {
    expect(toneAssetFor(ChordShapes.ukulele, 0), 'assets/tones/uke_g4.wav');
    expect(toneAssetFor(ChordShapes.ukulele, 3), 'assets/tones/uke_a4.wav');
  });
  test('maps guitar strings to the right tone assets', () {
    expect(toneAssetFor(ChordShapes.guitar, 0), 'assets/tones/guitar_e2.wav');
    expect(toneAssetFor(ChordShapes.guitar, 5), 'assets/tones/guitar_e4.wav');
  });
  test('out-of-range index returns null', () {
    expect(toneAssetFor(ChordShapes.ukulele, 9), isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/tone_player_test.dart`
Expected: FAIL — `toneAssetFor` / `tone_player.dart` undefined.

- [ ] **Step 3: Implement the service**

Create `apps/app/lib/tuner/tone_player.dart`:

```dart
/// Plays a sampled-pluck reference tone for an open string so the user can tune
/// by ear. Asset-path mapping is a pure function ([toneAssetFor]) so it is
/// unit-testable; playback wraps just_audio.
library;

import 'package:just_audio/just_audio.dart';
import 'package:models/models.dart';

const _ukeAssets = [
  'assets/tones/uke_g4.wav',
  'assets/tones/uke_c4.wav',
  'assets/tones/uke_e4.wav',
  'assets/tones/uke_a4.wav',
];
const _guitarAssets = [
  'assets/tones/guitar_e2.wav',
  'assets/tones/guitar_a2.wav',
  'assets/tones/guitar_d3.wav',
  'assets/tones/guitar_g3.wav',
  'assets/tones/guitar_b3.wav',
  'assets/tones/guitar_e4.wav',
];

/// Returns the WAV asset for [stringIndex] of [instrument], or null if the index
/// is out of range.
String? toneAssetFor(String instrument, int stringIndex) {
  final list = instrument == ChordShapes.guitar ? _guitarAssets : _ukeAssets;
  if (stringIndex < 0 || stringIndex >= list.length) return null;
  return list[stringIndex];
}

/// Thin wrapper over a single just_audio player for one-shot tone playback.
class TonePlayer {
  final AudioPlayer _player = AudioPlayer();

  /// Plays the tone for [stringIndex] of [instrument] from the start. No-op for
  /// an out-of-range index. Returns once playback has been kicked off.
  Future<void> play(String instrument, int stringIndex) async {
    final asset = toneAssetFor(instrument, stringIndex);
    if (asset == null) return;
    await _player.setAsset(asset);
    await _player.seek(Duration.zero);
    await _player.play();
  }

  /// Approximate length of a tone clip; callers use this to time mic resume.
  static const Duration clipDuration = Duration(seconds: 2);

  Future<void> dispose() => _player.dispose();
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/tone_player_test.dart`
Expected: PASS. (Only `toneAssetFor` is exercised; real audio playback is device-tested.)

- [ ] **Step 5: Commit**

Stage `apps/app/lib/tuner/tone_player.dart`, `apps/app/test/tone_player_test.dart`. Report back for `/commit` (prefix `FEAT`). Do NOT commit directly.

---

## Task 6: Native mic capture (closes ai_todo 003)

**Files:**
- Rewrite: `apps/app/lib/tuner/mic_io.dart`

No unit test (hardware + platform audio; not testable by Claude). Device QA is in Task 10. The pure path it feeds (`estimatePitch` -> `TunerEngine`) is already covered.

- [ ] **Step 1: Replace the stub with a `record`-backed implementation**

Replace the entire contents of `apps/app/lib/tuner/mic_io.dart`:

```dart
/// Native (iOS / Android / desktop) microphone tuner using the `record`
/// package's PCM16 stream. Web is served by `mic_web.dart` via the conditional
/// import in `mic_tuner.dart`, so `record` is never compiled into the web build.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'mic_tuner.dart';
import 'pitch.dart';

const int _sampleRate = 44100;
// ~46ms of audio per pitch estimate: enough periods for the low guitar E2.
const int _frameSamples = 2048;

class _RecordMicTuner implements MicTuner {
  _RecordMicTuner();

  final _recorder = AudioRecorder();
  final _pitches = StreamController<PitchSample>.broadcast();
  final _status = StreamController<MicTunerStatus>.broadcast();
  StreamSubscription<Uint8List>? _audioSub;
  final _buffer = <double>[];

  @override
  Stream<PitchSample> get pitchStream => _pitches.stream;

  @override
  Stream<MicTunerStatus> get statusStream => _status.stream;

  @override
  bool get isSupported => true;

  @override
  Future<void> start() async {
    _status.add(MicTunerStatus.starting);
    try {
      if (!await _recorder.hasPermission()) {
        _status.add(MicTunerStatus.permissionDenied);
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _status.add(MicTunerStatus.listening);
      _audioSub = stream.listen(_onAudio, onError: (_) {
        _status.add(MicTunerStatus.unavailable);
      });
    } catch (_) {
      _status.add(MicTunerStatus.unavailable);
    }
  }

  void _onAudio(Uint8List bytes) {
    // PCM16 little-endian -> normalized doubles in [-1, 1].
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      _buffer.add(view.getInt16(i, Endian.little) / 32768.0);
    }
    while (_buffer.length >= _frameSamples) {
      final frame = _buffer.sublist(0, _frameSamples);
      _buffer.removeRange(0, _frameSamples);
      final hz = estimatePitch(frame, _sampleRate);
      if (hz != null) _pitches.add(PitchSample(frequencyHz: hz));
    }
  }

  @override
  Future<void> stop() async {
    await _audioSub?.cancel();
    _audioSub = null;
    _buffer.clear();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _status.add(MicTunerStatus.idle);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _pitches.close();
    await _status.close();
  }
}

/// Factory used by the conditional import in `mic_tuner.dart`.
MicTuner createMicTunerImpl() => _RecordMicTuner();
```

- [ ] **Step 2: Verify it compiles (analyze)**

Run: `flutter analyze lib/tuner/mic_io.dart`
Expected: No issues. (Full device behavior is verified in Task 10.)

- [ ] **Step 3: Commit**

Stage `apps/app/lib/tuner/mic_io.dart`. Report back for `/commit` (prefix `FEAT`, e.g. "FEAT: native mic capture for the tuner via record"). Do NOT commit directly.

---

## Task 7: TunerGauge widget (closes part of ai_todo 007)

**Files:**
- Create: `apps/app/lib/tuner/tuner_gauge.dart`
- Test: `apps/app/test/tuner_gauge_test.dart`

Pure presentation: big note letter, cents readout, the sliding chromatic ribbon under a fixed color-coded pointer, the green detent band, and the in-tune glow+pulse. No mic/engine/business logic.

- [ ] **Step 1: Write the failing widget test**

Create `apps/app/test/tuner_gauge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/pitch.dart';
import 'package:joes_tabs_app/tuner/tuner_gauge.dart';

Future<void> _pump(WidgetTester t, Widget w) =>
    t.pumpWidget(MaterialApp(home: Scaffold(body: w)));

void main() {
  testWidgets('renders the center note and its chromatic neighbors', (t) async {
    await _pump(
      t,
      const TunerGauge(
        centerNote: 'G',
        cents: 0,
        zone: TuneZone.green,
        isInTune: true,
        active: true,
      ),
    );
    // Center note plus neighbors are on the ribbon.
    expect(find.text('G'), findsWidgets);
    expect(find.text('F#'), findsWidgets);
    expect(find.text('G#'), findsWidgets);
  });

  testWidgets('shows a dash for cents when inactive', (t) async {
    await _pump(
      t,
      const TunerGauge(
        centerNote: 'G',
        cents: 0,
        zone: TuneZone.red,
        isInTune: false,
        active: false,
      ),
    );
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('shows a signed cents number when active', (t) async {
    await _pump(
      t,
      const TunerGauge(
        centerNote: 'A',
        cents: -12,
        zone: TuneZone.amber,
        isInTune: false,
        active: true,
      ),
    );
    expect(find.text('-12¢'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/tuner_gauge_test.dart`
Expected: FAIL — `TunerGauge` undefined.

- [ ] **Step 3: Implement the gauge**

Create `apps/app/lib/tuner/tuner_gauge.dart`:

```dart
/// Presentational tuner gauge: a sliding chromatic note ribbon under a fixed,
/// color-coded center pointer, with the big target-note letter + cents readout
/// and an in-tune glow+pulse. Driven entirely by props - no business logic.
library;

import 'package:flutter/material.dart';

import 'pitch.dart';

// Tuner zone colors (design spec; tweakable later with Joe).
const Color _green = Color(0xFF3FA34D);
const Color _amber = Color(0xFFE8B23C);
const Color _red = Color(0xFFD9534F);
const Color _ink = Color(0xFF3A2E27);
const Color _muted = Color(0xFFB8A99D);
const Color _peach2 = Color(0xFFF6E2D4);

Color _colorFor(TuneZone z) => switch (z) {
      TuneZone.green => _green,
      TuneZone.amber => _amber,
      TuneZone.red => _red,
    };

/// How many chromatic neighbors show on each side of the center note.
const int _perSide = 3;
/// Pixels between adjacent semitone labels (one semitone == 100 cents).
const double _semitonePx = 74;

class TunerGauge extends StatefulWidget {
  const TunerGauge({
    super.key,
    required this.centerNote,
    required this.cents,
    required this.zone,
    required this.isInTune,
    required this.active,
  });

  /// The note the ribbon is centered on (a bare letter, e.g. 'G').
  final String centerNote;

  /// Smoothed signed cents from the target (negative = flat).
  final double cents;

  /// Color bucket for the pointer / note / cents.
  final TuneZone zone;

  /// Whether the reading is within the in-tune window (drives the glow/pulse).
  final bool isInTune;

  /// False when nothing is locked (listening / silence): shows a muted state.
  final bool active;

  @override
  State<TunerGauge> createState() => _TunerGaugeState();
}

class _TunerGaugeState extends State<TunerGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(TunerGauge old) {
    super.didUpdateWidget(old);
    // Fire the celebration on the rising edge of in-tune.
    if (widget.isInTune && widget.active && !(old.isInTune && old.active)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? _colorFor(widget.zone) : _muted;
    final notes = chromaticRibbon(widget.centerNote, _perSide);
    final centsLabel = !widget.active
        ? '--'
        : '${widget.cents >= 0 ? '+' : ''}${widget.cents.round()}¢';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big target-note letter with glow+pulse on lock.
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(_pulse.value);
            final scale = 1 + 0.12 * (1 - (2 * _pulse.value - 1).abs());
            return Transform.scale(
              scale: widget.isInTune ? 1 + 0.12 * (1 - t).clamp(0, 1) * 0 + (scale - 1) : 1,
              child: Text(
                widget.centerNote,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: color,
                  shadows: widget.isInTune
                      ? [const Shadow(color: _green, blurRadius: 18)]
                      : null,
                ),
              ),
            );
          },
        ),
        Text(
          centsLabel,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        // The gauge: fixed center pointer + sliding ribbon + detent band.
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 96,
            color: _peach2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Green detent band marking the in-tune zone.
                Container(
                  width: (widget.active ? 1 : 1) *
                      (2 * 5 / 100) * _semitonePx, // +/-5 cents wide
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: _green.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                // Sliding ribbon: translate by -cents within the semitone.
                TweenAnimationBuilder<double>(
                  tween: Tween(end: widget.active ? widget.cents : 0),
                  duration: const Duration(milliseconds: 90),
                  builder: (context, animCents, _) {
                    final dx = -(animCents / 100) * _semitonePx;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final n in notes)
                            SizedBox(
                              width: _semitonePx,
                              child: Center(
                                child: Text(
                                  n,
                                  style: TextStyle(
                                    fontWeight: n == widget.centerNote
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize:
                                        n.contains('#') ? 13 : 20,
                                    color: n == widget.centerNote
                                        ? _ink
                                        : (n.contains('#')
                                            ? _muted
                                            : _ink.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // Fixed center pointer (downward triangle), colored by zone.
                Align(
                  alignment: Alignment.topCenter,
                  child: CustomPaint(
                    size: const Size(18, 13),
                    painter: _PointerPainter(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.color != color;
}
```

> Note for the implementer: the `Transform.scale` expression above is intentionally simple — pulse to ~1.12x at the animation midpoint and settle to 1.0. If the `scale` math reads awkwardly, replace the `scale:` argument with a clean `1 + 0.12 * (1 - (2 * _pulse.value - 1).abs())` (a triangle 0->1->0 over the 300ms), which is the intended curve. Keep the green `Shadow` for the glow. Exact timing is deferred polish (spec).

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/tuner_gauge_test.dart`
Expected: PASS. If `find.text('-12¢')` fails, confirm the cents label uses the `¢` glyph and no thousands formatting.

- [ ] **Step 5: Commit**

Stage `apps/app/lib/tuner/tuner_gauge.dart`, `apps/app/test/tuner_gauge_test.dart`. Report back for `/commit` (prefix `FEAT`). Do NOT commit directly.

---

## Task 8: Rewrite the tuner screen as composition (closes ai_todo 007)

**Files:**
- Rewrite: `apps/app/lib/screens/tuner_screen.dart`

The screen owns the mic + engine + tone-player lifecycle, auto-starts listening, drives the engine from a ~66ms ticker (so silence frames are counted even though `pitchStream` only emits on a clear pitch), renders the gauge, plays a reference tone on chip tap (pausing mic feed to avoid feedback), and fires a light haptic on the rising edge of in-tune.

- [ ] **Step 1: Replace the screen implementation**

Replace the entire contents of `apps/app/lib/screens/tuner_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../tuner/mic_tuner.dart';
import '../tuner/pitch.dart';
import '../tuner/tone_player.dart';
import '../tuner/tuner_engine.dart';
import '../tuner/tuner_gauge.dart';
import '../widgets/brand_mascot.dart';
import '../widgets/instrument_toggle.dart';

/// Open-string tuning of each supported instrument, low-to-high.
const Map<String, List<String>> _tunings = {
  ChordShapes.ukulele: ['G', 'C', 'E', 'A'],
  ChordShapes.guitar: ['E', 'A', 'D', 'G', 'B', 'E'],
};

String _octaveKeyFor(String slug) =>
    slug == ChordShapes.guitar ? 'guitar' : 'ukulele';

/// How often the engine is advanced. The mic only emits on a clear pitch, so the
/// ticker supplies the steady frame cadence the engine needs to count silence.
const Duration _tick = Duration(milliseconds: 66);

/// Always-on mic tuner. Auto-detects which open string is being played, shows it
/// on the sliding chromatic gauge, and color-codes how in-tune it is. The string
/// chips play a sampled-pluck reference tone for tuning by ear.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> {
  String _instrument = ChordShapes.ukulele;

  MicTuner? _mic;
  StreamSubscription<PitchSample>? _pitchSub;
  StreamSubscription<MicTunerStatus>? _statusSub;
  MicTunerStatus _micStatus = MicTunerStatus.idle;

  late TunerEngine _engine = _buildEngine(_instrument);
  Timer? _ticker;
  double? _pendingHz; // most recent pitch since the last tick
  bool _suppressMic = false; // true while a reference tone is playing
  TunerState _state = const TunerState();

  final TonePlayer _tonePlayer = TonePlayer();

  List<String> get _strings => _tunings[_instrument]!;

  TunerEngine _buildEngine(String slug) => TunerEngine(
        stringFrequencies:
            openStringFrequencies(_tunings[slug]!, _octaveKeyFor(slug)),
      );

  @override
  void initState() {
    super.initState();
    _startMic();
    _ticker = Timer.periodic(_tick, (_) => _onTick());
  }

  Future<void> _startMic() async {
    final mic = createMicTuner();
    _mic = mic;
    _statusSub = mic.statusStream.listen((s) {
      if (mounted) setState(() => _micStatus = s);
    });
    _pitchSub = mic.pitchStream.listen((sample) {
      if (!_suppressMic) _pendingHz = sample.frequencyHz;
    });
    await mic.start();
  }

  void _onTick() {
    final hz = _suppressMic ? null : _pendingHz;
    _pendingHz = null;
    final next = _engine.update(hz);
    final justInTune = next.isInTune && !_state.isInTune;
    if (mounted) setState(() => _state = next);
    if (justInTune) HapticFeedback.lightImpact();
  }

  Future<void> _playTone(int index) async {
    setState(() => _suppressMic = true);
    _engine.reset();
    await _tonePlayer.play(_instrument, index);
    // Resume listening a touch after the clip so the mic does not re-lock the
    // speaker output (feedback guard).
    Timer(TonePlayer.clipDuration + const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _suppressMic = false);
    });
  }

  void _selectInstrument(String slug) {
    ref.read(selectedInstrumentProvider.notifier).state = slug;
  }

  void _applyInstrument(String slug) {
    if (_instrument == slug) return;
    _instrument = slug;
    _engine = _buildEngine(slug);
    _state = const TunerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pitchSub?.cancel();
    _statusSub?.cancel();
    _mic?.dispose();
    _tonePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPicker = ref.watch(showInstrumentPickerProvider);
    _applyInstrument(
      showPicker
          ? ref.watch(selectedInstrumentProvider)
          : ref.watch(instrumentsProvider).first,
    );

    final lockedIndex = _state.lockedIndex;
    final centerNote =
        lockedIndex != null ? _strings[lockedIndex] : _strings[0];
    final active = _state.hasSignal && lockedIndex != null;

    return Column(
      children: [
        if (showPicker)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: InstrumentToggle(
              value: _instrument,
              onChanged: _selectInstrument,
            ),
          ),
        const Expanded(
          child: Center(
            child: BrandMascot(size: 180, icon: PhosphorIconsFill.guitar),
          ),
        ),
        TunerGauge(
          centerNote: centerNote,
          cents: _state.cents,
          zone: _state.zone,
          isInTune: _state.isInTune,
          active: active,
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusLine(micStatus: _micStatus, active: active),
        const SizedBox(height: AppSpacing.md),
        // Reference-tone chips: tap to hear the open string, tune by ear.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < _strings.length; i++)
                _StringChip(label: _strings[i], onTap: () => _playTone(i)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Status / messaging under the gauge. Shows listening prompts and friendly mic
/// errors; the live note + cents now live in the gauge itself.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.micStatus, required this.active});

  final MicTunerStatus micStatus;
  final bool active;

  @override
  Widget build(BuildContext context) {
    switch (micStatus) {
      case MicTunerStatus.permissionDenied:
        return const _Friendly(
          'Microphone blocked. Allow mic access, or tap a string for a '
          'reference tone.',
        );
      case MicTunerStatus.unavailable:
        return const _Friendly(
          'No microphone found. Tap a string for a reference tone instead.',
        );
      case MicTunerStatus.unsupported:
        return _Friendly(
          kIsWeb
              ? 'Live tuning is not available here. Tap a string for a '
                  'reference tone.'
              : 'Live mic tuning is unavailable. Tap a string for a reference '
                  'tone.',
        );
      case MicTunerStatus.idle:
      case MicTunerStatus.starting:
      case MicTunerStatus.listening:
        return Text(
          active ? 'Hold steady...' : 'Listening... play a string',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        );
    }
  }
}

class _Friendly extends StatelessWidget {
  const _Friendly(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A reference-tone chip. Tapping plays that open string's sampled pluck.
class _StringChip extends StatelessWidget {
  const _StringChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play $label reference tone',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.peach,
            border: Border.all(color: AppColors.orange, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsFill.speakerHigh,
                size: 12,
                color: AppColors.orange,
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

> Implementer notes: (1) `PhosphorIconsFill.speakerHigh` denotes "play sound" — if that exact icon name differs in the installed `phosphor_flutter` version, pick the nearest speaker icon. (2) The old `_MicToggle`, `_NoteStrip`, `_Pointer`, `_TrianglePainter` classes are removed (the gauge replaces them; there is no manual listen toggle now). (3) `_inTuneCents` / `_greenInTune` consts are gone (zones live in the engine/gauge).

- [ ] **Step 2: Analyze the screen**

Run: `flutter analyze lib/screens/tuner_screen.dart`
Expected: No issues (resolve any icon-name error from the note above).

- [ ] **Step 3: Commit**

Stage `apps/app/lib/screens/tuner_screen.dart`. Report back for `/commit` (prefix `FEAT`, e.g. "FEAT: always-on auto-detect tuner screen"). Do NOT commit directly.

---

## Task 9: Update the screen widget tests

**Files:**
- Modify: `apps/app/test/tuner_test.dart`

The old tests assert the fake reference-tone flow ("Play the G string", tap-to-settle "In tune"), which no longer exists. Rewrite them for the new behavior: the chips/ribbon show the right notes, the listening prompt shows, and switching instruments swaps the note set. The live note + cents are engine-driven and covered in `tuner_engine_test.dart`.

- [ ] **Step 1: Replace the widget tests**

Replace the contents of `apps/app/test/tuner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/tuner_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride()],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TunerScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows ukulele open strings G C E A by default', (tester) async {
    await _pump(tester);
    for (final note in ['G', 'C', 'E', 'A']) {
      expect(find.text(note), findsWidgets);
    }
    // With no mic signal in tests, the listening prompt is shown.
    expect(find.text('Listening... play a string'), findsOneWidget);
  });

  testWidgets('switching to guitar swaps the note set to E A D G B', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Guitar'));
    await tester.pump();
    expect(find.text('D'), findsWidgets);
    expect(find.text('B'), findsWidgets);
  });

  test('tunings cover both instruments', () {
    expect(ChordShapes.namesFor(ChordShapes.ukulele), isNotEmpty);
    expect(ChordShapes.namesFor(ChordShapes.guitar), isNotEmpty);
  });
}
```

> Implementer note: the screen starts a `Timer.periodic`. In `testWidgets`, call `tester.pump()` (not `pumpAndSettle`, which never settles with a periodic timer). If a test flags a pending-timer error on teardown, the screen's `dispose` cancels the ticker — ensure the widget is disposed by ending the test normally; do not add `pumpAndSettle`.

- [ ] **Step 2: Run the tuner tests**

Run: `flutter test test/tuner_test.dart`
Expected: PASS. If a "Timer is still pending" error appears, confirm `_ticker?.cancel()` runs in `dispose` and the test does not use `pumpAndSettle`.

- [ ] **Step 3: Run the full app test suite**

Run: `flutter test` (from `apps/app`)
Expected: all tests pass (≈232 + the new engine/pitch/gauge/tone tests).

- [ ] **Step 4: Commit**

Stage `apps/app/test/tuner_test.dart`. Report back for `/commit` (prefix `TEST`). Do NOT commit directly.

---

## Task 10: Quality floor, device QA handoff, cleanup

**Files:**
- Delete: `.for_bepy/ai_todos/003-live-mic-tuner.md` (or `003-native-mic.md` — whichever exists)
- Delete: `.for_bepy/ai_todos/007-split-tuner-screen.md`
- Modify: `.for_bepy/BEPY_TODOS.md`

- [ ] **Step 1: Run the full quality floor**

From `apps/app`, run each and confirm clean:
- `dart format .`
- `flutter analyze` (Expected: "No issues found!")
- `flutter test` (Expected: all pass)
- `flutter build web` (Expected: build succeeds — proves `record` did not leak into the web build and `just_audio` web is fine)

If `build_runner`-generated files are missing, run
`dart run build_runner build --delete-conflicting-outputs` in `packages/models`
and `packages/data` first.

- [ ] **Step 2: Add the device-QA + real-sample items to BEPY_TODOS**

In `.for_bepy/BEPY_TODOS.md`, under `### Visual QA` (create the heading if absent), add:

```markdown
- Tune a real ukulele and guitar on a physical iOS + Android device: confirm the
  mic auto-detects the right string, the gauge slides smoothly, and green/amber/
  red + the lock glow/haptic feel right.
- (Optional) Swap the generated Karplus-Strong pluck WAVs in apps/app/assets/tones/
  for real CC0 ukulele/guitar single-note recordings if you want a warmer tone.
```

- [ ] **Step 3: Delete the closed ai_todos**

Delete the native-mic todo (003) and the split-tuner-screen todo (007) from
`.for_bepy/ai_todos/`. Both are now implemented.

- [ ] **Step 4: Commit**

Stage the deleted ai_todo files and `.for_bepy/BEPY_TODOS.md`. Report back for `/commit` (prefix `CHORE`, e.g. "CHORE: close tuner ai_todos, flag device QA"). Do NOT commit directly.

- [ ] **Step 5: Verify the running web app (UI verification)**

Bring the web app up via `/supervised-run` and open it at 390x844. Confirm: the
tuner opens and shows "Listening… play a string" (or a friendly mic message on a
mic-less environment), the gauge renders centered, and tapping a chip plays a
tone. Capture a throwaway screenshot to `.for_bepy/screenshots/`. (Live mic
auto-detect on web depends on the browser having mic access; full instrument
verification is the device-QA item above.)

---

## Self-review notes (addressed)

- **Spec coverage:** sliding ribbon + single colored pointer (Task 7); green/amber/red ±5/±15 (Task 2 + 7); glow+pulse + haptic (Task 7 + 8); open-string snap + lock + hysteresis + debounce + silence reset + octave fold + cents smoothing (Task 3); auto-listen on open (Task 8); native mic / 003 (Task 1 + 6); sampled-pluck tones + just_audio + mic/tone mutual exclusion (Task 1 + 4 + 5 + 8); file split / 007 (Tasks 3,5,7,8); tests (Tasks 2,3,5,7,9); package safety pinned (Task 1); 003+007 deleted + deferred polish flagged (Task 10).
- **Type consistency:** `TunerState{lockedIndex,cents,zone,isInTune,hasSignal}`, `TunerEngine.update(double?)`/`.reset()`, `TuneZone{green,amber,red}`, `tuneZoneForCents`, `centsBetween`, `chromaticRibbon`, `toneAssetFor(instrument,index)`, `TonePlayer.play/.dispose/.clipDuration`, `TunerGauge{centerNote,cents,zone,isInTune,active}` are used identically across tasks.
- **Known soft spot to verify during implementation:** the `Transform.scale` math in `TunerGauge` (Task 7) — use the documented triangle curve `1 + 0.12 * (1 - (2*_pulse.value - 1).abs())` and confirm the glyph `¢` renders in tests.
