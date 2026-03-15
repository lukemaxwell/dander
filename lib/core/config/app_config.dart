/// Application-level configuration constants.
///
/// API keys are injected at build time via `--dart-define` so they never
/// appear in source control:
///
/// ```
/// flutter run \
///   --dart-define=RC_IOS_API_KEY=appl_... \
///   --dart-define=RC_ANDROID_API_KEY=goog_...
/// ```
///
/// A missing key is detected at startup by [AppConfig.validate].
abstract final class AppConfig {
  /// RevenueCat API key for the iOS (App Store) app.
  ///
  /// Supplied via `--dart-define=RC_IOS_API_KEY=<value>` at build time.
  static const String revenueCatIosApiKey =
      String.fromEnvironment('RC_IOS_API_KEY');

  /// RevenueCat API key for the Android (Play Store) app.
  ///
  /// Supplied via `--dart-define=RC_ANDROID_API_KEY=<value>` at build time.
  static const String revenueCatAndroidApiKey =
      String.fromEnvironment('RC_ANDROID_API_KEY');

  /// Throws [StateError] in release builds if any required key is absent.
  ///
  /// Call once from `main()` before [setupLocator].
  static void validate() {
    assert(
      revenueCatIosApiKey.isNotEmpty,
      'Missing build-time constant RC_IOS_API_KEY. '
      'Pass --dart-define=RC_IOS_API_KEY=<value> when building.',
    );
    assert(
      revenueCatAndroidApiKey.isNotEmpty,
      'Missing build-time constant RC_ANDROID_API_KEY. '
      'Pass --dart-define=RC_ANDROID_API_KEY=<value> when building.',
    );
  }
}
