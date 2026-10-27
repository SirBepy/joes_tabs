import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/chords/chord_library_view.dart';
import 'package:joes_tabs_app/screens/chords/chord_picker_view.dart';
import 'package:joes_tabs_app/screens/onboarding/onboarding_screen.dart';
import 'package:joes_tabs_app/screens/thank_you_screen.dart';
import 'package:joes_tabs_app/theme/app_colors.dart';
import 'package:joes_tabs_app/theme/app_palette.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/tuner/pitch.dart';
import 'package:joes_tabs_app/tuner/tuner_gauge.dart';
import 'package:models/models.dart';

import 'support/settings_overrides.dart';

Future<void> _pump(WidgetTester tester, ThemeData theme, Widget home) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride(instrumentSlugs: const [])],
      child: MaterialApp(theme: theme, home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

bool _hasColoredContainer(WidgetTester tester, Color color) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .any(
        (c) =>
            c.color == color ||
            (c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == color),
      );
}

const _gauge = TunerGauge(
  centerNote: 'G',
  cents: 0,
  zone: TuneZone.green,
  isInTune: true,
  active: true,
);

void main() {
  group('tuner gauge', () {
    testWidgets('dark: ruler track follows the palette chip', (tester) async {
      await _pump(tester, AppTheme.dark, const Scaffold(body: _gauge));
      expect(_hasColoredContainer(tester, AppPalette.dark.chip), isTrue);
    });

    testWidgets('light: ruler track keeps its original peach', (tester) async {
      await _pump(tester, AppTheme.light, const Scaffold(body: _gauge));
      expect(_hasColoredContainer(tester, const Color(0xFFF6E2D4)), isTrue);
    });

    testWidgets('dark: non-target note labels use the palette ink', (
      tester,
    ) async {
      await _pump(tester, AppTheme.dark, const Scaffold(body: _gauge));
      final label = tester.widget<Text>(find.text('A').first);
      expect(label.style?.color, AppPalette.dark.ink.withValues(alpha: 0.55));
    });
  });

  group('chord picker', () {
    const picker = Scaffold(
      body: ChordPickerView(instrumentSlug: ChordShapes.ukulele),
    );

    testWidgets('dark: result card, family strip and unselected text', (
      tester,
    ) async {
      await _pump(tester, AppTheme.dark, picker);
      expect(_hasColoredContainer(tester, AppPalette.dark.card), isTrue);
      expect(_hasColoredContainer(tester, AppPalette.dark.chip), isTrue);
      expect(_textColor(tester, 'Minor'), AppPalette.dark.ink);
    });

    testWidgets('light: values are the original constants', (tester) async {
      await _pump(tester, AppTheme.light, picker);
      expect(_hasColoredContainer(tester, AppColors.cardPeach), isTrue);
      expect(_hasColoredContainer(tester, AppColors.peach), isTrue);
      expect(_textColor(tester, 'Minor'), AppColors.textDark);
    });
  });

  group('chord library search field', () {
    testWidgets('dark: typed text, hint and icon stay dark on the white fill', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTheme.dark,
        const Scaffold(body: ChordLibraryView(instrument: ChordShapes.ukulele)),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style?.color, AppColors.textDark);
      expect(field.decoration?.fillColor, AppColors.white);
      expect(field.decoration?.hintStyle?.color, AppColors.textMuted);
      expect((field.decoration?.prefixIcon as Icon).color, AppColors.textMuted);
    });
  });

  group('thank you screen', () {
    testWidgets('dark: background and caption follow the palette', (
      tester,
    ) async {
      await _pump(tester, AppTheme.dark, const ThankYouScreen());
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppPalette.dark.chip,
      );
      expect(
        _textColor(tester, 'Tap anywhere to continue'),
        AppPalette.dark.mutedInk,
      );
      // The white bubble keeps dark text in both themes.
      expect(_textColor(tester, 'Glad to have you here!'), AppColors.textDark);
    });

    testWidgets('light: original peach and muted caption', (tester) async {
      await _pump(tester, AppTheme.light, const ThankYouScreen());
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.peach,
      );
      expect(
        _textColor(tester, 'Tap anywhere to continue'),
        AppColors.textMuted,
      );
    });
  });

  group('onboarding', () {
    const welcome = 'Chord sheets for ukulele and guitar, made simple.';

    testWidgets('dark: welcome copy uses muted ink on the dark scaffold', (
      tester,
    ) async {
      await _pump(tester, AppTheme.dark, const OnboardingScreen());
      expect(_textColor(tester, welcome), AppPalette.dark.mutedInk);
      // No hard-coded background: the dark theme's scaffold colour applies.
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        isNull,
      );
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkBackground);
      // Inactive progress dots take the chip colour.
      expect(_hasColoredContainer(tester, AppPalette.dark.chip), isTrue);
    });

    testWidgets('light: muted copy and cream scaffold are unchanged', (
      tester,
    ) async {
      await _pump(tester, AppTheme.light, const OnboardingScreen());
      expect(_textColor(tester, welcome), AppColors.textMuted);
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.cream);
      expect(_hasColoredContainer(tester, AppColors.peach), isTrue);
    });
  });
}
