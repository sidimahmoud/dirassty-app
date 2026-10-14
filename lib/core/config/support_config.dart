/// Support contact details for the Profile screen's "Contact us" action.
abstract final class SupportConfig {
  /// Support's WhatsApp number (+222 33 30 60 60), digits only for wa.me.
  /// Override with `--dart-define=SUPPORT_WHATSAPP_NUMBER=...`.
  static const String whatsappNumber = String.fromEnvironment(
    'SUPPORT_WHATSAPP_NUMBER',
    defaultValue: '22233306060',
  );

  /// Bankily merchant number shown (with Copy) on the payment screen.
  /// Empty by default — the row is hidden until one is provided with
  /// `--dart-define=BANKILY_MERCHANT_NUMBER=...`.
  static const String bankilyMerchantNumber = String.fromEnvironment(
    'BANKILY_MERCHANT_NUMBER',
  );
}
