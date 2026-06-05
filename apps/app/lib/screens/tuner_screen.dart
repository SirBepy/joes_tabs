import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../tuner/mic_tuner.dart';
import '../tuner/pitch.dart';
import '../widgets/brand_mascot.dart';
import '../widgets/instrument_toggle.dart';

/// The open-string tuning of each supported instrument, low-to-high, matching
/// the diagram string order.
const Map<String, List<String>> _tunings = {
  ChordShapes.ukulele: ['G', 'C', 'E', 'A'],
  ChordShapes.guitar: ['E', 'A', 'D', 'G', 'B', 'E'],
};

/// Maps the instrument slug to the octave-map key used by `pitch.dart`.
String _octaveKeyFor(String slug) =>
    slug == ChordShapes.guitar ? 'guitar' : 'ukulele';

/// Cents window within which a string is considered "in tune" (pointer green).
const double _inTuneCents = 5;

/// In-tune green, matching the original bottom-pointer colour.
const Color _greenInTune = Color(0xFF3FA34D);

/// Tuner (per `docs/design/screens/tuner*.md`).
///
/// Two modes share one horizontal note strip with a fixed top target pointer
/// and a bottom pointer that goes orange -> green when in tune:
///
///  * Reference-tone mode (default, all platforms): tapping a string chip
///    selects it and settles it to in-tune, simulating the played string
///    landing on pitch. Guaranteed-working visual path.
///  * Live mic mode (web only): the "Listen" toggle requests the microphone,
///    runs autocorrelation pitch detection over each audio frame, maps the
///    detected pitch to the nearest open string and drives the bottom pointer
///    from the real signal (green within +/-5 cents). Detected note + cents are
///    shown live.
///
/// On non-web platforms live mic capture is not implemented yet
/// (see `mic_io.dart`); the toggle surfaces a friendly message and the screen
/// stays in reference-tone mode.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> {
  String _instrument = ChordShapes.ukulele;
  int _selectedString = 0;
  bool _inTune = false;
  bool _synced = false;

  // ---- Live mic state ----
  bool _micMode = false;
  MicTuner? _mic;
  StreamSubscription<PitchSample>? _pitchSub;
  StreamSubscription<MicTunerStatus>? _statusSub;
  MicTunerStatus _micStatus = MicTunerStatus.idle;

  /// Latest detected reading in mic mode (null when nothing clear is heard).
  NoteReading? _detected;

  /// Signed cents of the detected pitch from the nearest target string.
  double? _detectedCents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the instrument from the app-wide default once.
    if (!_synced) {
      _instrument = ref.read(defaultInstrumentProvider);
      _synced = true;
    }
  }

  @override
  void dispose() {
    _pitchSub?.cancel();
    _statusSub?.cancel();
    _mic?.dispose();
    super.dispose();
  }

  List<String> get _strings => _tunings[_instrument]!;

  void _selectInstrument(String slug) {
    setState(() {
      _instrument = slug;
      _selectedString = 0;
      _inTune = false;
      _detected = null;
      _detectedCents = null;
    });
  }

  /// Selecting a string targets it and (reference-tone path) settles it into
  /// tune so the bottom pointer turns green. Disabled in mic mode, where the
  /// target follows the detected pitch instead.
  void _selectString(int index) {
    if (_micMode) return;
    setState(() {
      _selectedString = index;
      _inTune = false;
    });
    // Simulate the string settling to its target pitch.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_selectedString != index) return;
      setState(() => _inTune = true);
    });
  }

  Future<void> _toggleMic() async {
    if (_micMode) {
      await _stopMic();
      return;
    }
    setState(() {
      _micMode = true;
      _inTune = false;
      _detected = null;
      _detectedCents = null;
      _micStatus = MicTunerStatus.starting;
    });

    final mic = createMicTuner();
    _mic = mic;
    _statusSub = mic.statusStream.listen(_onMicStatus);
    _pitchSub = mic.pitchStream.listen(_onPitch);
    await mic.start();
  }

  Future<void> _stopMic() async {
    await _pitchSub?.cancel();
    await _statusSub?.cancel();
    _pitchSub = null;
    _statusSub = null;
    final mic = _mic;
    _mic = null;
    await mic?.dispose();
    if (!mounted) return;
    setState(() {
      _micMode = false;
      _micStatus = MicTunerStatus.idle;
      _inTune = false;
      _detected = null;
      _detectedCents = null;
    });
  }

  void _onMicStatus(MicTunerStatus status) {
    if (!mounted) return;
    setState(() => _micStatus = status);
  }

  /// Drives the strip from a real detected pitch: snap the target to the
  /// nearest open string and flip the bottom pointer green within tolerance.
  void _onPitch(PitchSample sample) {
    if (!mounted) return;
    final reading = frequencyToNoteName(sample.frequencyHz);
    final match = nearestTargetString(
      sample.frequencyHz,
      _strings,
      _octaveKeyFor(_instrument),
    );
    if (reading == null || match == null) return;
    setState(() {
      _selectedString = match.index;
      _detected = reading;
      _detectedCents = match.cents;
      _inTune = match.cents.abs() <= _inTuneCents;
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetNote = _strings[_selectedString];

    return Column(
      children: [
        // Title now lives in the section header (AppShell); the body keeps the
        // mic toggle, pinned to the right per the mockup.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Spacer(),
              _MicToggle(active: _micMode, onTap: _toggleMic),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: InstrumentToggle(
            value: _instrument,
            onChanged: _selectInstrument,
          ),
        ),
        const Expanded(
          child: Center(
            child: BrandMascot(size: 200, icon: PhosphorIconsFill.guitar),
          ),
        ),
        // String chips row.
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
                _StringChip(
                  label: _strings[i],
                  selected: i == _selectedString,
                  onTap: () => _selectString(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Note strip with two centre pointers.
        _NoteStrip(
          notes: _strips(_strings),
          targetNote: targetNote,
          inTune: _inTune,
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusLine(
          micMode: _micMode,
          micStatus: _micStatus,
          inTune: _inTune,
          targetNote: targetNote,
          detected: _detected,
          detectedCents: _detectedCents,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// The strip scale: the instrument's open-string notes spread across the
  /// strip so the player sees the neighbouring targets too.
  List<String> _strips(List<String> strings) {
    // De-duplicate while keeping order (guitar repeats E).
    final seen = <String>{};
    final result = <String>[];
    for (final n in strings) {
      if (seen.add(n)) result.add(n);
    }
    return result;
  }
}

/// The Listen / mic toggle button (Phosphor microphone). Orange filled when
/// active, peach outline when idle.
class _MicToggle extends StatelessWidget {
  const _MicToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Stop listening' : 'Listen with microphone',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.orange : AppColors.peach,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.orange, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active
                    ? PhosphorIconsFill.microphone
                    : PhosphorIconsRegular.microphone,
                size: 18,
                color: active ? AppColors.white : AppColors.orange,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                active ? 'Stop' : 'Listen',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: active ? AppColors.white : AppColors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The status text under the strip. Shows a reference-tone prompt, a live
/// detected note + cents, or a friendly mic-error / unsupported message.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.micMode,
    required this.micStatus,
    required this.inTune,
    required this.targetNote,
    required this.detected,
    required this.detectedCents,
  });

  final bool micMode;
  final MicTunerStatus micStatus;
  final bool inTune;
  final String targetNote;
  final NoteReading? detected;
  final double? detectedCents;

  @override
  Widget build(BuildContext context) {
    // Reference-tone mode: original behaviour, unchanged.
    if (!micMode) {
      return Text(
        inTune ? 'In tune' : 'Play the $targetNote string',
        style: TextStyle(
          color: inTune ? _greenInTune : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    // Mic mode error / lifecycle states.
    switch (micStatus) {
      case MicTunerStatus.starting:
        return const Text(
          'Starting microphone...',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        );
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
              ? 'Live tuning is not available here.'
              : 'Live mic tuning is coming to this device soon. Tap a string '
                    'for a reference tone.',
        );
      case MicTunerStatus.idle:
      case MicTunerStatus.listening:
        final reading = detected;
        final cents = detectedCents;
        if (reading == null || cents == null) {
          return const Text(
            'Listening... play a string',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          );
        }
        final centsText = cents >= 0 ? '+${cents.round()}' : '${cents.round()}';
        return Text(
          inTune
              ? 'In tune: ${reading.label}'
              : '${reading.label}  $centsText cents',
          style: TextStyle(
            color: inTune ? _greenInTune : AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 16,
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

class _StringChip extends StatelessWidget {
  const _StringChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.orange : AppColors.peach,
          border: Border.all(color: AppColors.orange, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.white : AppColors.orange,
          ),
        ),
      ),
    );
  }
}

/// Horizontal note strip with two centre triangle pointers.
///
/// The top pointer (orange) marks the target centre; the bottom pointer is
/// orange while tuning and green when [inTune]. The [targetNote] label is
/// emphasised within the strip.
class _NoteStrip extends StatelessWidget {
  const _NoteStrip({
    required this.notes,
    required this.targetNote,
    required this.inTune,
  });

  final List<String> notes;
  final String targetNote;
  final bool inTune;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Column(
        children: [
          // Top target pointer (always orange, points down).
          const _Pointer(color: AppColors.orange, pointsDown: true),
          // The note labels.
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardPeach,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final n in notes)
                    Text(
                      n,
                      style: TextStyle(
                        fontWeight: n == targetNote
                            ? FontWeight.w900
                            : FontWeight.w500,
                        fontSize: n == targetNote ? 22 : 16,
                        color: n == targetNote
                            ? AppColors.orange
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Bottom in-tune pointer: orange -> green.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _Pointer(
              key: ValueKey<bool>(inTune),
              color: inTune ? _greenInTune : AppColors.orange,
              pointsDown: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single triangle pointer used at the centre of the note strip.
class _Pointer extends StatelessWidget {
  const _Pointer({super.key, required this.color, required this.pointsDown});

  final Color color;
  final bool pointsDown;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 12),
      painter: _TrianglePainter(color: color, pointsDown: pointsDown),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color, required this.pointsDown});

  final Color color;
  final bool pointsDown;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointsDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color != color || old.pointsDown != pointsDown;
}
