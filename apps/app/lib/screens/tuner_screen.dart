import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';
import '../widgets/instrument_toggle.dart';

/// The open-string tuning of each supported instrument, low-to-high, matching
/// the diagram string order.
const Map<String, List<String>> _tunings = {
  ChordShapes.ukulele: ['G', 'C', 'E', 'A'],
  ChordShapes.guitar: ['E', 'A', 'D', 'G', 'B', 'E'],
};

/// Tuner (per `docs/design/screens/tuner*.md`).
///
/// WIREFRAME + REFERENCE-TONE behaviour. There is no circular dial: tuning
/// feedback is a horizontal note strip with two centre triangle pointers (a
/// fixed top target pointer and a bottom pointer that goes orange -> green when
/// in tune). The mascot is the centrepiece.
///
/// Tuning model for this plan: tapping a string chip selects it as the target
/// note and arms a short "settling" animation that slides the strip to centre
/// and flips the bottom pointer to green, simulating the played string landing
/// in tune. This is the guaranteed-working path.
///
/// TODO: live mic pitch detection. Real-time pitch from the microphone is
/// intentionally NOT wired up here. On Flutter web a mic + FFT pitch tracker is
/// fragile (permissions, AudioWorklet, autoplay gating), so rather than ship
/// something flaky this screen provides the visual strip + reference-tone state
/// and leaves the detected-pitch source as a stub for a later native pass.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the instrument from the app-wide default once.
    if (!_synced) {
      _instrument = ref.read(defaultInstrumentProvider);
      _synced = true;
    }
  }

  List<String> get _strings => _tunings[_instrument]!;

  void _selectInstrument(String slug) {
    setState(() {
      _instrument = slug;
      _selectedString = 0;
      _inTune = false;
    });
  }

  /// Selecting a string targets it and (reference-tone path) settles it into
  /// tune so the bottom pointer turns green. A real implementation would gate
  /// the green state on detected pitch landing in tolerance.
  void _selectString(int index) {
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

  @override
  Widget build(BuildContext context) {
    final targetNote = _strings[_selectedString];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TUNER',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: 1.5,
              ),
            ),
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
        Text(
          _inTune ? 'In tune' : 'Play the $targetNote string',
          style: TextStyle(
            color: _inTune ? const Color(0xFF3FA34D) : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
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
              color: inTune ? const Color(0xFF3FA34D) : AppColors.orange,
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
