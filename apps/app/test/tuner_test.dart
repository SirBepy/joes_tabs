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
  testWidgets('shows ukulele target notes G C E A by default', (tester) async {
    await _pump(tester);

    // Each open string appears as a chip and on the strip.
    for (final note in ['G', 'C', 'E', 'A']) {
      expect(find.text(note), findsWidgets);
    }
    // Default prompt targets the first string (G).
    expect(find.text('Play the G string'), findsOneWidget);
    expect(find.text('In tune'), findsNothing);
  });

  testWidgets('switching to guitar changes the target notes to E A D G B', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Guitar'));
    await tester.pump();

    // Guitar-only notes D and B now appear; prompt resets to the low-E string.
    expect(find.text('D'), findsWidgets);
    expect(find.text('B'), findsWidgets);
    expect(find.text('Play the E string'), findsOneWidget);
  });

  testWidgets('selecting a string settles it to in-tune (reference tone)', (
    tester,
  ) async {
    await _pump(tester);

    // Tap the C string chip (target becomes C).
    await tester.tap(find.widgetWithText(InkWell, 'C').first);
    await tester.pump();
    expect(find.text('Play the C string'), findsOneWidget);

    // After the settling delay the bottom pointer flips to in-tune.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('In tune'), findsOneWidget);
  });

  test('tunings cover both instruments', () {
    // Sanity on the model: shapes exist for both instruments the tuner targets.
    expect(ChordShapes.namesFor(ChordShapes.ukulele), isNotEmpty);
    expect(ChordShapes.namesFor(ChordShapes.guitar), isNotEmpty);
  });
}
