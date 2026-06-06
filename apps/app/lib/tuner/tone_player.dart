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
