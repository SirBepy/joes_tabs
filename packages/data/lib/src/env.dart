/// Compile-time environment configuration for the data layer.
///
/// Values are injected via `--dart-define` (or a `--dart-define-from-file`
/// JSON) at build/run time and read here with [String.fromEnvironment]. They
/// are NOT read from a `.env` at runtime and are never hardcoded, so secrets
/// stay out of the repository.
///
/// Example run:
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// ```
class Env {
  const Env._();

  /// Supabase project URL, e.g. `https://<ref>.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon (public) API key. Safe to ship in a client build, but kept
  /// out of source control so it can be rotated without a code change.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// OAuth client ID of the Google Cloud "Web application" client that Supabase's
  /// Google provider is configured with. Android's native sign-in requests ID
  /// tokens for this audience so Supabase accepts them. Public, not a secret.
  /// Optional: when empty, native Google sign-in is hidden.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Turns on the Search screen's "From the web" section. Off unless built with
  /// `--dart-define=WEB_TABS=true`: ukulele-tabs.com's terms forbid extraction
  /// without their written permission, so only the `ut-client` demo build sets it.
  static const bool webTabs = bool.fromEnvironment('WEB_TABS');

  /// True only when both required defines are present and non-empty.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Throws a clear [StateError] listing the missing defines, used by
  /// [initSupabase] before touching the network.
  static void assertConfigured() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing --dart-define values: ${missing.join(', ')}. '
        'Pass them at build/run time, e.g. '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
