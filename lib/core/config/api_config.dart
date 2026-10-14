/// Base URL for the Next.js app's API routes (AI generation, corrections —
/// anything that must stay server-side because it calls an LLM with a
/// secret key). Defaults to the live Vercel deployment
/// (`dirassty.vercel.app`, the Vercel project's stable domain). Override with
/// `--dart-define=API_BASE_URL=http://localhost:3000` when developing
/// against a local `npm run dev` web server instead.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dirassty.vercel.app',
  );
}
