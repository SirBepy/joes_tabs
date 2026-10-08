import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/auth/google_sign_in_flow.dart';

void main() {
  setUp(GoogleSignInFlow.resetInitialization);

  test('a failed initialize is retried on the next attempt', () async {
    var calls = 0;
    Future<void> failing() async {
      calls++;
      throw StateError('network down');
    }

    Future<void> succeeding() async => calls++;

    await expectLater(
      GoogleSignInFlow.ensureInitialized(failing),
      throwsStateError,
    );
    await GoogleSignInFlow.ensureInitialized(succeeding);
    expect(calls, 2);
  });

  test('a successful initialize runs only once', () async {
    var calls = 0;
    Future<void> succeeding() async => calls++;

    await GoogleSignInFlow.ensureInitialized(succeeding);
    await GoogleSignInFlow.ensureInitialized(succeeding);
    expect(calls, 1);
  });
}
