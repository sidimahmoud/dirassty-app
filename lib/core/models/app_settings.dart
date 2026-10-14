import 'package:flutter/foundation.dart';

import 'plan.dart';

/// Singleton row — app-wide settings an admin controls from the web
/// panel's Plans page. See supabase/migrations/020_trial_toggle.sql and
/// 045_family_discount.sql.
@immutable
class AppSettings {
  const AppSettings({
    required this.trialEnabled,
    required this.trialDurationDays,
    this.familyDiscountEnabled = false,
    this.familyDiscount2Percent = 0,
    this.familyDiscount3Percent = 0,
    this.bankilyMerchantNumber,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      trialEnabled: json['trial_enabled'] as bool,
      trialDurationDays: json['trial_duration_days'] as int,
      // Absent until migration 045 is applied → no family discount shown.
      familyDiscountEnabled: json['family_discount_enabled'] as bool? ?? false,
      familyDiscount2Percent:
          (json['family_discount_2_percent'] as num?)?.toDouble() ?? 0,
      familyDiscount3Percent:
          (json['family_discount_3_percent'] as num?)?.toDouble() ?? 0,
      bankilyMerchantNumber:
          (json['bankily_merchant_number'] as String?)?.trim().isEmpty ?? true
              ? null
              : (json['bankily_merchant_number'] as String).trim(),
    );
  }

  final bool trialEnabled;

  /// The Bankily number customers pay to (Admin → Paramètres, migration
  /// 064). Null until an admin sets it.
  final String? bankilyMerchantNumber;
  final int trialDurationDays;
  final bool familyDiscountEnabled;

  /// % off the 2nd child's price when 2 children are subscribed together
  /// (the first child always pays the plan's normal price).
  final double familyDiscount2Percent;

  /// % off every child after the first, from 3 children subscribed
  /// together.
  final double familyDiscount3Percent;

  /// Mirrors `family_discount_for()` in 045_family_discount.sql.
  double familyDiscountFor(int children) {
    if (!familyDiscountEnabled || children < 2) return 0;
    return children == 2 ? familyDiscount2Percent : familyDiscount3Percent;
  }

  /// Price breakdown for [children] on [plan] — the same rule and
  /// rounding as `request_subscriptions()` (046): the first child at the
  /// plan price, each other child with the family discount. The server
  /// computes the real charge; this is only for display before paying.
  FamilyQuote quote(Plan plan, int children) {
    final double planPrice = plan.effectivePriceMru;
    final double pct = familyDiscountFor(children);
    final double unit = (planPrice * (1 - pct / 100)).roundToDouble();
    return FamilyQuote(
      children: children,
      planPriceMru: planPrice,
      familyDiscountPercent: pct,
      unitPriceMru: unit,
    );
  }
}

@immutable
class FamilyQuote {
  const FamilyQuote({
    required this.children,
    required this.planPriceMru,
    required this.familyDiscountPercent,
    required this.unitPriceMru,
  });

  final int children;
  final double planPriceMru;

  /// Applied to every child except the first.
  final double familyDiscountPercent;

  /// Price of each child after the first.
  final double unitPriceMru;

  double get subtotalMru => planPriceMru * children;
  double get totalMru =>
      children == 0 ? 0 : planPriceMru + unitPriceMru * (children - 1);
  double get savingMru => subtotalMru - totalMru;
}
