import 'package:supabase_flutter/supabase_flutter.dart';

/// The only place in the app that calls account-deletion RPCs.
class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  /// Calls the `delete_own_account` Postgres function (see
  /// supabase/migrations/013_delete_own_account.sql) — a SECURITY
  /// DEFINER function that deletes the caller's own parent/student row
  /// (cascading to progress/xp/badges/etc.) and their `auth.users` row.
  /// A client can never do the `auth.users` deletion directly; that
  /// needs the service-role key, which must never ship in this app.
  ///
  /// Throws if the migration hasn't been applied to the project yet
  /// (the function won't exist) — callers must surface that clearly
  /// rather than silently signing the user out as if it worked.
  Future<void> deleteOwnAccount() async {
    await _client.rpc<void>('delete_own_account');
  }
}
