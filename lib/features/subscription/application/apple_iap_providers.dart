import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../../../core/config/store_policy.dart';
import '../../auth/application/auth_providers.dart';
import '../../parent/application/parent_providers.dart';
import '../data/apple_iap_service.dart';
import 'subscription_providers.dart';

final Provider<AppleIapService> appleIapServiceProvider = Provider(
  (ref) => AppleIapService(ref.watch(supabaseClientProvider)),
);

/// The plans sold on iOS with Apple's prices. Loaded only while the
/// purchase screen is open.
final AutoDisposeFutureProvider<List<AppleOffer>> appleOffersProvider =
    FutureProvider.autoDispose((ref) async {
  final plans = await ref.watch(activePlansProvider.future);
  return ref.watch(appleIapServiceProvider).loadOffers(plans);
});

enum ApplePurchasePhase { idle, buying, verifying, success, cancelled, error }

@immutable
class ApplePurchaseState {
  const ApplePurchaseState(this.phase, {this.errorCode});

  final ApplePurchasePhase phase;
  final String? errorCode;

  bool get busy =>
      phase == ApplePurchasePhase.buying ||
      phase == ApplePurchasePhase.verifying;
}

/// Listens to Apple's purchase stream for the whole app life (started in
/// DirasstyApp, iOS only), so a purchase is unlocked even if it completes
/// after the screen closed or at the next launch.
class ApplePurchaseController extends Notifier<ApplePurchaseState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// The student of the purchase in progress, for the rare transaction
  /// that comes back without its applicationUsername.
  String? _pendingStudentId;

  @override
  ApplePurchaseState build() {
    if (StorePolicy.usesAppleInAppPurchase) {
      _sub = ref.read(appleIapServiceProvider).purchases.listen(
            _onPurchases,
            onError: (_) => state = const ApplePurchaseState(
              ApplePurchasePhase.error,
              errorCode: 'store_error',
            ),
          );
      ref.onDispose(() => _sub?.cancel());
    }
    return const ApplePurchaseState(ApplePurchasePhase.idle);
  }

  Future<void> buy(AppleOffer offer, String studentId) async {
    if (state.busy) return;
    _pendingStudentId = studentId;
    state = const ApplePurchaseState(ApplePurchasePhase.buying);
    try {
      await ref.read(appleIapServiceProvider).buy(offer, studentId);
    } catch (_) {
      state = const ApplePurchaseState(
        ApplePurchasePhase.error,
        errorCode: 'store_error',
      );
    }
  }

  Future<void> restore() async {
    try {
      await ref.read(appleIapServiceProvider).restore();
    } catch (_) {}
    _refreshAccess(null);
  }

  void reset() => state = const ApplePurchaseState(ApplePurchasePhase.idle);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final AppleIapService service = ref.read(appleIapServiceProvider);
    for (final PurchaseDetails p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          state = const ApplePurchaseState(ApplePurchasePhase.buying);
        case PurchaseStatus.canceled:
          await service.finish(p);
          state = const ApplePurchaseState(ApplePurchasePhase.cancelled);
        case PurchaseStatus.error:
          await service.finish(p);
          state = const ApplePurchaseState(
            ApplePurchasePhase.error,
            errorCode: 'store_error',
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _unlock(service, p);
      }
    }
  }

  Future<void> _unlock(AppleIapService service, PurchaseDetails p) async {
    final String? studentId = service.studentIdOf(p) ?? _pendingStudentId;
    final String? transactionId = p.purchaseID;
    if (studentId == null || transactionId == null) {
      await service.finish(p);
      return;
    }
    state = const ApplePurchaseState(ApplePurchasePhase.verifying);
    try {
      await service.verify(transactionId: transactionId, studentId: studentId);
      await service.finish(p);
      _refreshAccess(studentId);
      state = const ApplePurchaseState(ApplePurchasePhase.success);
    } on AppleIapException catch (e) {
      if (e.isFinal) await service.finish(p);
      state = ApplePurchaseState(ApplePurchasePhase.error, errorCode: e.code);
    } catch (_) {
      state = const ApplePurchaseState(
        ApplePurchasePhase.error,
        errorCode: 'network',
      );
    }
  }

  void _refreshAccess(String? studentId) {
    ref.invalidate(subscriptionsByParentProvider);
    ref.invalidate(latestSubscriptionsByStudentProvider);
    ref.invalidate(upcomingSubscriptionsByStudentProvider);
    ref.invalidate(studentsByParentProvider);
    if (studentId != null) {
      ref.invalidate(subscriptionForStudentProvider(studentId));
      ref.invalidate(upcomingSubscriptionForStudentProvider(studentId));
      ref.invalidate(studentHasAccessProvider(studentId));
    } else {
      ref.invalidate(subscriptionForStudentProvider);
      ref.invalidate(upcomingSubscriptionForStudentProvider);
      ref.invalidate(studentHasAccessProvider);
    }
  }
}

final NotifierProvider<ApplePurchaseController, ApplePurchaseState>
    applePurchaseControllerProvider =
    NotifierProvider<ApplePurchaseController, ApplePurchaseState>(
  ApplePurchaseController.new,
);
