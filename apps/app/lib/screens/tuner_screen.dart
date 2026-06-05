import 'package:flutter/material.dart';

import '../widgets/placeholder_body.dart';

/// Tuner utility (per `docs/design/screens/tuner.md`). Wireframe placeholder;
/// the listening/pitch UI lands in a later plan.
class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      title: 'Tuner',
      note: 'Note strip, mascot centerpiece, and tuning pointer (later plan).',
    );
  }
}
