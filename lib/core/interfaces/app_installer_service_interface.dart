/// Interface contract for dispatching native package installations on Android
/// and handling browser URL fallbacks.
abstract interface class IAppInstallerService {
  /// Prompts the Android OS package installer to install an APK file located at [filePath].
  /// Returns `true` if the installer intent was launched successfully.
  Future<bool> installApk(String filePath);

  /// Checks whether the application currently has permission to install unknown apps
  /// (`REQUEST_INSTALL_PACKAGES` on Android 8.0+ / API 26+).
  Future<bool> canRequestPackageInstalls();

  /// Opens the system settings screen where the user can grant permission to install unknown apps.
  Future<bool> openInstallPermissionSettings();

  /// Fallback to launch the GitHub release web page in the external system browser.
  Future<bool> openWebRelease(String url);
}
