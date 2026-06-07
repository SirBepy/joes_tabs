import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../tuner/mic_tuner.dart';
import '../tuner/pitch.dart';
import '../tuner/tone_player.dart';
import '../tuner/tuner_engine.dart';
import '../tuner/tuner_gauge.dart';
import '../widgets/brand_mascot.dart';
import '../widgets/instrument_toggle.dart';

/// Open-string tuning of each supported instrument, low-to-high.
const Map<String, List<String>> _tunings = {
  ChordShapes.ukulele: ['G', 'C', 'E', 'A'],
  ChordShapes.guitar: ['E', 'A', 'D', 'G', 'B', 'E'],
};

String _octaveKeyFor(String slug) =>
    slug == ChordShapes.guitar ? 'guitar' : 'ukulele';

/// How often the engine is advanced. The mic only emits on a clear pitch, so the
/// ticker supplies the steady frame cadence the engine needs to count silence.
const Duration _tick = Duration(milliseconds: 66);

/// Always-on mic tuner. Auto-detects which open string is being played, shows it
/// on the sliding chromatic gauge, and color-codes how in-tune it is. The string
/// chips play a sampled-pluck reference tone for tuning by ear.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> {
  String _instrument = ChordShapes.ukulele;

  MicTuner? _mic;
  StreamSubscription<PitchSample>? _pitchSub;
  StreamSubscription<MicTunerStatus>? _statusSub;
  MicTunerStatus _micStatus = MicTunerStatus.idle;

  late TunerEngine _engine = _buildEngine(_instrument);
  Timer? _ticker;
  double? _pendingHz; // most recent pitch since the last tick
  bool _suppressMic = false; // true while a reference tone is playing
  TunerState _state = const TunerState();

  final TonePlayer _tonePlayer = TonePlayer();

  List<String> get _strings => _tunings[_instrument]!;

  TunerEngine _buildEngine(String slug) => TunerEngine(
    stringFrequencies: openStringFrequencies(
      _tunings[slug]!,
      _octaveKeyFor(slug),
    ),
  );

  @override
  void initState() {
    super.initState();
    _startMic();
    _ticker = Timer.periodic(_tick, (_) => _onTick());
  }

  Future<void> _startMic() async {
    final mic = createMicTuner();
    _mic = mic;
    _statusSub = mic.statusStream.listen((s) {
      if (mounted) setState(() => _micStatus = s);
    });
    _pitchSub = mic.pitchStream.listen((sample) {
      if (!_suppressMic) _pendingHz = sample.frequencyHz;
    });
    await mic.start();
  }

  void _onTick() {
    final hz = _suppressMic ? null : _pendingHz;
    _pendingHz = null;
    final next = _engine.update(hz);
    final justInTune = next.isInTune && !_state.isInTune;
    if (mounted) setState(() => _state = next);
    if (justInTune) HapticFeedback.lightImpact();
  }

  Future<void> _playTone(int index) async {
    setState(() => _suppressMic = true);
    _engine.reset();
    await _tonePlayer.play(_instrument, index);
    Timer(TonePlayer.clipDuration + const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _suppressMic = false);
    });
  }

  void _selectInstrument(String slug) {
    ref.read(selectedInstrumentProvider.notifier).state = slug;
  }

  void _applyInstrument(String slug) {
    if (_instrument == slug) return;
    _instrument = slug;
    _engine = _buildEngine(slug);
    _state = const TunerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pitchSub?.cancel();
    _statusSub?.cancel();
    _mic?.dispose();
    _tonePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPicker = ref.watch(showInstrumentPickerProvider);
    _applyInstrument(
      showPicker
          ? ref.watch(selectedInstrumentProvider)
          : ref.watch(instrumentsProvider).first,
    );

    final lockedIndex = _state.lockedIndex;
    final centerNote = lockedIndex != null
        ? _strings[lockedIndex]
        : _strings[0];
    // Active (showing a reading) as long as a string is locked - the reading
    // stays frozen on screen through the silence after a pluck decays, rather
    // than blanking the moment the signal drops.
    final active = lockedIndex != null;

    return Column(
      children: [
        if (showPicker)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: InstrumentToggle(
              value: _instrument,
              onChanged: _selectInstrument,
            ),
          ),
        const Expanded(
          child: Center(
            child: BrandMascot(size: 180, icon: PhosphorIconsFill.guitar),
          ),
        ),
        TunerGauge(
          centerNote: centerNote,
          cents: _state.cents,
          octave: _state.octave,
          zone: _state.zone,
          isInTune: _state.isInTune,
          active: active,
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusLine(micStatus: _micStatus, active: active),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < _strings.length; i++)
                _StringChip(label: _strings[i], onTap: () => _playTone(i)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Status / messaging under the gauge. Shows listening prompts and friendly mic
/// errors; the live note + cents now live in the gauge itself.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.micStatus, required this.active});

  final MicTunerStatus micStatus;
  final bool active;

  @override
  Widget build(BuildContext context) {
    switch (micStatus) {
      case MicTunerStatus.permissionDenied:
        return const _Friendly(
          'Microphone blocked. Allow mic access, or tap a string for a '
          'reference tone.',
        );
      case MicTunerStatus.unavailable:
        return const _Friendly(
          'No microphone found. Tap a string for a reference tone instead.',
        );
      case MicTunerStatus.unsupported:
        return _Friendly(
          kIsWeb
              ? 'Live tuning is not available here. Tap a string for a '
                    'reference tone.'
              : 'Live mic tuning is unavailable. Tap a string for a reference '
                    'tone.',
        );
      case MicTunerStatus.idle:
      case MicTunerStatus.starting:
      case MicTunerStatus.listening:
        return Text(
          active ? 'Hold steady...' : 'Listening... play a string',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        );
    }
  }
}

class _Friendly extends StatelessWidget {
  const _Friendly(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A reference-tone chip. Tapping plays that open string's sampled pluck.
class _StringChip extends StatelessWidget {
  const _StringChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play $label reference tone',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.peach,
            border: Border.all(color: AppColors.orange, width: 2),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ),
      ),
    );
  }
}
