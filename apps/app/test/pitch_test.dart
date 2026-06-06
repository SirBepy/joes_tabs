import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/pitch.dart';

/// Synthesizes [durationSeconds] of a [freq] Hz sine wave at [sampleRate].
List<double> _sine(
  double freq,
  int sampleRate, {
  double durationSeconds = 0.1,
  double amplitude = 0.8,
}) {
  final n = (sampleRate * durationSeconds).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    out[i] = amplitude * math.sin(2 * math.pi * freq * i / sampleRate);
  }
  return out;
}

/// Cents between two frequencies.
double _cents(double a, double b) => 1200 * (math.log(a / b) / math.ln2);

void main() {
  group('frequencyToNoteName', () {
    test('440 Hz is exactly A4 with ~0 cents', () {
      final r = frequencyToNoteName(440)!;
      expect(r.name, 'A');
      expect(r.octave, 4);
      expect(r.cents.abs(), lessThan(0.5));
      expect(r.label, 'A4');
    });

    test('261.63 Hz is C4 (middle C)', () {
      final r = frequencyToNoteName(261.63)!;
      expect(r.name, 'C');
      expect(r.octave, 4);
      expect(r.cents.abs(), lessThan(2));
    });

    test('196 Hz is ~G3', () {
      final r = frequencyToNoteName(196)!;
      expect(r.name, 'G');
      expect(r.octave, 3);
      expect(r.cents.abs(), lessThan(3));
    });

    test('low E2 ~82.41 Hz maps to E2', () {
      final r = frequencyToNoteName(82.41)!;
      expect(r.name, 'E');
      expect(r.octave, 2);
      expect(r.cents.abs(), lessThan(2));
    });

    test('sharp pitch yields positive cents, flat yields negative', () {
      // ~25 cents above A4.
      final sharp = frequencyToNoteName(
        440 * math.pow(2, 25 / 1200).toDouble(),
      )!;
      expect(sharp.name, 'A');
      expect(sharp.cents, greaterThan(20));
      expect(sharp.cents, lessThan(30));

      // ~25 cents below A4.
      final flat = frequencyToNoteName(
        440 * math.pow(2, -25 / 1200).toDouble(),
      )!;
      expect(flat.name, 'A');
      expect(flat.cents, lessThan(-20));
      expect(flat.cents, greaterThan(-30));
    });

    test('cents always stays within [-50, 50]', () {
      for (var hz = 80.0; hz <= 1000; hz += 3.7) {
        final r = frequencyToNoteName(hz)!;
        expect(r.cents, inInclusiveRange(-50, 50));
      }
    });

    test('non-positive / non-finite input returns null', () {
      expect(frequencyToNoteName(0), isNull);
      expect(frequencyToNoteName(-100), isNull);
      expect(frequencyToNoteName(double.nan), isNull);
      expect(frequencyToNoteName(double.infinity), isNull);
    });

    test('matched target frequency is the equal-tempered note', () {
      final r = frequencyToNoteName(445)!; // a touch sharp of A4
      expect(r.targetFrequency, closeTo(440, 0.01));
    });
  });

  group('noteLetterToFrequency / openStringFrequencies', () {
    test('A4 letter resolves to 440', () {
      expect(noteLetterToFrequency('A', 4), closeTo(440, 0.001));
    });

    test('ukulele open strings G4 C4 E4 A4', () {
      final freqs = openStringFrequencies(['G', 'C', 'E', 'A'], 'ukulele');
      expect(freqs[0], closeTo(392.0, 0.5)); // G4
      expect(freqs[1], closeTo(261.63, 0.5)); // C4
      expect(freqs[2], closeTo(329.63, 0.5)); // E4
      expect(freqs[3], closeTo(440.0, 0.5)); // A4
    });

    test('guitar open strings E2 A2 D3 G3 B3 E4', () {
      final freqs = openStringFrequencies([
        'E',
        'A',
        'D',
        'G',
        'B',
        'E',
      ], 'guitar');
      expect(freqs[0], closeTo(82.41, 0.5)); // E2
      expect(freqs[1], closeTo(110.0, 0.5)); // A2
      expect(freqs[2], closeTo(146.83, 0.5)); // D3
      expect(freqs[3], closeTo(196.0, 0.5)); // G3
      expect(freqs[4], closeTo(246.94, 0.5)); // B3
      expect(freqs[5], closeTo(329.63, 0.5)); // E4
    });
  });

  group('nearestTargetString', () {
    const uke = ['G', 'C', 'E', 'A'];

    test('A4 pitch matches the A string, ~0 cents', () {
      final m = nearestTargetString(440, uke, 'ukulele')!;
      expect(m.index, 3);
      expect(m.note, 'A');
      expect(m.cents.abs(), lessThan(1));
    });

    test('slightly flat C4 matches C string with negative cents', () {
      final flatC = 261.63 * math.pow(2, -10 / 1200);
      final m = nearestTargetString(flatC.toDouble(), uke, 'ukulele')!;
      expect(m.note, 'C');
      expect(m.cents, lessThan(0));
      expect(m.cents, closeTo(-10, 2));
    });

    test('low E2 picks the low-E guitar string, not the high E4', () {
      const guitar = ['E', 'A', 'D', 'G', 'B', 'E'];
      final m = nearestTargetString(82.41, guitar, 'guitar')!;
      expect(m.index, 0);
      expect(m.cents.abs(), lessThan(2));
    });

    test('empty target list or bad input returns null', () {
      expect(nearestTargetString(440, const [], 'ukulele'), isNull);
      expect(nearestTargetString(0, uke, 'ukulele'), isNull);
      expect(nearestTargetString(double.nan, uke, 'ukulele'), isNull);
    });
  });

  group('estimatePitch', () {
    test('detects A4 (440) within a few cents', () {
      final r = estimatePitch(_sine(440, 44100), 44100)!;
      expect(_cents(r, 440).abs(), lessThan(5));
    });

    test('detects G3 (196) within a few cents', () {
      final r = estimatePitch(_sine(196, 44100), 44100)!;
      expect(_cents(r, 196).abs(), lessThan(5));
    });

    test('detects C4 (261.63) within a few cents', () {
      final r = estimatePitch(_sine(261.63, 44100), 44100)!;
      expect(_cents(r, 261.63).abs(), lessThan(5));
    });

    test('detects low E2 (82.41) within a few cents', () {
      // Longer window so the low fundamental has enough cycles.
      final r = estimatePitch(
        _sine(82.41, 44100, durationSeconds: 0.15),
        44100,
      )!;
      expect(_cents(r, 82.41).abs(), lessThan(8));
    });

    test('works at a 48 kHz sample rate', () {
      final r = estimatePitch(_sine(329.63, 48000), 48000)!;
      expect(_cents(r, 329.63).abs(), lessThan(5));
    });

    test('accepts a Float64List buffer', () {
      final buf = Float64List.fromList(_sine(440, 44100));
      final r = estimatePitch(buf, 44100)!;
      expect(_cents(r, 440).abs(), lessThan(5));
    });

    test('silence (all zeros) returns null', () {
      final silent = List<double>.filled(4096, 0);
      expect(estimatePitch(silent, 44100), isNull);
    });

    test('very quiet signal below RMS threshold returns null', () {
      final quiet = _sine(440, 44100, amplitude: 0.001);
      expect(estimatePitch(quiet, 44100), isNull);
    });

    test('white noise returns null (no clear pitch)', () {
      final rng = math.Random(7);
      final noise = List<double>.generate(
        4096,
        (_) => (rng.nextDouble() * 2 - 1) * 0.5,
      );
      expect(estimatePitch(noise, 44100), isNull);
    });

    test('detected pitch round-trips to the right note name', () {
      final hz = estimatePitch(_sine(440, 44100), 44100)!;
      final note = frequencyToNoteName(hz)!;
      expect(note.label, 'A4');
    });

    test('empty / tiny buffers return null without throwing', () {
      expect(estimatePitch(const [], 44100), isNull);
      expect(estimatePitch(const [0.1], 44100), isNull);
    });

    test('a custom band narrows what is accepted', () {
      final samples = _sine(440, 44100);
      // 440 is inside the default band but outside a 600..1500 band.
      expect(estimatePitch(samples, 44100), isNotNull);
      expect(estimatePitch(samples, 44100, minHz: 600, maxHz: 1500), isNull);
    });

    test('a non-positive sample rate returns null', () {
      expect(estimatePitch(_sine(440, 44100), 0), isNull);
      expect(estimatePitch(_sine(440, 44100), -44100), isNull);
    });

    test('raising the RMS threshold can gate an otherwise-valid tone', () {
      // A 0.05-amplitude tone passes the default 0.01 gate but not a 0.2 gate.
      final quietish = _sine(440, 44100, amplitude: 0.05);
      expect(estimatePitch(quietish, 44100), isNotNull);
      expect(estimatePitch(quietish, 44100, rmsThreshold: 0.2), isNull);
    });

    test('high E4 (329.63) at the top of the tuner band detects cleanly', () {
      final r = estimatePitch(_sine(329.63, 44100), 44100)!;
      expect(_cents(r, 329.63).abs(), lessThan(5));
    });
  });

  group('nearestTargetString octave robustness', () {
    test(
      'an octave-high A still matches the A string (cents may exceed 50)',
      () {
        const uke = ['G', 'C', 'E', 'A'];
        // 880 Hz (A5) is an octave above the A4 string. It is still nearest the
        // A string, with ~ +1200 cents (string match is "nearest of the set").
        final m = nearestTargetString(880, uke, 'ukulele')!;
        expect(m.note, 'A');
        expect(m.cents, closeTo(1200, 5));
      },
    );

    test('unknown instrument falls back to octave 4 for every string', () {
      // openStringFrequencies defaults unknown instruments to octave 4.
      final m = nearestTargetString(440, const ['G', 'C', 'E', 'A'], 'banjo')!;
      // A at octave 4 is exactly 440, so the A string matches with ~0 cents.
      expect(m.note, 'A');
      expect(m.cents.abs(), lessThan(1));
    });
  });

  group('centsBetween', () {
    test('zero when equal', () {
      expect(centsBetween(440, 440), closeTo(0, 1e-9));
    });
    test('one semitone up is +100 cents', () {
      expect(centsBetween(466.1637615, 440), closeTo(100, 0.5));
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
