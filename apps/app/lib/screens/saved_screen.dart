import 'package:flutter/material.dart';

import '../widgets/placeholder_body.dart';

/// Saved tabs grid (per `docs/design/screens/saved-tabs.md`). Wireframe
/// placeholder; plan 08 fills in the favorited-song cards.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      title: 'Saved Tabs',
      note: 'Cards of favorited songs with chord-color dot swatches (plan 08).',
    );
  }
}
