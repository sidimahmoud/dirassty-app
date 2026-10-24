import 'package:flutter/foundation.dart';

/// A way to pay listed on the payment screen (Admin → Paramètres →
/// Moyens de paiement, `payment_methods`, migration 075): its name, the
/// number / code to send the money to, and its logo.
@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.kind,
    this.logoUrl,
  });

  factory PaymentMethod.fromJson(
    Map<String, dynamic> json, {
    required String? Function(String path) logoUrlFor,
  }) {
    final String? logoPath = json['logo_path'] as String?;
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      accountNumber: (json['account_number'] as String).trim(),
      kind: json['kind'] as String? ?? 'transfer',
      logoUrl:
          logoPath == null || logoPath.isEmpty ? null : logoUrlFor(logoPath),
    );
  }

  /// Bankily from the settings row, for a backend without migration 075
  /// (no `payment_methods` table yet). No id: sent as plain 'bankily'.
  factory PaymentMethod.legacyBankily(String number) => PaymentMethod(
        id: null,
        name: 'Bankily',
        accountNumber: number,
        kind: 'bankily',
      );

  /// Null only for [PaymentMethod.legacyBankily].
  final String? id;
  final String name;
  final String accountNumber;

  /// 'bankily' or 'transfer' — what `request_subscriptions()` records as
  /// the payment method (with [id]).
  final String kind;
  final String? logoUrl;
}
