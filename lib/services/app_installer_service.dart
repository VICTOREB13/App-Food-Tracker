import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/interfaces/app_installer_service_interface.dart';

/// Service implementing native APK installation via Android MethodChannel
/// and external web browser fallbacks via url_launcher.
class AppInstallerService implements IAppInstallerService {
  static AppInstallerService? _instance;
  static AppInstallerService get instance => _instance ??= AppInstallerService();

  static const String channelName = 'com.victorengineer.foodtracker/app_installer';
  final MethodChannel _channel;

  AppInstallerService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  @override
  Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) {
      debugPrint('[AppInstallerService] installApk is only supported on Android.');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AppInstallerService] Error invoking installApk: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppInstallerService] Unexpected error in installApk: $e');
      return false;
    }
  }

  @override
  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint('[AppInstallerService] Error invoking canRequestPackageInstalls: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppInstallerService] Unexpected error in canRequestPackageInstalls: $e');
      return false;
    }
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AppInstallerService] Error invoking openInstallPermissionSettings: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppInstallerService] Unexpected error in openInstallPermissionSettings: $e');
      return false;
    }
  }

  @override
  Future<bool> openWebRelease(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return false;
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppInstallerService] Error launching web release URL: $e');
      return false;
    }
  }
}
