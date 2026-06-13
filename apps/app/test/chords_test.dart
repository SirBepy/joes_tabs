import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/chords_screen.dart';
import 'package:joes_tabs_app/song/chord_diagram.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/app_shell.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  testWidgets('defaults to the Pick tab and toggles to Browse all', (
    tester,
  ) async {
    await _pump(tester);

    // The guided picker is the default tab: its "Family" strip label is shown
    // and the library's search field is not yet present.
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Search chords'), findsNothing);

    // Switch to Browse all -> the library search field appears.
    await tester.tap(find.text('Browse all'));
    await tester.pump();
    expect(find.text('Search chords'), findsOneWidget);

    // Switch back to Pick -> the search field is gone again.
    await tester.tap(find.text('Pick'));
    await tester.pump();
    expect(find.text('Search chords'), findsNothing);
  });

  testWidgets('Browse all renders chord diagrams grouped by root', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Browse all'));
    await tester.pump();

    expect(find.byType(ChordDiagram), findsWidgets);
    // The C root section header is present.
    expect(find.text('C'), findsWidgets);
  });

  testWidgets(
    'top-bar instrument dropdown swaps the shape set and updates the provider',
    (tester) async {
      late WidgetRef capturedRef;
      // Pump the screen with the section header so its registered top-bar action
      // (the instrument picker) renders, mirroring how the shell hosts it.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialSettingsOverride()],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              appBar: const SectionHeader(title: 'CHORDS'),
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
      // Settle the post-frame action registration.
      await tester.pumpAndSettle();

      // Switch to Browse all so chord diagrams are on screen.
      await tester.tap(find.text('Browse all'));
      await tester.pump();

      expect(capturedRef.read(selectedInstrumentProvider), ChordShapes.ukulele);

      // The first card is a ukulele shape; switch to guitar via the dropdown.
      final firstBefore = tester
          .widgetList<ChordDiagram>(find.byType(ChordDiagram))
          .first;
      expect(firstBefore.instrumentSlug, ChordShapes.ukulele);

      // The top-bar action shows the current instrument's icon; tapping it opens
      // the popup of [icon] Name rows.
      await tester.tap(find.byIcon(PhosphorIconsRegular.musicNote));
      await tester.pumpAndSettle();

      // Pick Guitar from the menu.
      await tester.tap(find.text('Guitar').last);
      await tester.pumpAndSettle();

      expect(capturedRef.read(selectedInstrumentProvider), ChordShapes.guitar);
      final firstAfter = tester
          .widgetList<ChordDiagram>(find.byType(ChordDiagram))
          .first;
      expect(firstAfter.instrumentSlug, ChordShapes.guitar);
    },
  );

  testWidgets('Browse all search filters the chord list by name', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Browse all'));
    await tester.pump();

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
