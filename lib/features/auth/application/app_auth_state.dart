/// The app's resolved auth+role state, derived from the Supabase session
/// plus a lookup into `parents`/`students` — see
/// [AuthRepository.resolveRole]. Never inferred from "which login form was
/// used": a session restored on app relaunch has no memory of that.
sealed class AppAuthState {
  const AppAuthState();
}

final class AppAuthUnauthenticated extends AppAuthState {
  const AppAuthUnauthenticated();
}

final class AppAuthStudent extends AppAuthState {
  const AppAuthStudent({required this.userId});

  final String userId;
}

final class AppAuthParent extends AppAuthState {
  const AppAuthParent({required this.userId, required this.needsOnboarding});

  final String userId;

  /// True when the phone OTP succeeded but no `parents` row exists yet —
  /// a first-time parent who hasn't completed registration.
  final bool needsOnboarding;
}
