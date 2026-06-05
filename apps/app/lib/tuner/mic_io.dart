/// Non-web (mobile / desktop) microphone tuner stub.
///
/// On these platforms we have no live-mic pitch implementation yet, so this
/// stub reports `unsupported` and the Tuner screen falls back to its
/// reference-tone behaviour. The pure pitch math in `pitch.dart` is fully
/// reusable; only the capture layer is missing here.
///
/// TODO(device): native mic pitch detection. Wire a real microphone capture
/// path (e.g. the `record` package's PCM stream, or a platform channel feeding
/// Float64 frames into estimatePitch) and emit real PitchSample events.
/// Requires a physical-device test pass, tracked as a separate follow-up.
library;

import 'dart:async';

import 'mic_tuner.dart';

/// Stub [MicTuner] used on every non-web platform.
class _StubMicTuner implements MicTuner {
  final _pitches = StreamController<PitchSample>.broadcast();
  final _status = StreamController<MicTunerStatus>.broadcast();

  @override
  Stream<PitchSample> get pitchStream => _pitches.stream;

  @override
  Stream<MicTunerStatus> get statusStream => _status.stream;

  @override
  bool get isSupported => false;

  @override
  Future<void> start() async {
    // No native capture yet: announce unsupported so the UI shows the
    // reference-tone fallback message instead of a spinner.
    _status.add(MicTunerStatus.unsupported);
  }

  @override
  Future<void> stop() async {
    _status.add(MicTunerStatus.idle);
  }

  @override
  Future<void> dispose() async {
    await _pitches.close();
    await _status.close();
  }
}

/// Factory used by the conditional import in `mic_tuner.dart`.
MicTuner createMicTunerImpl() => _StubMicTuner();
