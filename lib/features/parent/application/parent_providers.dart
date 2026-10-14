import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/parent.dart';
import '../../../core/models/student.dart';
import '../../../core/models/weekly_insight.dart';
import '../../auth/application/app_auth_state.dart';
import '../../auth/application/auth_providers.dart';
import '../../subscription/application/subscription_providers.dart';
import '../data/parent_repository.dart';
import '../data/weekly_insight_repository.dart';

final Provider<ParentRepository> parentRepositoryProvider = Provider(
  (ref) => ParentRepository(ref.watch(supabaseClientProvider)),
);

final Provider<WeeklyInsightRepository> weeklyInsightRepositoryProvider =
    Provider(
        (ref) => WeeklyInsightRepository(ref.watch(supabaseClientProvider)));

/// One AI insight + suggestion per student per week — generated on first
/// request, cached after that (see WeeklyInsightRepository). Family-keyed
/// by student id so each child's card fetches/caches independently.
final weeklyInsightProvider = FutureProvider.family<WeeklyInsight, String>((
  ref,
  studentId,
) {
  return ref.watch(weeklyInsightRepositoryProvider).getOrGenerate(studentId);
});

/// The logged-in parent's own row. Mirrors [currentStudentProvider] in
/// the student feature — watches [appAuthStateProvider] so sign-out
/// invalidates this automatically.
final FutureProvider<Parent> currentParentProvider = FutureProvider((
  ref,
) async {
  final AppAuthState authState = await ref.watch(appAuthStateProvider.future);
  if (authState is! AppAuthParent) {
    throw StateError('currentParentProvider read outside parent mode');
  }
  return ref.watch(parentRepositoryProvider).getCurrentParent(authState.userId);
});

final FutureProvider<List<Student>> studentsByParentProvider = FutureProvider((
  ref,
) async {
  final Parent parent = await ref.watch(currentParentProvider.future);
  return ref.watch(parentRepositoryProvider).getStudentsByParent(parent.id);
});

/// Performs "add a child" and exposes its loading/error state — same
/// shape as [AuthController]/[DeleteAccountController]. [createChild]
/// itself returns the new child's actual username and id (not carried in
/// `state`, which only ever tracks "is an action in flight", matching
/// every other controller here) — the parent chooses the username, but
/// the username edge function normalizes case, so this is the confirmed
/// final value, not just an echo of what was typed; the id lets the
/// caller offer subscribing this exact child right away.
class AddChildController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<({String username, String studentId})> createChild({
    required String name,
    required int grade,
    required String avatarId,
    required String username,
    required String pin,
  }) async {
    state = const AsyncLoading();
    String resultUsername = '';
    String resultStudentId = '';
    state = await AsyncValue.guard(() async {
      final Parent parent = await ref.read(currentParentProvider.future);
      final Student student =
          await ref.read(parentRepositoryProvider).createStudent(
                parentId: parent.id,
                name: name,
                grade: grade,
                avatarId: avatarId,
              );
      resultStudentId = student.id;
      ref.invalidate(studentsByParentProvider);
      // Every child gets their own trial the moment they're created —
      // subscriptions are per-student (see supabase/migrations/016_
      // student_subscriptions.sql), so this can't be "only if the parent
      // has none yet" the way it used to be. Admin-controlled, on top of
      // that (see 020_trial_toggle.sql) — skip entirely when off, rather
      // than attempting an insert RLS would reject anyway.
      final appSettings = await ref.read(appSettingsProvider.future);
      if (appSettings.trialEnabled) {
        await ref.read(subscriptionRepositoryProvider).createTrial(
              parentId: parent.id,
              studentId: student.id,
              durationDays: appSettings.trialDurationDays,
            );
        ref.invalidate(subscriptionsByParentProvider);
        ref.invalidate(latestSubscriptionsByStudentProvider);
      }
      resultUsername = await ref
          .read(parentRepositoryProvider)
          .setStudentCredentials(
              studentId: student.id, username: username, pin: pin);
    });
    return (username: resultUsername, studentId: resultStudentId);
  }
}

final AsyncNotifierProvider<AddChildController, void>
    addChildControllerProvider =
    AsyncNotifierProvider<AddChildController, void>(AddChildController.new);

/// Changing an existing child's login credentials (ChildProgressScreen) —
/// the username, the PIN, or both — separate from [AddChildController]
/// since it doesn't touch the student row or subscription at all, just
/// the login itself.
class UpdateStudentCredentialsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> updateCredentials({
    required String studentId,
    String? username,
    String? pin,
  }) async {
    state = const AsyncLoading();
    String resultUsername = '';
    state = await AsyncValue.guard(() async {
      resultUsername = await ref
          .read(parentRepositoryProvider)
          .setStudentCredentials(
              studentId: studentId, username: username, pin: pin);
      ref.invalidate(studentsByParentProvider);
    });
    return resultUsername;
  }
}

final AsyncNotifierProvider<UpdateStudentCredentialsController, void>
    updateStudentCredentialsControllerProvider =
    AsyncNotifierProvider<UpdateStudentCredentialsController, void>(
  UpdateStudentCredentialsController.new,
);
