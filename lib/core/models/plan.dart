import 'package:flutter/foundation.dart';

/// One admin-configurable subscription plan — price, duration, and
/// whether it's currently offered at all live in the `plans` table (see
/// supabase/migrations/018_configurable_plans.sql), edited from the web
/// admin's Plans page. The app always fetches this list rather than
/// hardcoding tiers, so an admin changing a price or disabling a plan
/// takes effect immediately with no app update.
@immutable
class Plan {
  const Plan({
    required this.id,
    required this.key,
    required this.nameFr,
    required this.nameAr,
    required this.durationDays,
    required this.priceMru,
    required this.discountPercent,
    required this.isActive,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      key: json['key'] as String,
      nameFr: json['name_fr'] as String,
      nameAr: json['name_ar'] as String,
      durationDays: json['duration_days'] as int,
      priceMru: (json['price_mru'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String key;
  final String nameFr;
  final String nameAr;
  final int durationDays;
  final double priceMru;

  /// 0–100. A promotional discount set by the admin — see [effectivePriceMru].
  final double discountPercent;
  final bool isActive;

  String name(bool isArabic) => isArabic ? nameAr : nameFr;

  bool get hasDiscount => discountPercent > 0;

  /// The price a student/parent actually pays — always whole MRU (no
  /// fractional currency in this app).
  double get effectivePriceMru =>
      (priceMru * (1 - discountPercent / 100)).roundToDouble();
}
