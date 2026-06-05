import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/home_screen.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String email) => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: email,
  createdAt: DateTime.utc(2026).toIso8601String(),
);

Future<void> _pump(WidgetTester tester, {User? user}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (user != null) currentUserProvider.overrideWithValue(user),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('anonymous: generic welcome, no user name', (tester) async {
    await _pump(tester);
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Tap Log In to sync your tabs'), findsOneWidget);
  });

  testWidgets('signed in: greets by the email local part', (tester) async {
    await _pump(tester, user: _user('joe@example.com'));
    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('JOE!'), findsOneWidget);
  });
}
