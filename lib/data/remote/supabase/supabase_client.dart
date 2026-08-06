import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client for authentication only (Sprint 0).
///
/// Credentials must be supplied at run/build time:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Does not query any Supabase tables — auth session APIs only.
Future<void> initializeSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || anonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
      'Pass both via --dart-define when running or building the app.',
    );
  }

  await Supabase.initialize(
    url: url,
    publishableKey: anonKey,
  );
}
