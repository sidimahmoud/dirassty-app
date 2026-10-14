import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import 'push_service.dart';

final Provider<PushService> pushServiceProvider = Provider(
  (ref) => PushService(ref.watch(supabaseClientProvider)),
);
