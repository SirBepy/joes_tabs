import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

import 'support/settings_overrides.dart';

/// Pumps a minimal app wired exactly like [JoesTabsApp]: light + dark themes
/// with [themeMode] driven by [themeModeProvider], seeded from the persisted
/// record. A captured [BuildContext] lets the test read the active [Theme].
Future<Brightness> _pumpBrightness(
  WidgetTester tester, {
  required String themeMode,
  Brightness platformBrightness = Brightness.light,
}) async {
  late Brightness captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialSettingsOverride(themeMode: themeMode)],
      child: Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          return MediaQuery(
            data: MediaQueryData(platformBrightness: platformBrightness),
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: Builder(
                builder: (context) {
                  captured = Theme.of(context).brightness;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return captured;
}

void main() {
  testWidgets('themeMode light yields a light Theme', (tester) async {
    final brightness = await _pumpBrightness(tester, themeMode: 'light');
    expect(brightness, Brightness.light);
  });

  testWidgets('themeMode dark yields a dark Theme', (tester) async {
    final brightness = await _pumpBrightness(tester, themeMode: 'dark');
    expect(brightness, Brightness.dark);
  });

  testWidgets('themeMode system follows the platform brightness', (
    tester,
  ) async {
    final brightness = await _pumpBrightness(
      tester,
      themeMode: 'system',
      platformBrightness: Brightness.dark,
    );
    expect(brightness, Brightness.dark);
  });

  testWidgets('AppTheme.light and AppTheme.dark expose matching brightness', (
    tester,
  ) async {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(
      AppTheme.dark.colorScheme.primary,
      AppTheme.light.colorScheme.primary,
    );
  });
}
