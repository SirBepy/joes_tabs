import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase's [GoTrueClient] for email/password auth.
///
/// Kept deliberately small and provider-free so it is trivially mockable in
/// tests: the app talks to this surface, never to `supabase.auth` directly.
/// Anonymous use needs no [AuthService] at all - accounts are optional in v1.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// The signed-in [User], or null when anonymous / logged out.
  User? get currentUser => _auth.currentUser;

  /// The signed-in user's email, or null when anonymous / logged out.
  String? get currentEmail => _auth.currentUser?.email;

  /// Emits on every auth transition (sign-in, sign-out, token refresh). The UI
  /// layer maps each event to the current [User] (or null) for the greeting and
  /// the drawer's logged-in state.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Creates an account with [email] + [password] and signs the new user in.
  ///
  /// Local Supabase has email confirmations disabled (see supabase/config.toml
  /// `[auth.email] enable_confirmations = false`) so the returned session is
  /// immediately usable. Throws [AuthException] on failure (weak password,
  /// already-registered email, etc.) for the caller to surface.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _auth.signUp(email: email.trim(), password: password);
  }

  /// Signs an existing user in with [email] + [password]. Throws
  /// [AuthException] on bad credentials.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Signs the current user out. The app then falls back to anonymous mode,
  /// where local Drift favorites continue to work unchanged.
  Future<void> signOut() => _auth.signOut();
}
