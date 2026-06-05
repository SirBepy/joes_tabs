import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../widgets/placeholder_body.dart';

/// Song / play-along view (per `docs/design/screens/tabs-screen.md`). Wireframe
/// placeholder; plan 08 wires it to `songProvider(id)` for chords-over-lyrics.
class SongDetailScreen extends StatelessWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PlaceholderBody(
          title: 'Song View',
          note: 'Chords-over-lyrics for song "$songId" (plan 08).',
        ),
      ),
    );
  }
}
