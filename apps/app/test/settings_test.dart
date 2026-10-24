import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/settings_screen.dart';
import 'package:joes_tabs_app/state/settings_provider.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

final _user = User(
  id: 'user-1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

/// Pumps Settings signed in as [_user] with [auth] behind [authServiceProvider].
Future<void> _pumpSignedIn(WidgetTester tester, AuthService auth) => _pump(
  tester,
  extraOverrides: [
    currentUserProvider.overrideWithValue(_user),
    authServiceProvider.overrideWithValue(auth),
  ],
);

Future<void> _openDeleteDialog(WidgetTester tester) async {
  final row = find.byKey(const Key('delete-account-row'));
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  List<String>? instrumentSlugs,
  List<Override> extraOverrides = const [],
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
  testWidgets('renders the 3-way theme selector and instrument multi-select', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('theme-mode-selector')), findsOneWidget);
    expect(find.byKey(const Key('instruments-multiselect')), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Ukulele'), findsOneWidget);
    expect(find.text('Guitar'), findsOneWidget);
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

  testWidgets('instrument multi-select adds and removes (min one enforced)', (
    tester,
  ) async {
    // Start with only ukulele so the toggle starts single-selected.
    await _pump(tester, instrumentSlugs: const [ChordShapes.ukulele]);

    expect(_ref.read(instrumentsProvider), {ChordShapes.ukulele});

    // Tapping the only selected chip must NOT clear it (min-one rule).
    await tester.tap(find.byKey(const Key('instrument-chip-ukulele')));
    await tester.pump();
    expect(_ref.read(instrumentsProvider), {ChordShapes.ukulele});

    // Adding guitar selects both.
    await tester.tap(find.byKey(const Key('instrument-chip-guitar')));
    await tester.pump();
    expect(_ref.read(instrumentsProvider), {
      ChordShapes.ukulele,
      ChordShapes.guitar,
    });

    final record = await AppSettingsRepository(_db).read();
    expect(record.instrumentSlugs.toSet(), {
      ChordShapes.ukulele,
      ChordShapes.guitar,
    });
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
}
