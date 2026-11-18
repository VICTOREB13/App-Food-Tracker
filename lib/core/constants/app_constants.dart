/// Centralized application constants.
class AppConstants {
  /// Canonical semantic version of the application matching pubspec.yaml.
  /// Dynamically reads from compile-time --dart-define 'APP_VERSION', with fallback to latest version.
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.5.3');
}
