import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/network/retry.dart';
import '../../../core/offline/offline_video_store.dart';
import '../../focus/data/focus_repository.dart';
import '../application/app_auth_state.dart';

/// The only place in the app that calls `supabase.auth.*` or touches the
/// `parents`/`students` tables for login purposes. Screens and providers
/// go through this, never `Supabase.instance.client` directly — that keeps
/// the actual auth contract in exactly one place instead of duplicated
/// across call sites.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Students authenticate with username + PIN against a synthetic email —
  /// there's no real inbox behind it, it only exists so Supabase's
  /// email/password auth can be reused instead of building a second auth
  /// system. This domain MUST exactly match the web app's
  /// `STUDENT_EMAIL_DOMAIN` (apps/web/app/(auth)/login/page.tsx) — students
  /// provisioned there sign in here.
  static const String _studentEmailDomain = 'students.dirassty.internal';

  /// Same idea as [_studentEmailDomain], for parents who registered via
  /// phone + WhatsApp OTP (see supabase/functions/verify-otp) instead of
  /// being provisioned with a username. MUST match
  /// `syntheticEmail()` in supabase/functions/_shared/otp.ts.
  static const String _parentEmailDomain = 'parents.dirassty.internal';

  /// Mauritania's country code, hardcoded like the web login page — every
  /// Dirassty account is Mauritanian.
  static const String _countryCode = '+222';

  /// A login PIN is 4 digits, but Supabase Auth requires passwords of at
  /// least 6 characters — so the stored password is `njh-<pin>`. MUST
  /// stay identical to supabase/functions/_shared/pin.ts and the web
  /// admin's `pinPassword` (apps/web/app/api/admin/students/
  /// _credentials.ts). Not a secret: it only satisfies the length rule.
  static String pinPassword(String pin) => 'njh-$pin';

  Session? get currentSession => _client.auth.currentSession;

  /// Signs in with [pin] as stored today ([pinPassword]); falls back to
  /// the bare PIN for accounts created before that format existed, and
  /// then quietly upgrades them so the fallback is needed only once.
  /// Throws the original error if neither matches (a wrong PIN).
  Future<void> _signInWithPin(String email, String pin) async {
    try {
      await _client.auth
          .signInWithPassword(email: email, password: pinPassword(pin));
    } on AuthException catch (original) {
      try {
        await _client.auth.signInWithPassword(email: email, password: pin);
      } on AuthException {
        throw original;
      }
      try {
        await _client.auth
            .updateUser(UserAttributes(password: pinPassword(pin)));
      } catch (_) {
        // Best effort — the legacy password still works next time.
      }
    }
  }

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInStudent({
    required String username,
    required String pin,
  }) async {
    await _signInWithPin(
      '${username.trim().toLowerCase()}@$_studentEmailDomain',
      pin,
    );
  }

  /// Returning-parent login. Supabase's native Phone/SMS provider isn't
  /// configured on this project (would need a separate paid Twilio
  /// Messaging Service) — parents authenticate the same way students do,
  /// phone + PIN against a synthetic email, set once at registration
  /// time (see [verifyOtpAndRegister]).
  Future<void> signInParent({
    required String localPhone,
    required String pin,
  }) async {
    await _signInWithPin(
      '${_digitsOf(_fullPhone(localPhone))}@$_parentEmailDomain',
      pin,
    );
  }

  /// Step 1 of self-registration: ask for a WhatsApp OTP to be sent to
  /// [localPhone]. Currently only used for the parent role — see
  /// RegisterScreen's doc comment for why student self-registration
  /// still goes through [registerDirect] unverified (verify-otp doesn't
  /// carry a student's chosen username into the created row, so routing
  /// students through OTP today would create an account with no way to
  /// log back in via username+PIN).
  Future<void> requestOtp({
    required String localPhone,
    required String role,
    required Map<String, dynamic> metadata,
  }) async {
    await _invokeFunction('request-otp', {
      'phone': _digitsOf(_fullPhone(localPhone)),
      'role': role,
      'metadata': metadata,
    });
  }

  /// Step 2 of self-registration, and the only step for redeeming an
  /// admin-issued invite code (same Edge Function, same payload shape —
  /// an invite code was never requested by this device, but it's
  /// verified identically). On success, creates the real
  /// `parents`/`students` row server-side, then signs in immediately
  /// with the [pin] just chosen — no separate login step.
  Future<void> verifyOtpAndRegister({
    required String localPhone,
    required String role,
    required String code,
    required String pin,
  }) async {
    final Map<String, dynamic> data = await _invokeFunction('verify-otp', {
      'phone': _digitsOf(_fullPhone(localPhone)),
      'role': role,
      'code': code,
      'pin': pin,
    });

    await _signInWithPin(data['email'] as String, pin);
  }

  /// Self-registration without a WhatsApp-OTP round trip — see
  /// supabase/functions/register-direct. Creates the account immediately
  /// and signs in with the [pin] just chosen, exactly like
  /// [verifyOtpAndRegister] does once its code is verified. A parent logs
  /// in with [phone] afterward (matches [signInParent]); a student logs
  /// in with [username] afterward (matches [signInStudent]) — [phone] is
  /// optional for a student, collected only so progress notifications
  /// have somewhere to go, never used to sign in.
  Future<void> registerDirect({
    required String role,
    required String name,
    required String lang,
    required String pin,
    String? phone,
    int? grade,
    String? username,
  }) async {
    final Map<String, dynamic> data = await _invokeFunction('register-direct', {
      'role': role,
      'name': name,
      'lang': lang,
      'pin': pin,
      if (phone != null && phone.trim().isNotEmpty)
        'phone': _digitsOf(_fullPhone(phone)),
      if (grade != null) 'grade': grade,
      if (username != null) 'username': username,
    });

    await _signInWithPin(data['email'] as String, pin);
  }

  /// Also wipes this device's offline videos and cached focus schedule —
  /// both belong to the account, not the device.
  Future<void> signOut() async {
    await const OfflineVideoStore().deleteAll();
    await FocusRepository.clearLocal();
    await _client.auth.signOut();
  }

  String _fullPhone(String local) =>
      '$_countryCode${local.replaceAll(RegExp(r'\s'), '')}';

  String _digitsOf(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  /// Calls one of the WhatsApp-OTP Edge Functions (request-otp,
  /// verify-otp — see supabase/functions/) over plain HTTP, not
  /// `supabase.functions.invoke`. Deliberately: this app already has a
  /// proven HTTP-calling pattern via `package:http` (see
  /// core/network/api_client.dart for the Next.js API routes), and
  /// reusing that avoids depending on the exact return-type shape of
  /// supabase_flutter's FunctionsClient, which isn't worth the risk for
  /// two simple JSON-in/JSON-out calls.
  Future<Map<String, dynamic>> _invokeFunction(
    String name,
    Map<String, dynamic> body,
  ) async {
    final Uri uri = Uri.parse('${SupabaseConfig.url}/functions/v1/$name');
    final http.Response response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'apikey': SupabaseConfig.anonKey,
      },
      body: jsonEncode(body),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // The Edge Functions always return `{ error: '...' }` on failure —
      // surface that message directly rather than a generic HTTP status,
      // since callers (e.g. "account_exists", "code_expired") pattern-
      // match on it for human-friendly copy.
      throw Exception(data['error']?.toString() ?? 'unknown_error');
    }

    return data;
  }

  /// Determines role from the DATA, not from which login form was used —
  /// a session restored on app relaunch has no memory of that. A
  /// `parents` row means parent; a `students` row (linked via
  /// `auth_user_id`, see supabase/migrations/011_student_login.sql and
  /// 014_account_registration_codes.sql) means student — both rows are
  /// created before this can ever be called with their new user's id
  /// (admin-provisioned, self-registered via WhatsApp OTP, or an
  /// admin-invite claim all create the row first), so "neither" only
  /// means a first-time parent who verified their phone via the legacy
  /// onboarding flow but hasn't finished registration.
  /// The last settled role (a student, or a parent past onboarding) and
  /// whose it is. It can't change while the same person stays signed in,
  /// so token refreshes, the app coming back to the foreground and every
  /// router redirect reuse it instead of two network reads each time — one
  /// failed read there used to leave the app on "Hors ligne · Impossible
  /// de charger ton profil" with a working connection. Reset on sign-out
  /// or another account.
  String? _settledRoleUserId;
  AppAuthState? _settledRole;

  Future<AppAuthState> resolveRole(String? userId) async {
    if (userId == null) {
      _settledRoleUserId = null;
      _settledRole = null;
      return const AppAuthUnauthenticated();
    }
    final AppAuthState? settled = _settledRole;
    if (settled != null && userId == _settledRoleUserId) return settled;

    final AppAuthState role = await retryRequest(() => _fetchRole(userId));
    final bool isSettled = role is AppAuthStudent ||
        (role is AppAuthParent && !role.needsOnboarding);
    _settledRoleUserId = isSettled ? userId : null;
    _settledRole = isSettled ? role : null;
    return role;
  }

  Future<AppAuthState> _fetchRole(String userId) async {
    final parentRow = await _client
        .from('parents')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (parentRow != null) {
      return AppAuthParent(userId: userId, needsOnboarding: false);
    }

    final studentRow = await _client
        .from('students')
        .select('id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    if (studentRow != null) {
      return AppAuthStudent(userId: userId);
    }

    return AppAuthParent(userId: userId, needsOnboarding: true);
  }
}
