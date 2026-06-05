/// Platform-agnostic microphone tuner contract.
///
/// The Tuner screen depends only on this interface. The concrete implementation
/// is chosen at compile time via a conditional import (`mic_web.dart` on web,
/// `mic_io.dart` everywhere else) so the screen compiles and runs on all
/// platforms without `dart:html` / `dart:js_interop` leaking into shared code.
library;

import 'mic_io.dart' if (dart.library.js_interop) 'mic_web.dart';

/// A single detected-pitch sample emitted by [MicTuner.pitchStream].
class PitchSample {
  const PitchSample({required this.frequencyHz});

  /// Detected fundamental frequency in Hz.
  final double frequencyHz;
}

/// The state a [MicTuner] can be in, surfaced to the UI for messaging.
enum MicTunerStatus {
  /// Not started, or stopped.
  idle,

  /// Requesting mic permission / spinning up the audio graph.
  starting,

  /// Actively capturing and emitting pitch samples.
  listening,

  /// User denied microphone permission.
  permissionDenied,

  /// No microphone / capture device available, or audio init failed.
  unavailable,

  /// This platform has no live-mic implementation (mobile/desktop stub).
  unsupported,
}

/// Live microphone pitch source.
///
/// Implementations capture audio, run the pure [estimatePitch] over each frame,
/// and emit detected frequencies on [pitchStream]. [status] reflects lifecycle
/// + error state for the UI to render a friendly message.
abstract class MicTuner {
  /// Detected pitches. Only emits when a clear pitch is found; quiet/noisy
  /// frames are simply skipped (no event).
  Stream<PitchSample> get pitchStream;

  /// Lifecycle / error state, for UI messaging.
  Stream<MicTunerStatus> get statusStream;

  /// Whether this platform actually supports live mic capture.
  bool get isSupported;

  /// Begins capture. Safe to call once; resolves the permission prompt and
  /// starts emitting on [pitchStream]. Never throws: failures surface as a
  /// [MicTunerStatus] on [statusStream].
  Future<void> start();

  /// Stops capture and releases all audio resources (tracks, AudioContext).
  Future<void> stop();

  /// Permanently disposes the tuner. After this the instance is unusable.
  Future<void> dispose();
}

/// Constructs the platform-appropriate [MicTuner]. Resolved at compile time by
/// the conditional import above.
MicTuner createMicTuner() => createMicTunerImpl();
