import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Initializes the global Supabase client from the compile-time [Env] defines.
///
/// Call this once at app startup (after `WidgetsFlutterBinding.ensureInitialized`)
/// before any provider that reads [SupabaseClient]. Throws a [StateError] with a
/// clear message if the required `--dart-define` values are missing.
///
/// After this returns, [Supabase.instance.client] is available, and the
/// `supabaseClientProvider` exposes it to the Riverpod graph.
Future<SupabaseClient> initSupabase() async {
  Env.assertConfigured();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // The anon key is Supabase's "publishable" key; the named define stays
    // SUPABASE_ANON_KEY to match the DB's anon role and existing tooling.
    publishableKey: Env.supabaseAnonKey,
  );
  return Supabase.instance.client;
}
