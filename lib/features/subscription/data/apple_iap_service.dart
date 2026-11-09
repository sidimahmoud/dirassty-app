import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/models/plan.dart';

/// A plan as sold on iOS: our [Plan] + its App Store product (Apple's
/// price, in the buyer's own currency — the only price iOS may show).
class AppleOffer {
  const AppleOffer({required this.plan, required this.product});

  final Plan plan;
  final ProductDetails product;
}

/// Apple In-App Purchase (App Store rule 3.1.1, migration 081).
///
/// Plans are App Store "non-renewing subscriptions" (one product per
/// plan, `plans.apple_product_id`). A purchase carries the student's id as
/// `applicationUsername` (Apple's appAccountToken), and access is granted
/// only by the `apple-iap-verify` Edge Function after Apple confirms the
/// transaction — the app never activates anything itself. A transaction
/// is finished only once that succeeded, so a purchase interrupted by a
/// lost connection is delivered again at the next launch and retried.
class AppleIapService {
  AppleIapService(this._client) {
    InAppPurchaseStoreKitPlatform.registerPlatform();
  }

  final SupabaseClient _client;

  InAppPurchaseStoreKitPlatform get _store =>
      InAppPurchasePlatform.instance as InAppPurchaseStoreKitPlatform;

  Stream<List<PurchaseDetails>> get purchases => _store.purchaseStream;

  /// Plans that have an App Store product Apple knows about, in plan order.
  Future<List<AppleOffer>> loadOffers(List<Plan> plans) async {
    final List<Plan> sold =
        plans.where((p) => (p.appleProductId ?? '').isNotEmpty).toList();
    if (sold.isEmpty || !await _store.isAvailable()) return const [];
    final ProductDetailsResponse response = await _store.queryProductDetails(
      sold.map((p) => p.appleProductId!).toSet(),
    );
    final Map<String, ProductDetails> byId = {
      for (final ProductDetails d in response.productDetails) d.id: d,
    };
    return [
      for (final Plan p in sold)
        if (byId[p.appleProductId] != null)
          AppleOffer(plan: p, product: byId[p.appleProductId]!),
    ];
  }

  /// Opens Apple's payment sheet. The result arrives on [purchases].
  Future<void> buy(AppleOffer offer, String studentId) async {
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: offer.product,
        applicationUserName: studentId,
      ),
    );
  }

  /// "Restaurer mes achats": re-delivers anything Apple still has for this
  /// Apple ID. Non-renewing passes live on the Dirassty account itself, so
  /// signing in on any device already restores them.
  Future<void> restore() => _store.restorePurchases();

  Future<void> finish(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _store.completePurchase(purchase);
    }
  }

  /// The student a purchase was made for (its applicationUsername).
  String? studentIdOf(PurchaseDetails purchase) {
    if (purchase is AppStorePurchaseDetails) {
      return purchase.skPaymentTransaction.payment.applicationUsername;
    }
    return null;
  }

  /// Asks our server to check the transaction with Apple and unlock the
  /// student. Throws [AppleIapException] with the server's error code.
  Future<void> verify({
    required String transactionId,
    required String studentId,
  }) async {
    final String? token = _client.auth.currentSession?.accessToken;
    if (token == null) throw const AppleIapException('not_signed_in');
    final http.Response response = await http
        .post(
          Uri.parse('${SupabaseConfig.url}/functions/v1/apple-iap-verify'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'transaction_id': transactionId,
            'student_id': studentId,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String code = 'server_error';
    try {
      code = (jsonDecode(response.body) as Map<String, dynamic>)['error']
              ?.toString() ??
          code;
    } catch (_) {}
    throw AppleIapException(code);
  }
}

class AppleIapException implements Exception {
  const AppleIapException(this.code);

  final String code;

  /// Errors where retrying later can't help (refunded, made for another
  /// student, another app): the transaction is finished so it isn't
  /// re-delivered forever. Anything else (no connection, plan not set up
  /// yet in Admin → Plans, someone else signed in) stays unfinished so the
  /// paid purchase is retried at the next launch, never lost.
  bool get isFinal =>
      const {'other_account', 'refunded', 'wrong_app'}.contains(code);

  @override
  String toString() => 'AppleIapException($code)';
}
