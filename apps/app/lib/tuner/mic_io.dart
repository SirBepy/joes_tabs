/// Native (iOS / Android / desktop) microphone tuner using the `record`
/// package's PCM16 stream. Web is served by `mic_web.dart` via the conditional
/// import in `mic_tuner.dart`, so `record` is never compiled into the web build.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'mic_tuner.dart';
import 'pitch.dart';

const int _sampleRate = 44100;
// ~46ms of audio per pitch estimate: enough periods for the low guitar E2.
const int _frameSamples = 2048;

class _RecordMicTuner implements MicTuner {
  _RecordMicTuner();

  final _recorder = AudioRecorder();
  final _pitches = StreamController<PitchSample>.broadcast();
  final _status = StreamController<MicTunerStatus>.broadcast();
  StreamSubscription<Uint8List>? _audioSub;
  final _buffer = <double>[];

  @override
  Stream<PitchSample> get pitchStream => _pitches.stream;

  @override
  Stream<MicTunerStatus> get statusStream => _status.stream;

  @override
  bool get isSupported => true;

  @override
  Future<void> start() async {
    _status.add(MicTunerStatus.starting);
    try {
      if (!await _recorder.hasPermission()) {
        _status.add(MicTunerStatus.permissionDenied);
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _status.add(MicTunerStatus.listening);
      _audioSub = stream.listen(
        _onAudio,
        onError: (_) {
          _status.add(MicTunerStatus.unavailable);
        },
      );
    } catch (_) {
      _status.add(MicTunerStatus.unavailable);
    }
  }

  void _onAudio(Uint8List bytes) {
    // PCM16 little-endian -> normalized doubles in [-1, 1].
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      _buffer.add(view.getInt16(i, Endian.little) / 32768.0);
    }
    while (_buffer.length >= _frameSamples) {
      final frame = _buffer.sublist(0, _frameSamples);
      _buffer.removeRange(0, _frameSamples);
      final hz = estimatePitch(frame, _sampleRate);
      if (hz != null) _pitches.add(PitchSample(frequencyHz: hz));
    }
  }

  @override
  Future<void> stop() async {
    await _audioSub?.cancel();
    _audioSub = null;
    _buffer.clear();
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Plugin unavailable (e.g. unit tests) or already stopped - nothing to do.
    }
    _status.add(MicTunerStatus.idle);
  }

  @override
  Future<void> dispose() async {
    await stop();
    try {
      await _recorder.dispose();
    } catch (_) {
      // Plugin unavailable (e.g. unit tests) - nothing to dispose.
    }
    await _pitches.close();
    await _status.close();
  }
}

/// Factory used by the conditional import in `mic_tuner.dart`.
MicTuner createMicTunerImpl() => _RecordMicTuner();
