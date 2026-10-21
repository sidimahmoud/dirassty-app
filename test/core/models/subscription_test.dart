import 'package:dirassty/core/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription _sub({
  required SubscriptionStatus status,
  DateTime? trialEnds,
  DateTime? currentPeriodStart,
  DateTime? currentPeriodEnd,
}) {
  final now = DateTime.now();
  return Subscription(
    id: 'sub-1',
    parentId: 'parent-1',
    studentId: 'student-1',
    planId: null,
    plan: null,
    status: status,
    trialEnds: trialEnds ?? now,
    currentPeriodStart: currentPeriodStart,
    currentPeriodEnd: currentPeriodEnd,
    paymentMethod: null,
    paymentPhone: null,
    paymentCode: null,
    createdAt: now,
  );
}

void main() {
  final now = DateTime.now();
  final future = now.add(const Duration(days: 10));
  final past = now.subtract(const Duration(days: 10));

  group('grantsAccess', () {
    test('active row with a future end date grants access', () {
      expect(
        _sub(status: SubscriptionStatus.active, currentPeriodEnd: future)
            .grantsAccess,
        isTrue,
      );
    });

    test('active row with a past end date does not grant access', () {
      expect(
        _sub(status: SubscriptionStatus.active, currentPeriodEnd: past)
            .grantsAccess,
        isFalse,
      );
    });

    test('active row with no end date grants access (never expires)', () {
      expect(_sub(status: SubscriptionStatus.active).grantsAccess, isTrue);
    });

    test('trial grants access only before it ends', () {
      expect(
        _sub(status: SubscriptionStatus.trial, trialEnds: future).grantsAccess,
        isTrue,
      );
      expect(
        _sub(status: SubscriptionStatus.trial, trialEnds: past).grantsAccess,
        isFalse,
      );
    });

    test(
        'scheduled (early renewal, not yet promoted) never grants access on its own',
        () {
      expect(
        _sub(status: SubscriptionStatus.scheduled, currentPeriodEnd: future)
            .grantsAccess,
        isFalse,
      );
    });

    for (final status in [
      SubscriptionStatus.pending,
      SubscriptionStatus.unpaid,
      SubscriptionStatus.paused,
      SubscriptionStatus.cancelled,
    ]) {
      test('$status never grants access', () {
        expect(_sub(status: status).grantsAccess, isFalse);
      });
    }
  });

  test('isUpcoming is true only for scheduled rows', () {
    expect(_sub(status: SubscriptionStatus.scheduled).isUpcoming, isTrue);
    expect(_sub(status: SubscriptionStatus.active).isUpcoming, isFalse);
  });
}
