import 'dart:convert';

import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A signed-in session to delete. The client never verifies the token, so any
/// string stands in for a real JWT.
final _sessionJson = jsonEncode({
  'access_token': 'token-1',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'refresh-1',
  'user': {
    'id': 'user-1',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-01-01T00:00:00Z',
  },
});

const _rpcPath = '/rest/v1/rpc/delete_my_account';
const _logoutPath = '/auth/v1/logout';

/// A signed-in [SupabaseClient] whose HTTP calls are answered by [statusFor]
/// (keyed by request path) and recorded in [calls].
Future<SupabaseClient> _client(
  List<String> calls,
  int Function(String path) statusFor,
) async {
  final client = SupabaseClient(
    'http://localhost:54321',
    'anon-key',
    httpClient: MockClient((request) async {
      calls.add(request.url.path);
      final status = statusFor(request.url.path);
      final body = status < 300 ? '' : jsonEncode({'message': 'boom'});
      return http.Response(
        body,
        status,
        headers: {'content-type': 'application/json'},
        // postgrest reads the request back off the response.
        request: request,
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.setInitialSession(_sessionJson);
  return client;
}

void main() {
  test('deleteAccount calls the RPC, then clears the session', () async {
    final calls = <String>[];
    final client = await _client(calls, (_) => 204);

    await AuthService(client).deleteAccount();

    expect(calls, [_rpcPath, _logoutPath]);
    expect(client.auth.currentSession, isNull);
  });

  test(
    'a failed server sign-out after deletion still counts as deleted',
    () async {
      final calls = <String>[];
      final client = await _client(
        calls,
        (path) => path == _logoutPath ? 500 : 204,
      );

      await AuthService(client).deleteAccount();

      expect(calls, [_rpcPath, _logoutPath]);
      expect(client.auth.currentSession, isNull);
    },
  );

  test('a failed RPC throws and keeps the user signed in', () async {
    final calls = <String>[];
    final client = await _client(calls, (path) => path == _rpcPath ? 500 : 204);

    await expectLater(AuthService(client).deleteAccount(), throwsA(anything));

    expect(calls, [_rpcPath]);
    expect(client.auth.currentSession, isNotNull);
  });
}
