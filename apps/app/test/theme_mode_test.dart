import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

/// Pumps a minimal app wired exactly like [JoesTabsApp]: light + dark themes
/// with [themeMode] driven by [darkModeProvider]. A captured [BuildContext] lets
/// the test read the active [Theme]'s brightness.
Future<Brightness> _pumpBrightness(
  WidgetTester tester, {
  required bool dark,
}) async {
  late Brightness captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [darkModeProvider.overrideWith((ref) => dark)],
      child: Consumer(
        builder: (context, ref, _) {
          final isDark = ref.watch(darkModeProvider);
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: Builder(
              builder: (context) {
                captured = Theme.of(context).brightness;
                return const SizedBox.shrink();
              },
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
  testWidgets('darkModeProvider false yields a light Theme', (tester) async {
    final brightness = await _pumpBrightness(tester, dark: false);
    expect(brightness, Brightness.light);
  });

  testWidgets('darkModeProvider true yields a dark Theme', (tester) async {
    final brightness = await _pumpBrightness(tester, dark: true);
    expect(brightness, Brightness.dark);
  });

  testWidgets('AppTheme.light and AppTheme.dark expose matching brightness', (
    tester,
  ) async {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    // Brand accent (orange) survives into dark mode.
    expect(
      AppTheme.dark.colorScheme.primary,
      AppTheme.light.colorScheme.primary,
    );
  });
}
