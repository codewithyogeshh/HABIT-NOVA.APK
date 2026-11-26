/// Configuration for the in-app "update available" prompt.
///
/// The app compares its own version with a small JSON manifest hosted online.
/// No Play Store involved, so an APK installed manually also learns about new
/// builds.
///
/// Override the manifest URL for testing/staging without touching code:
///
/// ```bash
/// flutter build apk --dart-define=UPDATE_MANIFEST_URL=https://example.com/version.json
/// ```
class AppUpdateConfig {
  AppUpdateConfig._();

  /// Remote JSON manifest describing the newest published build.
  /// Edit `version.json` in the repository and the raw URL below serves it.
  static const String manifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue:
        'https://raw.githubusercontent.com/codewithyogeshh/HABIT-NOVA.APK/main/version.json',
  );

  /// How long to wait for the manifest before giving up silently.
  static const Duration requestTimeout = Duration(seconds: 8);

  /// Don't hit the network more often than this.
  static const Duration checkInterval = Duration(hours: 6);

  /// How long "Later" hides the prompt for.
  static const Duration snoozeDuration = Duration(hours: 24);

  // SharedPreferences keys (namespaced so they never clash with app settings).
  static const String lastCheckKey = 'app_update_last_check_v1';
  static const String snoozeKey = 'app_update_snoozed_until_v1';
}
