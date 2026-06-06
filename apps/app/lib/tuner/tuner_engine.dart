/// Pure, time-free tuner state machine.
///
/// The screen calls [update] once per frame with the detected fundamental in Hz
/// (or `null` when the frame is silent / has no clear pitch). String matching is
/// OCTAVE-INVARIANT (via [octaveMatch]): any octave of a string's note maps to
/// that string, and [TunerState.octave] reports which octave is sounding. The
/// engine LOCKS onto the matched string with hysteresis so a badly out-of-tune
/// string never jumps to a neighbor, debounces lock changes, resets on sustained
/// silence, and EMA-smooths the cents value that drives the gauge.
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
    this.octave = 0,
    this.zone = TuneZone.red,
    this.isInTune = false,
    this.hasSignal = false,
  });

  /// Index into the tuning's open strings, or null when nothing is locked.
  final int? lockedIndex;

  /// Smoothed signed cents from the nearest octave of the locked string
  /// (negative = flat).
  final double cents;

  /// Scientific octave of the note currently sounding (e.g. 3 for a played G3),
  /// 0 when nothing is locked.
  final int octave;

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
  });

  /// Equal-tempered frequencies of the active tuning's open strings, in strip
  /// order (e.g. ukulele G4 C4 E4 A4). Matching is octave-invariant, so these
  /// are just one representative octave per string.
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

  int? _locked;
  double _smoothed = 0;
  int _octave = 0;
  int _silent = 0;
  int? _candidate;
  int _candidateCount = 0;
  bool _hasSignal = false;

  /// Clears all state (call when the tuning changes).
  void reset() {
    _locked = null;
    _smoothed = 0;
    _octave = 0;
    _silent = 0;
    _candidate = null;
    _candidateCount = 0;
    _hasSignal = false;
  }

  /// Advances one frame. Pass the detected Hz, or null for a silent frame.
  TunerState update(double? hz) {
    final valid = hz != null && hz.isFinite && hz > 0;

    // An empty tuning can never lock onto anything; stay idle without indexing.
    if (stringFrequencies.isEmpty) {
      _hasSignal = valid;
      return TunerState(hasSignal: valid);
    }

    if (!valid) {
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

    final nearest = _nearestIndex(hz);

    if (_locked == null) {
      // Acquire: require stabilityFrames of agreement on the same string.
      if (_candidate == nearest) {
        _candidateCount++;
      } else {
        _candidate = nearest;
        _candidateCount = 1;
      }
      if (_candidateCount >= stabilityFrames) {
        final m = octaveMatch(hz, stringFrequencies[nearest]);
        _locked = nearest;
        _smoothed = m.cents; // snap on a fresh lock
        _octave = m.octave;
        _candidate = null;
        _candidateCount = 0;
      }
      return _state();
    }

    // Locked. Consider a switch only if a different string (by octave-invariant
    // pitch class) is closer by more than the hysteresis margin.
    final lockedMatch = octaveMatch(hz, stringFrequencies[_locked!]);
    if (nearest != _locked) {
      final nearMatch = octaveMatch(hz, stringFrequencies[nearest]);
      if (nearMatch.cents.abs() < lockedMatch.cents.abs() - switchMarginCents) {
        if (_candidate == nearest) {
          _candidateCount++;
        } else {
          _candidate = nearest;
          _candidateCount = 1;
        }
        if (_candidateCount >= stabilityFrames) {
          _locked = nearest;
          _smoothed = nearMatch.cents;
          _octave = nearMatch.octave;
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

    _smoothed = _smoothed + emaAlpha * (lockedMatch.cents - _smoothed);
    _octave = lockedMatch.octave;
    return _state();
  }

  /// The string whose nearest octave is closest (in cents) to [hz].
  int _nearestIndex(double hz) {
    var best = 0;
    var bestAbs = double.infinity;
    for (var i = 0; i < stringFrequencies.length; i++) {
      final a = octaveMatch(hz, stringFrequencies[i]).cents.abs();
      if (a < bestAbs) {
        bestAbs = a;
        best = i;
      }
    }
    return best;
  }

  TunerState _state() {
    final locked = _locked;
    if (locked == null) {
      return TunerState(hasSignal: _hasSignal);
    }
    return TunerState(
      lockedIndex: locked,
      cents: _smoothed,
      octave: _octave,
      zone: tuneZoneForCents(_smoothed),
      isInTune: _smoothed.abs() <= inTuneCents,
      hasSignal: _hasSignal,
    );
  }
}
