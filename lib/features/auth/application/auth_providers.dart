import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import 'app_auth_state.dart';

final Provider<SupabaseClient> supabaseClientProvider = Provider(
  (ref) => Supabase.instance.client,
);

final Provider<AuthRepository> authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// The resolved auth+role state, re-evaluated every time Supabase's auth
/// stream emits (sign-in, sign-out, token refresh). Screens/the router
/// watch this to decide what to show; [authControllerProvider] is for
/// *performing* login actions — this is for *reacting* to their result.
final StreamProvider<AppAuthState> appAuthStateProvider = StreamProvider((
  ref,
) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield await repo.resolveRole(repo.currentSession?.user.id);
  yield* repo.onAuthStateChange.asyncMap(
    (change) => repo.resolveRole(change.session?.user.id),
  );
});

/// Performs login/logout actions and exposes their loading/error state.
/// Screens call `ref.read(authControllerProvider.notifier).signInStudent(...)`
/// and watch `ref.watch(authControllerProvider)` for an [AsyncValue] to
/// show a spinner or an error — this notifier only tracks "is an action in
/// flight right now", never role (see [appAuthStateProvider] for that).
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInStudent({
    required String username,
    required String pin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInStudent(username: username, pin: pin),
    );
  }

  Future<void> signInParent({
    required String phone,
    required String pin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInParent(localPhone: phone, pin: pin),
    );
  }

  Future<void> requestOtp({
    required String phone,
    required String role,
    required Map<String, dynamic> metadata,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).requestOtp(
            localPhone: phone,
            role: role,
            metadata: metadata,
          ),
    );
  }

  Future<void> verifyOtpAndRegister({
    required String phone,
    required String role,
    required String code,
    required String pin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtpAndRegister(
            localPhone: phone,
            role: role,
            code: code,
            pin: pin,
          ),
    );
  }

  Future<void> registerDirect({
    required String role,
    required String name,
    required String lang,
    required String pin,
    String? phone,
    int? grade,
    String? username,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).registerDirect(
            role: role,
            name: name,
            lang: lang,
            pin: pin,
            phone: phone,
            grade: grade,
            username: username,
          ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final AsyncNotifierProvider<AuthController, void> authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
