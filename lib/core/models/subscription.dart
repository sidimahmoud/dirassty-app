import 'package:flutter/foundation.dart';

import 'plan.dart';

enum SubscriptionStatus {
  trial,
  pending,
  unpaid,
  scheduled,
  active,
  paused,
  cancelled;

  static SubscriptionStatus fromDb(String value) => switch (value) {
        'pending' => SubscriptionStatus.pending,
        'unpaid' => SubscriptionStatus.unpaid,
        'scheduled' => SubscriptionStatus.scheduled,
        'active' => SubscriptionStatus.active,
        'paused' => SubscriptionStatus.paused,
        'cancelled' => SubscriptionStatus.cancelled,
        _ => SubscriptionStatus.trial,
      };
}

enum SubscriptionPaymentMethod {
  bankily,
  contact;

  static SubscriptionPaymentMethod? fromDb(String? value) => switch (value) {
        'bankily' => SubscriptionPaymentMethod.bankily,
        'contact' => SubscriptionPaymentMethod.contact,
        _ => null,
      };

  String get dbValue => switch (this) {
        SubscriptionPaymentMethod.bankily => 'bankily',
        SubscriptionPaymentMethod.contact => 'contact',
      };
}

/// Ported from `Subscription` in packages/shared/src/types, scoped to a
/// single student (see supabase/migrations/016_student_subscriptions.sql)
/// — a parent with several children has one row per child, each with its
/// own dates/status. [parentId] is null when a self-registered student
/// (no parent account — see 017_student_notifications.sql) subscribed
/// for themselves; [planId] is null while on the free trial, since the
/// trial isn't one of the admin-configured plans (see
/// 018_configurable_plans.sql). There is still no real payment gateway
/// wired up anywhere in this project: 'bankily' rows carry a phone+code
/// the subscriber submitted for an admin to verify manually against the
/// BPay merchant dashboard ('pending' until then); 'contact' rows are a
/// WhatsApp arrangement instead ('unpaid' until the admin activates
/// them). Only an admin, from the web panel, can ever flip a row to
/// 'active' — see this migration's RLS.
@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.planId,
    required this.plan,
    required this.status,
    required this.trialEnds,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.paymentMethod,
    required this.paymentPhone,
    required this.paymentCode,
    required this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final Object? planJson = json['plan'];
    return Subscription(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      studentId: json['student_id'] as String?,
      planId: json['plan_id'] as String?,
      plan: planJson is Map<String, dynamic> ? Plan.fromJson(planJson) : null,
      status: SubscriptionStatus.fromDb(json['status'] as String),
      trialEnds: DateTime.parse(json['trial_ends'] as String),
      currentPeriodStart: json['current_period_start'] == null
          ? null
          : DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
      paymentMethod: SubscriptionPaymentMethod.fromDb(
        json['payment_method'] as String?,
      ),
      paymentPhone: json['payment_phone'] as String?,
      paymentCode: json['payment_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String? parentId;
  final String? studentId;
  final String? planId;

  /// Populated only when the row was fetched with the `plan:plan_id(*)`
  /// embed (see SubscriptionRepository) — null for a trial row, or if
  /// the caller didn't ask for the embed.
  final Plan? plan;
  final SubscriptionStatus status;
  final DateTime trialEnds;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final SubscriptionPaymentMethod? paymentMethod;
  final String? paymentPhone;
  final String? paymentCode;
  final DateTime createdAt;

  int get daysLeftInTrial =>
      trialEnds.difference(DateTime.now()).inDays.clamp(0, 1 << 30);

  /// The single source of truth for "does this row currently grant course
  /// access" — every gating check and every UI badge reads this instead
  /// of re-deriving it from status/dates independently, so they can't
  /// drift apart. A 'scheduled' row (an early renewal queued up to take
  /// over once the current period ends — see [isUpcoming]) never grants
  /// access on its own; a daily cron promotes it to 'active' once its
  /// turn actually comes (see supabase/functions/activate-scheduled-
  /// subscriptions), and only then does this flip to true for it.
  bool get grantsAccess {
    final DateTime now = DateTime.now();
    return switch (status) {
      SubscriptionStatus.active =>
        currentPeriodEnd == null || currentPeriodEnd!.isAfter(now),
      SubscriptionStatus.trial => trialEnds.isAfter(now),
      SubscriptionStatus.pending ||
      SubscriptionStatus.unpaid ||
      SubscriptionStatus.scheduled ||
      SubscriptionStatus.paused ||
      SubscriptionStatus.cancelled =>
        false,
    };
  }

  /// A renewal queued up to take over once the current period ends — the
  /// result of renewing before expiry, so the family's paid-for days
  /// aren't lost. Never true at the same time as [grantsAccess] on the
  /// same row.
  bool get isUpcoming => status == SubscriptionStatus.scheduled;

  /// The date access ends (or ended) — trial end date while trialing,
  /// period end once on a paid plan. Null only for pending/unpaid rows
  /// that were never activated.
  DateTime? get expiresAt =>
      status == SubscriptionStatus.trial ? trialEnds : currentPeriodEnd;

  /// The date the current period began — the trial's creation date while
  /// trialing (there's no separate "trial start" column), the admin's
  /// activation date once on a paid plan.
  DateTime? get startsAt =>
      status == SubscriptionStatus.trial ? createdAt : currentPeriodStart;
}
