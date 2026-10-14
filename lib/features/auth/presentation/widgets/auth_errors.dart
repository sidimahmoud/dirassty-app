import 'package:shared_preferences/shared_preferences.dart';

import '../../../../l10n/app_localizations.dart';

/// Maps a request-otp / verify-otp / register-direct failure (the Edge
/// Functions' error codes, see supabase/functions/) to its localized
/// message. Unknown errors fall back to the generic copy.
String authErrorMessage(AppLocalizations l10n, Object error) {
  final String m = error.toString();
  if (m.contains('account_exists')) return l10n.errAccountExists;
  if (m.contains('username_taken')) return l10n.errUsernameTaken;
  if (m.contains('invalid_username')) return l10n.errUsernameFormat;
  if (m.contains('grade_inactive') || m.contains("n'est pas active")) {
    return l10n.errGradeClosed;
  }
  if (m.contains('grade_parent_only')) return l10n.selfSignupFromC2;
  if (m.contains('too_soon')) return l10n.errTooSoon;
  if (m.contains('code_expired')) return l10n.errCodeExpired;
  if (m.contains('incorrect_code')) return l10n.errIncorrectCode;
  if (m.contains('too_many_attempts')) return l10n.errTooManyAttempts;
  if (m.contains('no_pending_code')) return l10n.errNoPendingCode;
  return l10n.errGeneric;
}

/// Client-side lockout after repeated wrong PINs: 5 misses → locked for
/// 5 minutes (DESIGN_SPEC §4 "Student login"). Persisted so relaunching
/// the app doesn't reset it. This is a UX guard only — the server has no
/// equivalent limit yet (TODO(api): enforce attempt limits in Supabase
/// Auth / an Edge Function so it can't be bypassed).
class PinAttemptLimiter {
  const PinAttemptLimiter(this.scope);

  /// 'student' or 'parent' — separate counters per login screen.
  final String scope;

  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 5);

  String get _countKey => 'auth.pin_failures.$scope';
  String get _untilKey => 'auth.pin_locked_until.$scope';

  /// Remaining lock time, or null when not locked.
  Future<Duration?> lockRemaining() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_untilKey);
    if (raw == null) return null;
    final Duration left = DateTime.parse(raw).difference(DateTime.now());
    if (left.isNegative) {
      await prefs.remove(_untilKey);
      await prefs.remove(_countKey);
      return null;
    }
    return left;
  }

  /// Records a wrong PIN; returns the lock duration if this one tripped
  /// the limit.
  Future<Duration?> recordFailure() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int count = (prefs.getInt(_countKey) ?? 0) + 1;
    if (count >= maxAttempts) {
      await prefs.setString(
          _untilKey, DateTime.now().add(lockDuration).toIso8601String());
      await prefs.remove(_countKey);
      return lockDuration;
    }
    await prefs.setInt(_countKey, count);
    return null;
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countKey);
    await prefs.remove(_untilKey);
  }
}
