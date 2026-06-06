import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/chords_screen.dart';
import 'package:joes_tabs_app/song/chord_diagram.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride()],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ChordsScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders chord diagrams grouped by root', (tester) async {
    await _pump(tester);

    // The "CHORDS" bubble title now lives in the section header (AppShell),
    // not the screen body. Here the body is pumped bare, so assert on the body
    // content it owns: the diagram cards and the root-note section headers.
    expect(find.byType(ChordDiagram), findsWidgets);
    // The C root section header is present.
    expect(find.text('C'), findsWidgets);
  });

  testWidgets(
    'instrument toggle swaps the shape set and updates the provider',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialSettingsOverride()],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const ChordsScreen();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(capturedRef.read(selectedInstrumentProvider), ChordShapes.ukulele);

      // The first ukulele card uses 4 strings; switch to guitar.
      final firstBefore = tester
          .widgetList<ChordDiagram>(find.byType(ChordDiagram))
          .first;
      expect(firstBefore.instrumentSlug, ChordShapes.ukulele);

      await tester.tap(find.text('Guitar'));
      await tester.pump();

      expect(capturedRef.read(selectedInstrumentProvider), ChordShapes.guitar);
      final firstAfter = tester
          .widgetList<ChordDiagram>(find.byType(ChordDiagram))
          .first;
      expect(firstAfter.instrumentSlug, ChordShapes.guitar);
    },
  );

  testWidgets('search filters the chord list by name', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'Am');
    await tester.pump();

    final cards = tester
        .widgetList<ChordDiagram>(find.byType(ChordDiagram))
        .map((c) => c.chord)
        .toList();
    expect(cards, isNotEmpty);
    // Every visible card now matches the query.
    expect(cards.every((c) => c.toLowerCase().contains('am')), isTrue);
  });
}
