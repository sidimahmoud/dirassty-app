import 'package:flutter/foundation.dart';

/// App Store rule 3.1.1: on iOS (iPhone and iPad) the app may not sell
/// access without Apple's In-App Purchase, nor point users to another way
/// to pay (no prices, payment methods, "subscribe" buttons, or messages
/// asking someone to pay). So on iOS the app only shows the state of an
/// account; iOS users pay manually through support on WhatsApp (or a
/// parent pays on Android), and the account unlocks on its own. Android
/// keeps the full subscribe flow. See docs/mobile-releases.md §7.
abstract final class StorePolicy {
  static bool get inAppSalesAllowed =>
      defaultTargetPlatform != TargetPlatform.iOS;
}
