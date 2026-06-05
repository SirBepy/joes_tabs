import 'package:flutter/material.dart';

import '../widgets/placeholder_body.dart';

/// Trending tabs list (per `docs/design/screens/trending-2.md`). Wireframe
/// placeholder; plan 08 wires it to `trendingProvider`.
class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      title: 'Trending',
      note: 'Vertical song list with search and per-row bookmark (plan 08).',
    );
  }
}
