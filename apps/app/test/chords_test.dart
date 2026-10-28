import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/chords_screen.dart';
import 'package:joes_tabs_app/song/chord_diagram.dart';
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

    // The guided picker is the default tab: its "Sharp / Flat" strip label is
    // shown and the library's search field is not yet present.
    expect(find.text('Sharp / Flat'), findsOneWidget);
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

  testWidgets('ukulele only: no instrument picker, ukulele shapes', (
    tester,
  ) async {
    // Pump with the section header so a registered top-bar action (the old
    // instrument picker) would render, mirroring how the shell hosts it.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialSettingsOverride()],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            appBar: SectionHeader(title: 'CHORDS'),
            body: ChordsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse all'));
    await tester.pump();

    expect(find.byIcon(PhosphorIconsRegular.musicNote), findsNothing);
    expect(find.text('Guitar'), findsNothing);
    final first = tester
        .widgetList<ChordDiagram>(find.byType(ChordDiagram))
        .first;
    expect(first.instrumentSlug, ChordShapes.ukulele);
  });

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
