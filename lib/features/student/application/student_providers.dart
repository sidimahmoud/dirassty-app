import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/student.dart';
import '../../auth/application/app_auth_state.dart';
import '../../auth/application/auth_providers.dart';
import '../data/student_repository.dart';

final Provider<StudentRepository> studentRepositoryProvider = Provider(
  (ref) => StudentRepository(ref.watch(supabaseClientProvider)),
);

/// The logged-in student's own row. Watches [appAuthStateProvider] so a
/// sign-out (or session expiry) invalidates this automatically instead of
/// screens holding on to a stale student after the auth state has moved
/// on — every screen under the student area depends on this, not on
/// reading `auth.currentUser` directly.
final FutureProvider<Student> currentStudentProvider = FutureProvider((
  ref,
) async {
  final AppAuthState authState = await ref.watch(appAuthStateProvider.future);
  if (authState is! AppAuthStudent) {
    throw StateError('currentStudentProvider read outside student mode');
  }
  return ref
      .watch(studentRepositoryProvider)
      .getCurrentStudent(authState.userId);
});
