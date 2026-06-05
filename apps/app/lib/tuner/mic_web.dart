/// Web microphone tuner: live pitch detection via the Web Audio API.
///
/// Pipeline:
///   navigator.mediaDevices.getUserMedia({audio:true})
///     -> MediaStreamAudioSourceNode
///     -> AnalyserNode (fftSize 2048)
///   a periodic timer (~15 fps) pulls the time-domain float buffer with
///   `getFloatTimeDomainData`, runs the pure `estimatePitch` over it, and emits
///   a [PitchSample] when a clear pitch is found.
///
/// Permission denial / missing device / init failure all resolve into a
/// [MicTunerStatus] on the status stream; nothing throws to the caller.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'mic_tuner.dart';
import 'pitch.dart';

/// Capture/analysis poll rate. ~15 fps is responsive enough for tuning while
/// keeping per-frame autocorrelation cheap.
const Duration _pollInterval = Duration(milliseconds: 66);

/// FFT size for the analyser. 2048 samples at ~44.1k is ~46 ms, enough cycles
/// to resolve a low guitar E2 (~82 Hz) reliably.
const int _fftSize = 2048;

class _WebMicTuner implements MicTuner {
  final _pitches = StreamController<PitchSample>.broadcast();
  final _status = StreamController<MicTunerStatus>.broadcast();

  web.MediaStream? _stream;
  web.AudioContext? _audioCtx;
  web.AnalyserNode? _analyser;
  web.MediaStreamAudioSourceNode? _source;
  Timer? _timer;
  Float32List? _buffer;
  bool _disposed = false;

  @override
  Stream<PitchSample> get pitchStream => _pitches.stream;

  @override
  Stream<MicTunerStatus> get statusStream => _status.stream;

  @override
  bool get isSupported => true;

  @override
  Future<void> start() async {
    if (_disposed) return;
    _status.add(MicTunerStatus.starting);

    final mediaDevices = web.window.navigator.mediaDevices;
    web.MediaStream stream;
    try {
      final constraints = web.MediaStreamConstraints(audio: true.toJS);
      stream = await mediaDevices.getUserMedia(constraints).toDart;
    } catch (e) {
      // getUserMedia rejects with NotAllowedError (denied) or NotFoundError
      // (no device). Map both into friendly states; default to unavailable.
      final name = _domErrorName(e);
      if (name == 'NotAllowedError' ||
          name == 'PermissionDeniedError' ||
          name == 'SecurityError') {
        _status.add(MicTunerStatus.permissionDenied);
      } else {
        _status.add(MicTunerStatus.unavailable);
      }
      return;
    }

    if (_disposed) {
      _stopTracks(stream);
      return;
    }

    try {
      _stream = stream;
      final ctx = web.AudioContext();
      _audioCtx = ctx;
      final analyser = ctx.createAnalyser();
      analyser.fftSize = _fftSize;
      _analyser = analyser;
      final source = ctx.createMediaStreamSource(stream);
      _source = source;
      source.connect(analyser);
      _buffer = Float32List(analyser.fftSize);

      // Some browsers start the context suspended until a user gesture; the
      // mic toggle is a gesture, so resume is safe here.
      try {
        await ctx.resume().toDart;
      } catch (_) {
        // Resume is best-effort; analysis still works if already running.
      }

      _status.add(MicTunerStatus.listening);
      _timer = Timer.periodic(_pollInterval, (_) => _analyseFrame());
    } catch (_) {
      await stop();
      _status.add(MicTunerStatus.unavailable);
    }
  }

  void _analyseFrame() {
    final analyser = _analyser;
    final buffer = _buffer;
    final ctx = _audioCtx;
    if (analyser == null || buffer == null || ctx == null) return;

    // Fill `buffer` with the current time-domain waveform in [-1, 1].
    analyser.getFloatTimeDomainData(buffer.toJS);

    final samples = List<double>.generate(
      buffer.length,
      (i) => buffer[i],
      growable: false,
    );
    final hz = estimatePitch(samples, ctx.sampleRate.round());
    if (hz != null && !_pitches.isClosed) {
      _pitches.add(PitchSample(frequencyHz: hz));
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;

    final source = _source;
    if (source != null) {
      try {
        source.disconnect();
      } catch (_) {}
      _source = null;
    }

    final stream = _stream;
    if (stream != null) {
      _stopTracks(stream);
      _stream = null;
    }

    final ctx = _audioCtx;
    if (ctx != null) {
      try {
        await ctx.close().toDart;
      } catch (_) {}
      _audioCtx = null;
    }

    _analyser = null;
    _buffer = null;
    if (!_status.isClosed) _status.add(MicTunerStatus.idle);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _pitches.close();
    await _status.close();
  }

  void _stopTracks(web.MediaStream stream) {
    final tracks = stream.getTracks();
    for (var i = 0; i < tracks.length; i++) {
      try {
        tracks.toDart[i].stop();
      } catch (_) {}
    }
  }

  /// Best-effort extraction of a DOMException `name` from a JS error.
  String? _domErrorName(Object error) {
    try {
      final jsErr = error as JSObject;
      final name = jsErr.getProperty('name'.toJS);
      if (name.isDefinedAndNotNull) {
        return (name as JSString).toDart;
      }
    } catch (_) {}
    return null;
  }
}

/// Factory used by the conditional import in `mic_tuner.dart`.
MicTuner createMicTunerImpl() => _WebMicTuner();
