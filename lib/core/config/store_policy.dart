import 'package:flutter/foundation.dart';

/// App Store rule 3.1.1: on iOS (iPhone and iPad) access is sold only
/// with Apple's In-App Purchase, and the app never points to another way
/// to pay (no Bankily, transfer, WhatsApp payment, website, or MRU price).
/// Accounts paid outside the app still open on iOS (rule 3.1.3(b)).
/// Android keeps the transfer / manual payment flow. See
/// docs/mobile-releases.md §7.
abstract final class StorePolicy {
  /// The Android-style payment flow (payment methods, proof screenshot,
  /// manual payment over WhatsApp, MRU prices). Never on iOS.
  static bool get inAppSalesAllowed =>
      defaultTargetPlatform != TargetPlatform.iOS;

  /// Plans are bought with Apple In-App Purchase (AppleSubscribeScreen).
  static bool get usesAppleInAppPurchase =>
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Some way to subscribe exists inside the app on this platform.
  static bool get canSubscribeInApp => true;
}
