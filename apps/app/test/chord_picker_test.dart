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
  testWidgets('composes a chord symbol from the four strips', (tester) async {
    await _pump(tester);

    // Default is C major: the result card shows the bare root.
    expect(find.text('C'), findsWidgets);

    // Pick the Minor family, then the m7 type -> Cm7.
    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('m7'));
    await tester.pumpAndSettle();
    expect(find.text('Cm7'), findsWidgets);

    // Sharpen the root -> C#m7.
    await tester.tap(find.text('♯'));
    await tester.pumpAndSettle();
    expect(find.text('C#m7'), findsWidgets);
  });
}
