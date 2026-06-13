import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/chords/chord_picker_view.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride(maximalChords: false)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ChordPickerView(instrumentSlug: ChordShapes.ukulele),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('composes a chord symbol via the family tabs + type list', (
    tester,
  ) async {
    await _pump(tester);

    // Default is C major: the result card shows the bare root.
    expect(find.text('C'), findsWidgets);

    // The default (Major) family list shows no Minor-family chords yet, so the
    // only "Minor" on screen is the family tab. Tap it to switch families.
    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();

    // Now the Minor family's chord rows are listed; tap the m7 row -> Cm7.
    await tester.tap(find.text('m7'));
    await tester.pumpAndSettle();
    expect(find.text('Cm7'), findsWidgets);

    // Sharpen the root -> C#m7.
    await tester.tap(find.text('♯'));
    await tester.pumpAndSettle();
    expect(find.text('C#m7'), findsWidgets);
  });
}
