/// Supabase project connection details.
///
/// Defaults to the same project the web app talks to (see
/// apps/web/.env.local's NEXT_PUBLIC_SUPABASE_URL/ANON_KEY) so `flutter
/// run` works with no extra flags. Override per environment with
/// `--dart-define=SUPABASE_URL=...` / `--dart-define=SUPABASE_ANON_KEY=...`
/// if/when a separate staging project exists.
///
/// The anon key is meant to be public — it ships in every client bundle by
/// design, on web and mobile alike. Real access control lives in Postgres
/// RLS policies, not in keeping this key secret.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wgzhhpvnbajlqylollyg.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndnemhocHZuYmFqbHF5bG9sbHlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5Njk4MDMsImV4cCI6MjA5MzU0NTgwM30.FINoy4NQXW36OpHKlgQJYQvcxUo41RA8PJpIVAZTjRI',
  );
}
