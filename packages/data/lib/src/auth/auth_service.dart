import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase's [GoTrueClient] for email/password and Google
/// auth.
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

  /// Signs in (creating the account on first use) with a Google ID token from
  /// the platform's native Google sign-in. The token's audience must be one of
  /// the client IDs configured on Supabase's Google provider.
  Future<AuthResponse> signInWithGoogleIdToken({required String idToken}) {
    return _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// Starts the browser-redirect Google OAuth flow (web). The page navigates
  /// away to Google and comes back to [redirectTo], where Supabase picks the
  /// session up and [onAuthStateChange] fires.
  Future<bool> signInWithGoogleRedirect({String? redirectTo}) {
    return _auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirectTo);
  }

  /// Permanently deletes the signed-in user's account and its server data via
  /// the `delete_my_account` RPC (`user_favorites` cascades), then signs out.
  ///
  /// Throws only when the deletion itself fails. signOut clears the local
  /// session before it calls the server, so an error from that server call
  /// (the user no longer exists, or the network dropped) must not read as a
  /// failed deletion and prompt a retry of something that already happened.
  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_my_account');
    try {
      await _auth.signOut();
    } catch (_) {
      // Local session is already gone; see the doc comment.
    }
  }

  /// Signs the current user out. The app then falls back to anonymous mode,
  /// where local Drift favorites continue to work unchanged.
  Future<void> signOut() => _auth.signOut();
}
