import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_settings.dart';
import '../../../core/models/plan.dart';
import '../../../core/models/subscription.dart';
import '../../auth/application/auth_providers.dart';
import '../../parent/application/parent_providers.dart';
import '../../student/application/student_providers.dart';
import '../data/subscription_repository.dart';

final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider(
  (ref) => SubscriptionRepository(ref.watch(supabaseClientProvider)),
);

/// Whether new students currently get a free trial, and for how long —
/// admin-controlled (see supabase/migrations/020_trial_toggle.sql).
/// Checked before ever calling [SubscriptionRepository.createTrial].
final FutureProvider<AppSettings> appSettingsProvider = FutureProvider((ref) {
  return ref.watch(subscriptionRepositoryProvider).getAppSettings();
});

/// Every plan currently offered — the mobile app never hardcodes price or
/// duration, it always reflects whatever the admin has configured (see
/// supabase/migrations/018_configurable_plans.sql).
final FutureProvider<List<Plan>> activePlansProvider = FutureProvider((ref) {
  return ref.watch(subscriptionRepositoryProvider).getActivePlans();
});

/// Every subscription row across every one of the parent's children,
/// newest first.
final FutureProvider<List<Subscription>> subscriptionsByParentProvider =
    FutureProvider((ref) async {
  final parent = await ref.watch(currentParentProvider.future);
  return ref
      .watch(subscriptionRepositoryProvider)
      .getSubscriptionsForParent(parent.id);
});

/// Reduces [subscriptionsByParentProvider] to the single row per student
/// that actually grants access right now, keyed by student id — what the
/// parent-facing subscription screen renders as each child's card. NOT
/// simply "first row seen" (rows arrive newest-first, but the newest row
/// can be a future early-renewal that hasn't started yet — see
/// [Subscription.isUpcoming]): this prefers whichever row currently
/// grants access, falling back to the newest row for a student with none
/// (so a lapsed/pending child still shows something instead of nothing).
final FutureProvider<Map<String, Subscription>>
    latestSubscriptionsByStudentProvider = FutureProvider((ref) async {
  final List<Subscription> all = await ref.watch(
    subscriptionsByParentProvider.future,
  );
  final Map<String, Subscription> current = {};
  final Map<String, Subscription> newest = {};
  for (final Subscription sub in all) {
    final String? studentId = sub.studentId;
    if (studentId == null) continue;
    newest.putIfAbsent(studentId, () => sub);
    if (sub.grantsAccess) {
      current.putIfAbsent(studentId, () => sub);
    }
  }
  for (final MapEntry<String, Subscription> entry in newest.entries) {
    current.putIfAbsent(entry.key, () => entry.value);
  }
  return current;
});

/// Mirrors [latestSubscriptionsByStudentProvider] but surfaces each
/// student's *upcoming* row instead — the early-renewal scheduled to take
/// over once their current period ends, if any. A student with no
/// upcoming row is simply absent from the map.
final FutureProvider<Map<String, Subscription>>
    upcomingSubscriptionsByStudentProvider = FutureProvider((ref) async {
  final List<Subscription> all = await ref.watch(
    subscriptionsByParentProvider.future,
  );
  final Map<String, Subscription> upcoming = {};
  for (final Subscription sub in all) {
    final String? studentId = sub.studentId;
    if (studentId == null || !sub.isUpcoming) continue;
    upcoming.putIfAbsent(studentId, () => sub);
  }
  return upcoming;
});

/// The subscription row currently in effect for a single student — used
/// both by the parent-side per-child card and, more importantly, by the
/// access gate (router redirect + student-side lock screen), so it's
/// fetched independently of the parent's full list rather than assuming a
/// parent session is available.
final subscriptionForStudentProvider =
    FutureProvider.family<Subscription?, String>((
  ref,
  studentId,
) {
  return ref
      .watch(subscriptionRepositoryProvider)
      .getLatestForStudent(studentId);
});

/// The row scheduled to take over once a single student's current period
/// ends (an early renewal), or null. Used by the student's own Profile
/// summary (self-registered students have no parent list to derive this
/// from — see [upcomingSubscriptionsByStudentProvider]).
final upcomingSubscriptionForStudentProvider =
    FutureProvider.family<Subscription?, String>((
  ref,
  studentId,
) {
  return ref
      .watch(subscriptionRepositoryProvider)
      .getUpcomingForStudent(studentId);
});

/// Whether a student currently has course access — the one thing the
/// router's redirect gate and the lock screen actually need. Deliberately
/// never throws: "no row at all" (a student who somehow has none) and
/// "the query itself failed" (a network blip, a schema mismatch after a
/// pending migration, ...) both just mean "no access" here. This is a
/// fail-*closed* choice on purpose — a broken check must never silently
/// grant free access — but it also means a real backend problem must
/// show up to the student as the same friendly "no active subscription"
/// screen instead of crashing the whole app on an unhandled exception
/// (which is what a raw router-redirect throw used to do).
final studentHasAccessProvider = FutureProvider.family<bool, String>((
  ref,
  studentId,
) async {
  try {
    final Subscription? sub = await ref.watch(
      subscriptionForStudentProvider(studentId).future,
    );
    return sub?.grantsAccess ?? false;
  } catch (_) {
    return false;
  }
});

/// Performs the two subscribe/renew actions (Bankily submission, contact
/// request) for one or more selected children at once, and exposes
/// loading/error state — same shape as the app's other action controllers
/// (AuthController, AddChildController, ...). Works for a parent
/// subscribing for their children AND for any student subscribing for
/// themselves, parent-linked or self-registered alike — the server-side
/// `request_subscriptions()` resolves the parent and the price.
class SubscribeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitBankily({
    required List<String> studentIds,
    required String planId,
    required String phone,
    required Uint8List proofJpeg,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(subscriptionRepositoryProvider).submitBankilyPayment(
            studentIds: studentIds,
            planId: planId,
            phone: phone,
            proofJpeg: proofJpeg,
          );
      _invalidateAll(studentIds);
    });
  }

  Future<void> submitContact({
    required List<String> studentIds,
    required String planId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(subscriptionRepositoryProvider).submitContactRequest(
            studentIds: studentIds,
            planId: planId,
          );
      _invalidateAll(studentIds);
    });
  }

  void _invalidateAll(List<String> studentIds) {
    ref.invalidate(subscriptionsByParentProvider);
    ref.invalidate(latestSubscriptionsByStudentProvider);
    ref.invalidate(upcomingSubscriptionsByStudentProvider);
    for (final String studentId in studentIds) {
      ref.invalidate(subscriptionForStudentProvider(studentId));
      ref.invalidate(upcomingSubscriptionForStudentProvider(studentId));
      ref.invalidate(studentHasAccessProvider(studentId));
    }
  }
}

final AsyncNotifierProvider<SubscribeController, void>
    subscribeControllerProvider =
    AsyncNotifierProvider<SubscribeController, void>(SubscribeController.new);

/// Grants a just-registered, self-registered student their first trial —
/// the parent-managed equivalent lives in AddChildController.createChild
/// (parent_providers.dart). Kept here rather than in AuthController so
/// auth's application layer doesn't need to depend on subscription/
/// student (subscription already depends on auth, not the reverse —
/// keeping it one-directional avoids a feature-import cycle). Called by
/// RegisterScreen right after a successful student registration.
class PostRegistrationTrialController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Never throws — worst case a student reaches the subscribe screen
  /// with no trial instead of one, which is recoverable; blocking a
  /// successful registration on this wouldn't be.
  Future<void> grantTrialIfEnabled() async {
    try {
      final AppSettings appSettings =
          await ref.read(appSettingsProvider.future);
      if (!appSettings.trialEnabled) return;
      final student = await ref.read(currentStudentProvider.future);
      await ref.read(subscriptionRepositoryProvider).createTrial(
            parentId: null,
            studentId: student.id,
            durationDays: appSettings.trialDurationDays,
          );
    } catch (_) {
      // See doc comment above.
    }
  }
}

final AsyncNotifierProvider<PostRegistrationTrialController, void>
    postRegistrationTrialControllerProvider =
    AsyncNotifierProvider<PostRegistrationTrialController, void>(
  PostRegistrationTrialController.new,
);
