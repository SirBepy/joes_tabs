import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/tuner_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride()],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TunerScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows ukulele open strings G C E A by default', (tester) async {
    await _pump(tester);
    for (final note in ['G', 'C', 'E', 'A']) {
      expect(find.text(note), findsWidgets);
    }
  });

  testWidgets('switching to guitar swaps the note set to include D and B', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Guitar'));
    await tester.pump();
    expect(find.text('D'), findsWidgets);
    expect(find.text('B'), findsWidgets);
  });

  test('tunings cover both instruments', () {
    expect(ChordShapes.namesFor(ChordShapes.ukulele), isNotEmpty);
    expect(ChordShapes.namesFor(ChordShapes.guitar), isNotEmpty);
  });
}
