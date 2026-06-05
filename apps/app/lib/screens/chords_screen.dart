import 'package:flutter/material.dart';

import '../widgets/placeholder_body.dart';

/// Chord-diagram library (per `docs/design/screens/chords.md`). Wireframe
/// placeholder; plan 08 builds the grouped chord-grid carousels.
class ChordsScreen extends StatelessWidget {
  const ChordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      title: 'Chords',
      note: 'Chord-diagram library grouped by root note (plan 08).',
    );
  }
}
