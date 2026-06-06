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
    e.update(c4);
    var s = e.update(c4);
    expect(s.lockedIndex, isNull);
    s = e.update(c4);
    expect(s.lockedIndex, 1);
    expect(s.isInTune, isTrue);
    expect(s.zone, TuneZone.green);
  });

  test(
    'a badly flat string stays locked and does NOT jump to the neighbor',
    () {
      final e = engine();
      final a4 = ukeFreqs[3];
      for (var i = 0; i < 3; i++) {
        e.update(a4);
      }
      expect(e.update(a4).lockedIndex, 3);
      final flatA = a4 * 0.955; // ~ -80 cents
      for (var i = 0; i < 5; i++) {
        final s = e.update(flatA);
        expect(s.lockedIndex, 3, reason: 'flat A must stay locked to A');
        expect(s.cents, lessThan(0), reason: 'reads flat');
      }
    },
  );

  test('octave error while locked is folded back to the locked string', () {
    final e = engine();
    final g4 = ukeFreqs[0];
    for (var i = 0; i < 3; i++) {
      e.update(g4);
    }
    expect(e.update(g4).lockedIndex, 0);
    final s = e.update(g4 * 2);
    expect(s.lockedIndex, 0);
    expect(s.cents.abs(), lessThan(10));
  });

  test('silence for silenceResetFrames releases the lock', () {
    final e = engine();
    final e4 = ukeFreqs[2];
    for (var i = 0; i < 3; i++) {
      e.update(e4);
    }
    expect(e.update(e4).lockedIndex, 2);
    expect(e.update(null).lockedIndex, 2);
    for (var i = 0; i < 8; i++) {
      e.update(null);
    }
    final s = e.update(null);
    expect(s.lockedIndex, isNull);
    expect(s.hasSignal, isFalse);
  });

  test(
    'switches lock to a clearly different string after enough stable frames',
    () {
      final e = engine();
      final c4 = ukeFreqs[1];
      final a4 = ukeFreqs[3];
      for (var i = 0; i < 3; i++) {
        e.update(c4);
      }
      expect(e.update(c4).lockedIndex, 1);
      e.update(a4);
      e.update(a4);
      final s = e.update(a4);
      expect(s.lockedIndex, 3);
    },
  );

  test('cents are smoothed toward the target (no instant jumps)', () {
    final e = TunerEngine(stringFrequencies: ukeFreqs, emaAlpha: 0.5);
    final g4 = ukeFreqs[0];
    for (var i = 0; i < 3; i++) {
      e.update(g4);
    }
    final sharpG = g4 * 1.01; // ~ +17 cents
    final s = e.update(sharpG);
    expect(s.cents, greaterThan(0));
    expect(s.cents, lessThan(17));
  });

  test('a sustained octave harmonic of the locked string keeps the lock', () {
    final e = engine();
    final g4 = ukeFreqs[0];
    for (var i = 0; i < 3; i++) {
      e.update(g4);
    }
    expect(e.update(g4).lockedIndex, 0);
    // G5 (the octave harmonic) must NOT switch the lock to A and must read ~0.
    for (var i = 0; i < 6; i++) {
      final s = e.update(g4 * 2);
      expect(
        s.lockedIndex,
        0,
        reason: 'octave harmonic must not hijack the lock',
      );
      expect(s.cents.abs(), lessThan(15));
    }
  });

  test('does not switch when a neighbor is closer but not past the margin', () {
    final e = engine();
    final c4 = ukeFreqs[1];
    for (var i = 0; i < 3; i++) {
      e.update(c4);
    }
    expect(e.update(c4).lockedIndex, 1);
    // ~250 cents sharp of C4: nearest becomes E4, but not by switchMarginCents.
    final sharpC = c4 * 1.155;
    for (var i = 0; i < 5; i++) {
      expect(e.update(sharpC).lockedIndex, 1);
    }
  });

  test('an empty string list stays idle and never throws', () {
    final e = TunerEngine(stringFrequencies: <double>[]);
    for (var i = 0; i < 4; i++) {
      expect(e.update(440).lockedIndex, isNull);
    }
    expect(e.update(440).hasSignal, isTrue);
  });
}
