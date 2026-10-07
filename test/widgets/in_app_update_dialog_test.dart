import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/interfaces/app_installer_service_interface.dart';
import 'package:food_tracker/core/interfaces/app_update_service_interface.dart';
import 'package:food_tracker/models/github_release_model.dart';
import 'package:food_tracker/widgets/settings/in_app_update_dialog.dart';
import 'package:http/http.dart' as http;

class _MockUpdateService implements IAppUpdateService {
  bool downloadCalled = false;
  UpdateDownloadProgressCallback? capturedProgress;

  @override
  Future<GitHubReleaseModel?> checkLatestRelease() async => null;

  @override
  bool isUpdateAvailable(String currentVersion, String latestTag) => true;

  @override
  Future<File> downloadApk({
    required String downloadUrl,
    required String versionTag,
    UpdateDownloadProgressCallback? onProgress,
    http.Client? client,
    Directory? destinationDirectory,
  }) async {
    downloadCalled = true;
    capturedProgress = onProgress;
    onProgress?.call(0.5, 20971520, 41943040);
    return File('/tmp/test_update.apk');
  }
}

class _SlowMockUpdateService implements IAppUpdateService {
  final Completer<File> completer = Completer<File>();

  @override
  Future<GitHubReleaseModel?> checkLatestRelease() async => null;

  @override
  bool isUpdateAvailable(String currentVersion, String latestTag) => true;

  @override
  Future<File> downloadApk({
    required String downloadUrl,
    required String versionTag,
    UpdateDownloadProgressCallback? onProgress,
    http.Client? client,
    Directory? destinationDirectory,
  }) {
    onProgress?.call(0.2, 1000, 5000);
    return completer.future;
  }
}

class _FailingMockUpdateService implements IAppUpdateService {
  final Exception errorToThrow;
  _FailingMockUpdateService(this.errorToThrow);

  @override
  Future<GitHubReleaseModel?> checkLatestRelease() async => null;

  @override
  bool isUpdateAvailable(String currentVersion, String latestTag) => true;

  @override
  Future<File> downloadApk({
    required String downloadUrl,
    required String versionTag,
    UpdateDownloadProgressCallback? onProgress,
    http.Client? client,
    Directory? destinationDirectory,
  }) async => throw errorToThrow;
}

class _MockInstallerService implements IAppInstallerService {
  String? installedPath;
  String? openedWebUrl;

  @override
  Future<bool> installApk(String filePath) async {
    installedPath = filePath;
    return true;
  }

  @override
  Future<bool> canRequestPackageInstalls() async => true;

  @override
  Future<bool> openInstallPermissionSettings() async => true;

  @override
  Future<bool> openWebRelease(String url) async {
    openedWebUrl = url;
    return true;
  }
}

void main() {
  group('InAppUpdateDialog Widget Tests', () {
    final testRelease = GitHubReleaseModel(
      tagName: 'v1.3.0',
      title: 'v1.3.0 - Microinteracciones y Auto-Actualizador',
      releaseNotes: '### Novedades\n- Auto actualizador nativo\n- Animaciones elásticas',
      apkDownloadUrl: 'https://github.com/owner/repo/releases/download/v1.3.0/app-release.apk',
      apkSizeBytes: 41943040,
      publishedAt: DateTime.now(),
      htmlUrl: 'https://github.com/owner/repo/releases/tag/v1.3.0',
    );

    testWidgets('renders dialog with release notes, version tag, and action buttons', (tester) async {
      final mockUpdate = _MockUpdateService();
      final mockInstaller = _MockInstallerService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              release: testRelease,
              updateService: mockUpdate,
              installerService: mockInstaller,
            ),
          ),
        ),
      );

      expect(find.text('Actualización Disponible'), findsOneWidget);
      expect(find.text('v1.3.0'), findsOneWidget);
      expect(find.textContaining('40.0 MB'), findsOneWidget);
      expect(find.textContaining('Auto actualizador nativo'), findsOneWidget);
      expect(find.byKey(const Key('start_in_app_update_button')), findsOneWidget);
      expect(find.text('Actualizar Ahora'), findsOneWidget);
      expect(find.text('Más tarde'), findsOneWidget);
      expect(find.text('Ver en GitHub'), findsOneWidget);
    });

    testWidgets('tapping Actualizar Ahora triggers download and calls installApk upon completion', (tester) async {
      final mockUpdate = _MockUpdateService();
      final mockInstaller = _MockInstallerService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              release: testRelease,
              updateService: mockUpdate,
              installerService: mockInstaller,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('start_in_app_update_button')));
      await tester.pumpAndSettle();

      expect(mockUpdate.downloadCalled, isTrue);
      expect(mockInstaller.installedPath, equals('/tmp/test_update.apk'));
    });

    testWidgets('tapping Abrir en Navegador when no APK asset invokes openWebRelease', (tester) async {
      final noApkRelease = GitHubReleaseModel(
        tagName: 'v1.3.0',
        title: 'Release Title',
        releaseNotes: 'Notas',
        publishedAt: DateTime.now(),
        htmlUrl: 'https://github.com/owner/repo/releases/tag/v1.3.0',
      );
      final mockUpdate = _MockUpdateService();
      final mockInstaller = _MockInstallerService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              release: noApkRelease,
              updateService: mockUpdate,
              installerService: mockInstaller,
            ),
          ),
        ),
      );

      expect(find.text('Abrir en Navegador'), findsOneWidget);
      await tester.tap(find.text('Abrir en Navegador'));
      await tester.pumpAndSettle();

      expect(mockInstaller.openedWebUrl, equals('https://github.com/owner/repo/releases/tag/v1.3.0'));
      expect(mockUpdate.downloadCalled, isFalse);
    });

    testWidgets('tapping Cancelar descarga pauses/cancels download gracefully', (tester) async {
      final slowMock = _SlowMockUpdateService();
      final mockInstaller = _MockInstallerService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              release: testRelease,
              updateService: slowMock,
              installerService: mockInstaller,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('start_in_app_update_button')));
      await tester.pump();

      expect(find.byKey(const Key('cancel_download_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel_download_button')));
      await tester.pump();

      expect(find.textContaining('cancelada'), findsOneWidget);
      expect(find.byKey(const Key('start_in_app_update_button')), findsOneWidget);
    });

    testWidgets('sanitizes long presigned AWS/Azure URLs from error messages', (tester) async {
      final failingMock = _FailingMockUpdateService(
        HttpException(
          'Fallo al descargar el archivo APK (HTTP 403)',
          uri: Uri.parse('https://objects.githubusercontent.com/github-production-release-asset-2e65be/12345?AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&Signature=vjbyPxybdZaNmGa%2ByT272YEAiv4%3D'),
        ),
      );
      final mockInstaller = _MockInstallerService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppUpdateDialog(
              release: testRelease,
              updateService: failingMock,
              installerService: mockInstaller,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('start_in_app_update_button')));
      await tester.pumpAndSettle();

      expect(find.text('Fallo al descargar el archivo APK (HTTP 403)'), findsOneWidget);
      expect(find.textContaining('AWSAccessKeyId'), findsNothing);
      expect(find.textContaining('objects.githubusercontent.com'), findsNothing);
    });
  });
}
