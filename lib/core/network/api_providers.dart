import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import 'api_client.dart';

/// Sends the current Supabase session's access token with every API call
/// (read at call time, so a refreshed token is always used).
final Provider<ApiClient> apiClientProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ApiClient(accessToken: () => client.auth.currentSession?.accessToken);
});
