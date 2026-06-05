/// Pure, Flutter-free pitch utilities for the Tuner.
///
/// Nothing in this file imports `dart:ui` or Flutter, so every function here is
/// directly unit-testable on the VM. The web mic capture layer
/// (`mic_web.dart`) feeds PCM frames into [estimatePitch] and the result into
/// [frequencyToNoteName] / [nearestTargetString] to drive the gauge.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Chromatic note names (sharps), index 0 == C.
const List<String> _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Concert pitch reference: A4 = 440 Hz.
const double a4Hz = 440.0;

/// MIDI note number of A4. Used as the anchor for the equal-temperament map.
const int _a4Midi = 69;

/// Result of mapping a frequency onto the equal-tempered scale.
class NoteReading {
  const NoteReading({
    required this.name,
    required this.octave,
    required this.cents,
    required this.frequency,
    required this.targetFrequency,
  });

  /// Note letter with optional sharp, e.g. `A`, `C#`.
  final String name;

  /// Scientific-pitch octave number, e.g. 4 for A4 (middle-octave A).
  final int octave;

  /// Signed cents offset from the nearest note, in the range [-50, 50].
  /// Negative means flat (below the note), positive means sharp (above it).
  final double cents;

  /// The frequency that produced this reading.
  final double frequency;

  /// The exact equal-tempered frequency of the matched note.
  final double targetFrequency;

  /// `A`, `C#4`, etc. Convenience label combining [name] and [octave].
  String get label => '$name$octave';
}

/// Maps an arbitrary frequency [hz] onto the nearest equal-tempered note.
///
/// Uses A4 = [a4Hz] and 12-TET. Returns the note name, scientific octave and a
/// signed cents offset in the range [-50, 50] (negative = flat, positive =
/// sharp). Returns `null` for non-positive / non-finite input.
NoteReading? frequencyToNoteName(double hz) {
  if (!hz.isFinite || hz <= 0) return null;

  // Fractional MIDI number for this frequency.
  final double midiReal = _a4Midi + 12 * (math.log(hz / a4Hz) / math.ln2);
  final int midi = midiReal.round();
  final double cents = (midiReal - midi) * 100.0;

  final int noteIndex = midi % 12;
  // Scientific pitch: C4 is MIDI 60, so octave = midi ~/ 12 - 1.
  final int octave = (midi ~/ 12) - 1;

  return NoteReading(
    name: _noteNames[noteIndex],
    octave: octave,
    cents: cents,
    frequency: hz,
    targetFrequency: midiToFrequency(midi),
  );
}

/// Equal-tempered frequency of a MIDI note number.
double midiToFrequency(int midi) => a4Hz * math.pow(2, (midi - _a4Midi) / 12.0);

/// Result of matching a detected frequency to one open string of an
/// instrument's tuning.
class StringMatch {
  const StringMatch({
    required this.index,
    required this.note,
    required this.targetFrequency,
    required this.cents,
  });

  /// Index into the `targetNotes` list that was passed in.
  final int index;

  /// The matched open-string note label including octave, e.g. `G4`.
  final String note;

  /// Equal-tempered frequency of the matched string.
  final double targetFrequency;

  /// Signed cents offset of the detected pitch from this string. Can exceed
  /// +/-50 because a string match is "nearest of the target set", not "nearest
  /// chromatic note".
  final double cents;
}

/// Standard scientific octaves for the open strings of the supported
/// instruments. Ukulele uses re-entrant high-G tuning (g4 c4 e4 a4); guitar is
/// standard E2 A2 D3 G3 B3 E4. Keyed by the bare note letter as used by the
/// tuner UI plus the string position, so callers can pass plain letters.
///
/// We expose a helper rather than hard-coding octaves into note labels so the
/// existing UI (which shows bare letters G C E A) stays unchanged.
const Map<String, List<int>> _instrumentOctaves = {
  // low-to-high order matching the tuner strip.
  'ukulele': [4, 4, 4, 4], // G4 C4 E4 A4 (re-entrant high-G)
  'guitar': [2, 2, 3, 3, 3, 4], // E2 A2 D3 G3 B3 E4
};

/// Builds the absolute frequencies for an instrument's open strings.
///
/// [targetNotes] are bare letters (e.g. `['G','C','E','A']`) in strip order;
/// [instrument] selects the octave map (`'ukulele'` or `'guitar'`). Falls back
/// to octave 4 for everything if the instrument is unknown.
List<double> openStringFrequencies(
  List<String> targetNotes,
  String instrument,
) {
  final octaves =
      _instrumentOctaves[instrument] ?? List<int>.filled(targetNotes.length, 4);
  final out = <double>[];
  for (var i = 0; i < targetNotes.length; i++) {
    final octave = i < octaves.length ? octaves[i] : 4;
    out.add(noteLetterToFrequency(targetNotes[i], octave));
  }
  return out;
}

/// Frequency of a bare note letter (`G`, `C#`) at a scientific [octave].
double noteLetterToFrequency(String letter, int octave) {
  final noteIndex = _noteNames.indexOf(letter);
  if (noteIndex < 0) {
    throw ArgumentError.value(letter, 'letter', 'not a chromatic note name');
  }
  // MIDI = (octave + 1) * 12 + noteIndex.
  final midi = (octave + 1) * 12 + noteIndex;
  return midiToFrequency(midi);
}

/// Returns which target string the detected pitch [hz] is closest to.
///
/// Closeness is measured in cents (log-frequency distance), so it behaves
/// musically across octaves. [targetNotes] are bare letters in strip order and
/// [instrument] picks the octave map. Returns `null` for invalid input or an
/// empty target list.
StringMatch? nearestTargetString(
  double hz,
  List<String> targetNotes,
  String instrument,
) {
  if (!hz.isFinite || hz <= 0 || targetNotes.isEmpty) return null;

  final freqs = openStringFrequencies(targetNotes, instrument);
  var bestIndex = 0;
  var bestCents = double.infinity;
  var bestSignedCents = 0.0;

  for (var i = 0; i < freqs.length; i++) {
    final cents = 1200 * (math.log(hz / freqs[i]) / math.ln2);
    if (cents.abs() < bestCents) {
      bestCents = cents.abs();
      bestSignedCents = cents;
      bestIndex = i;
    }
  }

  return StringMatch(
    index: bestIndex,
    note: targetNotes[bestIndex],
    targetFrequency: freqs[bestIndex],
    cents: bestSignedCents,
  );
}

/// Estimates the fundamental frequency of a block of PCM [samples] using
/// normalized autocorrelation (a lightweight YIN-style approach).
///
/// Returns the detected frequency in Hz, or `null` when no clear periodic pitch
/// is present (silence, noise, or signal too weak to tune to). [sampleRate] is
/// the capture rate, e.g. 44100 or 48000.
///
/// The estimator:
///  1. Rejects frames whose RMS is below [rmsThreshold] (too quiet).
///  2. Computes autocorrelation over a lag range covering [minHz]..[maxHz].
///  3. Picks the first strong peak after the zero-lag dip, then refines it with
///     parabolic interpolation for sub-sample accuracy (a few cents).
double? estimatePitch(
  List<double> samples,
  int sampleRate, {
  double minHz = 60,
  double maxHz = 1500,
  double rmsThreshold = 0.01,
  double clarityThreshold = 0.5,
}) {
  final n = samples.length;
  if (n < 2 || sampleRate <= 0) return null;

  // 1. Loudness gate. RMS below threshold == effectively silence.
  var sumSq = 0.0;
  for (var i = 0; i < n; i++) {
    sumSq += samples[i] * samples[i];
  }
  final rms = math.sqrt(sumSq / n);
  if (rms < rmsThreshold) return null;

  // Lag range from the frequency band of interest.
  final maxLag = math.min(n - 1, (sampleRate / minHz).floor());
  final minLag = math.max(1, (sampleRate / maxHz).floor());
  if (minLag >= maxLag) return null;

  // 2. Autocorrelation, normalized so the peak height is a clarity measure in
  // [0, 1] independent of overall volume.
  final ac = Float64List(maxLag + 1);
  for (var lag = minLag; lag <= maxLag; lag++) {
    var sum = 0.0;
    for (var i = 0; i < n - lag; i++) {
      sum += samples[i] * samples[i + lag];
    }
    ac[lag] = sum;
  }
  // Zero-lag energy for normalization.
  var energy = 0.0;
  for (var i = 0; i < n; i++) {
    energy += samples[i] * samples[i];
  }
  if (energy <= 0) return null;

  // 3. Find the first significant peak. Walk past the initial decline from the
  // (excluded) zero-lag, then take the maximum of the first hump.
  var pos = minLag;
  // Skip while still descending into the first trough.
  while (pos < maxLag && ac[pos] > ac[pos + 1]) {
    pos++;
  }
  // From the trough, find the highest point (first real period peak).
  var peakLag = pos;
  var peakVal = ac[pos];
  for (var lag = pos; lag <= maxLag; lag++) {
    if (ac[lag] > peakVal) {
      peakVal = ac[lag];
      peakLag = lag;
    }
  }
  if (peakLag <= 0) return null;

  // Clarity = normalized peak. Reject ambiguous / noisy frames.
  final clarity = peakVal / energy;
  if (clarity < clarityThreshold) return null;

  // Parabolic interpolation around the peak for sub-sample precision.
  double refinedLag = peakLag.toDouble();
  if (peakLag > minLag && peakLag < maxLag) {
    final a = ac[peakLag - 1];
    final b = ac[peakLag];
    final c = ac[peakLag + 1];
    final denom = a - 2 * b + c;
    if (denom != 0) {
      final shift = 0.5 * (a - c) / denom;
      // Guard against runaway interpolation on flat peaks.
      if (shift.abs() < 1) {
        refinedLag = peakLag + shift;
      }
    }
  }

  final freq = sampleRate / refinedLag;
  if (!freq.isFinite || freq < minHz || freq > maxHz) return null;
  return freq;
}
