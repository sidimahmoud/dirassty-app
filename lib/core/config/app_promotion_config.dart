/// Links used by the Profile screen's "Share app" and "Rate app" actions.
abstract final class AppPromotionConfig {
  /// The production web app — real and live today, unlike the store
  /// listings below, so "share the app" has something genuine to point
  /// to even before the mobile app itself is published. Matches
  /// apps/web/.env.local's NEXT_PUBLIC_APP_URL.
  static const String shareUrl = String.fromEnvironment(
    'APP_SHARE_URL',
    defaultValue: 'https://dirassty.vercel.app',
  );

  /// Public privacy policy (apps/web/app/confidentialite) — linked from
  /// sign-up and About, and given to both stores.
  static const String privacyPolicyUrl = '$shareUrl/confidentialite';

  /// Empty until the app is actually published to each store — callers
  /// must check [isPublishedOnAnyStore] and show a "coming soon" message
  /// instead of attempting a link that goes nowhere.
  static const String iosAppStoreId = String.fromEnvironment(
    'IOS_APP_STORE_ID',
    defaultValue: '',
  );
  static const String androidPackageName = String.fromEnvironment(
    'ANDROID_PACKAGE_NAME',
    defaultValue: '',
  );

  static bool get isPublishedOnAnyStore =>
      iosAppStoreId.isNotEmpty || androidPackageName.isNotEmpty;
}
