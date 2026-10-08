import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of a [GoogleSignInFlow.signIn] attempt.
enum GoogleSignInResult {
  /// A Supabase session now exists.
  signedIn,

  /// The page is navigating to Google (web); the session arrives on return.
  redirecting,

  /// The user closed the account picker.
  cancelled,
}

/// Google sign-in per platform: Android uses the native account picker and
/// hands its ID token to Supabase; web uses Supabase's browser redirect, since
/// `google_sign_in`'s `authenticate()` is unsupported there.
class GoogleSignInFlow {
  GoogleSignInFlow(this._auth);

  final AuthService _auth;

  static Future<void>? _initialized;

  /// Runs [initialize] once per app session. A failed attempt is forgotten so
  /// the next tap retries, instead of replaying the cached error until restart.
  @visibleForTesting
  static Future<void> ensureInitialized(Future<void> Function() initialize) {
    return _initialized ??= initialize().catchError((
      Object error,
      StackTrace stack,
    ) {
      _initialized = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  @visibleForTesting
  static void resetInitialization() => _initialized = null;

  /// Web needs no client ID in the app (Supabase holds it). Android needs the
  /// web client ID as the token audience. iOS is not wired yet: it needs its
  /// own OAuth client plus Info.plist URL-scheme entries.
  static bool get isAvailable =>
      kIsWeb ||
      (defaultTargetPlatform == TargetPlatform.android &&
          Env.googleWebClientId.isNotEmpty);

  Future<GoogleSignInResult> signIn() async {
    if (kIsWeb) {
      // Back to the current page without the query, so a stale ?code= from a
      // previous attempt is not replayed.
      final redirectTo = '${Uri.base.origin}${Uri.base.path}';
      await _auth.signInWithGoogleRedirect(redirectTo: redirectTo);
      return GoogleSignInResult.redirecting;
    }

    final google = GoogleSignIn.instance;
    await ensureInitialized(
      () => google.initialize(serverClientId: Env.googleWebClientId),
    );
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInResult.cancelled;
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token.');
    }
    await _auth.signInWithGoogleIdToken(idToken: idToken);
    return GoogleSignInResult.signedIn;
  }
}

final googleSignInFlowProvider = Provider<GoogleSignInFlow>((ref) {
  return GoogleSignInFlow(ref.watch(authServiceProvider));
});

/// Whether to show the Google button. A provider so widget tests can force it
/// on without a real client ID.
final googleSignInAvailableProvider = Provider<bool>(
  (ref) => GoogleSignInFlow.isAvailable,
);
