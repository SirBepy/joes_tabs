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

    // Nearest-string detection always uses the RAW frequency so a clearly
    // different string (e.g. A4 while locked on C4) is identified correctly.
    // Octave folding is applied ONLY when the nearest string IS the locked
    // string, to fold accidental 2x/0.5x harmonics for accurate cents display.
    final nearest = _nearestIndex(hz);

    if (_locked == null) {
      if (_candidate == nearest) {
        _candidateCount++;
      } else {
        _candidate = nearest;
        _candidateCount = 1;
      }
      if (_candidateCount >= stabilityFrames) {
        _locked = nearest;
        _smoothed = centsBetween(hz, stringFrequencies[nearest]);
        _candidate = null;
        _candidateCount = 0;
      }
      return _state();
    }

    if (nearest != _locked) {
      // Potential switch: the raw pitch is closer to a different string.
      final centsToNearest = centsBetween(hz, stringFrequencies[nearest]);
      final centsToLocked = centsBetween(hz, stringFrequencies[_locked!]);
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
      // While counting toward a switch, also update cents against locked string
      // (using folded hz so an octave-harmonic doesn't show huge cents error).
      final hzForCents = _tryFoldOctave(hz, stringFrequencies[_locked!]);
      final centsToLockedFolded = centsBetween(
        hzForCents,
        stringFrequencies[_locked!],
      );
      _smoothed = _smoothed + emaAlpha * (centsToLockedFolded - _smoothed);
    } else {
      // Nearest IS the locked string. Fold octave errors for cents accuracy.
      _candidate = null;
      _candidateCount = 0;
      final hzForCents = _tryFoldOctave(hz, stringFrequencies[_locked!]);
      final centsToLocked = centsBetween(
        hzForCents,
        stringFrequencies[_locked!],
      );
      _smoothed = _smoothed + emaAlpha * (centsToLocked - _smoothed);
    }
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

  /// Like [_foldOctave] but only applies the fold if the result actually lands
  /// within [octaveFoldCents] of [target]. This prevents a genuinely different
  /// string (e.g. A4 while locked on C4) from being mis-folded into a harmonic
  /// that re-maps to the locked string, which would block legitimate lock switches.
  double _tryFoldOctave(double hz, double target) {
    final folded = _foldOctave(hz, target);
    if (centsBetween(folded, target).abs() <= octaveFoldCents) {
      return folded;
    }
    return hz;
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
