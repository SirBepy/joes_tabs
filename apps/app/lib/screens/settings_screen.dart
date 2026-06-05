import 'package:flutter/material.dart';

import '../widgets/placeholder_body.dart';

/// Settings (per `docs/design/screens/settings.md`). Wireframe placeholder;
/// font settings, dark mode, tags, and log out land in a later plan.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      title: 'Settings',
      note:
          'Font settings, dark-mode toggle, my tags, and log out (later plan).',
    );
  }
}
