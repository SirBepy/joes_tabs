import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/settings_screen.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_palette.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';

import 'login_form_test.dart' show testUser;
import 'support/settings_overrides.dart';

late WidgetRef _ref;
late AppDatabase _db;

/// Records account deletions; every other [AuthService] member is unused here.
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.failDelete = false});

  final bool failDelete;
  int deleteCalls = 0;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (failDelete) throw Exception('offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps Settings signed in as [testUser] with [auth] behind [authServiceProvider].
Future<void> _pumpSignedIn(WidgetTester tester, AuthService auth) => _pump(
  tester,
  extraOverrides: [
    currentUserProvider.overrideWithValue(testUser),
    authServiceProvider.overrideWithValue(auth),
  ],
);

Future<void> _openDeleteDialog(WidgetTester tester) async {
  final row = find.byKey(const Key('delete-account-row'));
  // The lazy list hasn't built the last rows yet; scroll them into existence.
  await tester.scrollUntilVisible(row, 200);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  List<String>? instrumentSlugs,
  List<Override> extraOverrides = const [],
  ThemeData? theme,
}) async {
  _db = inMemoryAppDatabase();
  addTearDown(_db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseOverride(_db),
        initialSettingsOverride(instrumentSlugs: instrumentSlugs),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
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
  testWidgets('renders the 3-way theme selector and no instrument choice', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('theme-mode-selector')), findsOneWidget);
    expect(find.byKey(const Key('instruments-multiselect')), findsNothing);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Guitar'), findsNothing);
  });

  testWidgets('theme selector updates and persists the provider', (
    tester,
  ) async {
    await _pump(tester);

    expect(_ref.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(_ref.read(themeModeProvider), ThemeMode.dark);
    // Wrote through to the repository.
    final record = await AppSettingsRepository(_db).read();
    expect(record.themeMode, 'dark');
  });

  testWidgets('font size stepper updates and persists the provider', (
    tester,
  ) async {
    await _pump(tester);

    expect(_ref.read(fontSizeProvider), 20);

    await tester.tap(find.text('FONT SETTINGS'));
    await tester.pump();

    await tester.tap(find.byTooltip('Increase font size'));
    await tester.pump();
    expect(_ref.read(fontSizeProvider), 21);

    final record = await AppSettingsRepository(_db).read();
    expect(record.fontSize, 21);
  });

  testWidgets('maximal-chords toggle persists', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    final sw = find.byKey(const Key('maximal-chords-switch'));
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(sw).value, isTrue);
  });

  testWidgets('Delete Account is hidden while signed out', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('delete-account-row')), findsNothing);
  });

  testWidgets('cancelling the delete dialog keeps the account', (tester) async {
    final auth = _FakeAuthService();
    await _pumpSignedIn(tester, auth);

    await _openDeleteDialog(tester);
    expect(find.textContaining('Delete your account?'), findsOneWidget);
    await tester.tap(find.text('NOPE!'));
    await tester.pumpAndSettle();

    expect(auth.deleteCalls, 0);
  });

  testWidgets('confirming the delete dialog deletes the account', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    await _pumpSignedIn(tester, auth);

    await _openDeleteDialog(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('DELETE ACCOUNT'),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.deleteCalls, 1);
    expect(find.text('Account deleted.'), findsOneWidget);
  });

  testWidgets('a failed deletion tells the user to retry', (tester) async {
    final auth = _FakeAuthService(failDelete: true);
    await _pumpSignedIn(tester, auth);

    await _openDeleteDialog(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('DELETE ACCOUNT'),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.deleteCalls, 1);
    expect(find.textContaining("Couldn't delete your account"), findsOneWidget);
  });

  group('dark palette', () {
    testWidgets('headings and rows resolve the dark tokens', (tester) async {
      await _pump(tester, theme: AppTheme.dark);
      await tester.pumpAndSettle();

      Color? ink(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      expect(ink('THEME'), AppPalette.dark.ink);
      expect(ink('MAXIMAL CHORDS'), AppPalette.dark.ink);
      expect(ink('FONT SETTINGS'), AppPalette.dark.ink);
    });

    testWidgets('the log-out dialog sits on the dark card with ink text', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: AppTheme.dark,
        extraOverrides: [
          currentUserProvider.overrideWithValue(testUser),
          authServiceProvider.overrideWithValue(_FakeAuthService()),
        ],
      );
      await tester.tap(find.byKey(const Key('account-log-out')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
        AppPalette.dark.card,
      );
      final message = tester.widget<Text>(
        find.text('Are you sure you want to log out?'),
      );
      expect(message.style?.color, AppPalette.dark.ink);
    });
  });
}
