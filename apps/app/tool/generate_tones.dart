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
  final rng = math.Random(42);
  final buf = List<double>.generate(n, (_) => rng.nextDouble() * 2 - 1);
  final out = List<double>.filled(total, 0);
  var idx = 0;
  for (var i = 0; i < total; i++) {
    final cur = buf[idx];
    final next = buf[(idx + 1) % n];
    // Karplus-Strong: the two-point average is the string; a gentle per-sample
    // damping gives a natural ~2s decay. (A larger factor like 0.996 would halve
    // the amplitude every few ms, collapsing every pitch to the same click.)
    final sample = 0.5 * (cur + next) * 0.99996;
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
