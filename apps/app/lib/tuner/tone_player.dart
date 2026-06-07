/// Plays a sampled-pluck reference tone for an open string so the user can tune
/// by ear. Asset-path mapping is a pure function ([toneAssetFor]) so it is
/// unit-testable; playback wraps just_audio.
library;

import 'dart:async';

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

/// One-shot reference-tone player.
///
/// Each tap gets a FRESH [AudioPlayer]; the previous one is disposed first. A
/// reused just_audio player is unreliable for back-to-back one-shots on web -
/// `play()` only completes when the (2s) clip ends, so reusing the same player
/// mid-clip fails to switch sources and every tap keeps playing the first note.
/// A fresh player per tap guarantees the correct asset plays from the start.
class TonePlayer {
  AudioPlayer? _current;

  /// Plays the tone for [stringIndex] of [instrument] from the start. No-op for
  /// an out-of-range index. Returns once playback has been started (it does not
  /// wait for the clip to finish).
  Future<void> play(String instrument, int stringIndex) async {
    final asset = toneAssetFor(instrument, stringIndex);
    if (asset == null) return;
    // Stop/free any in-progress tone so this tap starts a clean source.
    final previous = _current;
    _current = null;
    await previous?.dispose();
    final player = AudioPlayer();
    _current = player;
    await player.setAsset(asset);
    // Start playback but don't block on completion; swallow errors from a tone
    // that gets disposed by a newer tap.
    unawaited(player.play().catchError((_) {}));
  }

  /// Approximate length of a tone clip; callers use this to time mic resume.
  static const Duration clipDuration = Duration(seconds: 2);

  Future<void> dispose() async {
    final p = _current;
    _current = null;
    await p?.dispose();
  }
}
