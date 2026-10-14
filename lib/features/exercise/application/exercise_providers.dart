import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/exercise_repository.dart';

final Provider<ExerciseRepository> exerciseRepositoryProvider = Provider(
  (ref) => ExerciseRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(apiClientProvider),
  ),
);
