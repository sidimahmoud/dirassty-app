import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/account_repository.dart';

final Provider<AccountRepository> accountRepositoryProvider = Provider(
  (ref) => AccountRepository(ref.watch(supabaseClientProvider)),
);

/// Performs account deletion and exposes its loading/error state — same
/// shape as [AuthController]: screens call
/// `ref.read(deleteAccountControllerProvider.notifier).deleteAccount()`
/// and watch the provider itself for an [AsyncValue] to show a spinner
/// or an error.
class DeleteAccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).deleteOwnAccount();
      // The RPC deletes the auth.users row server-side, but the local
      // client session isn't automatically cleared by that — sign out
      // explicitly so the router's auth-redirect gate sends the student
      // to Welcome immediately, the same path a normal logout takes.
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}

final AsyncNotifierProvider<DeleteAccountController, void>
    deleteAccountControllerProvider =
    AsyncNotifierProvider<DeleteAccountController, void>(
  DeleteAccountController.new,
);
