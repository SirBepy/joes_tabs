import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/settings_screen.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';

late WidgetRef _ref;

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              _ref = ref;
              return const SettingsScreen();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('default-instrument dropdown updates the provider', (
    tester,
  ) async {
    await _pump(tester);

    expect(_ref.read(defaultInstrumentProvider), ChordShapes.ukulele);

    // Open the dropdown and pick Guitar.
    await tester.tap(find.byKey(const Key('default-instrument-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guitar').last);
    await tester.pumpAndSettle();

    expect(_ref.read(defaultInstrumentProvider), ChordShapes.guitar);
  });

  testWidgets('font size stepper updates the provider when expanded', (
    tester,
  ) async {
    await _pump(tester);

    expect(_ref.read(fontSizeProvider), 20);

    // Expand the font settings group.
    await tester.tap(find.text('FONT SETTINGS'));
    await tester.pump();

    await tester.tap(find.byTooltip('Increase font size'));
    await tester.pump();
    expect(_ref.read(fontSizeProvider), 21);

    await tester.tap(find.byTooltip('Decrease font size'));
    await tester.pump();
    expect(_ref.read(fontSizeProvider), 20);
  });

  testWidgets('dark mode toggle updates the provider', (tester) async {
    await _pump(tester);

    expect(_ref.read(darkModeProvider), isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(_ref.read(darkModeProvider), isTrue);
  });
}
