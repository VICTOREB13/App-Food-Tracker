import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:food_tracker/models/github_release_model.dart';
import 'package:food_tracker/services/app_update_service.dart';
import 'package:food_tracker/services/app_installer_service.dart';

/// Lightweight mock HTTP client for deterministic unit testing.
class MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  group('GitHubReleaseModel Tests', () {
    test('parses official GitHub release JSON with APK asset', () {
      final jsonPayload = {
        'tag_name': 'v1.3.0', 'name': 'v1.3.0 - Auto-Actualizador In-App',
        'body': '## Novedades\n- Sistema de actualización automática.',
        'html_url': 'https://github.com/VICTOREB13/App-Food-Tracker/releases/tag/v1.3.0',
        'published_at': '2026-10-06T12:00:00Z',
        'assets': [
          {'name': 'source.zip', 'browser_download_url': 'https://example.com/source.zip', 'size': 1024},
          {'name': 'app-release.apk', 'browser_download_url': 'https://github.com/releases/download/v1.3.0/app-release.apk', 'size': 25600000},
        ],
      };
      final release = GitHubReleaseModel.fromJson(jsonPayload);

      expect(release.tagName, equals('v1.3.0'));
      expect(release.title, equals('v1.3.0 - Auto-Actualizador In-App'));
      expect(release.releaseNotes, contains('Sistema de actualización automática'));
      expect(release.htmlUrl, equals('https://github.com/VICTOREB13/App-Food-Tracker/releases/tag/v1.3.0'));
      expect(release.publishedAt.year, equals(2026));
      expect(release.hasApk, isTrue);
      expect(release.apkDownloadUrl, equals('https://github.com/releases/download/v1.3.0/app-release.apk'));
      expect(release.apkSizeBytes, equals(25600000));
    });

    test('parses release without APK assets gracefully', () {
      final jsonPayload = {
        'tag_name': 'v1.2.0', 'name': '', 'body': 'Sin APK adjunto',
        'html_url': 'https://github.com/releases/v1.2.0',
        'published_at': '2026-09-01T00:00:00Z', 'assets': <Map<String, dynamic>>[],
      };
      final release = GitHubReleaseModel.fromJson(jsonPayload);
      expect(release.tagName, equals('v1.2.0'));
      expect(release.title, equals('v1.2.0'));
      expect(release.hasApk, isFalse);
      expect(release.apkDownloadUrl, isNull);
      expect(release.apkSizeBytes, isNull);
    });

    test('serializes to JSON cleanly', () {
      final model = GitHubReleaseModel(
        tagName: 'v1.3.0', title: 'Release 1.3.0', releaseNotes: 'Notas',
        apkDownloadUrl: 'https://apk.url', apkSizeBytes: 5000,
        publishedAt: DateTime(2026, 10, 6), htmlUrl: 'https://release.url',
      );
      final map = model.toJson();
      expect(map['tag_name'], equals('v1.3.0'));
      expect(map['apk_download_url'], equals('https://apk.url'));
      expect(map['apk_size_bytes'], equals(5000));
    });
  });

  group('AppUpdateService SemVer Comparison Tests', () {
    late AppUpdateService service;
    setUp(() => service = AppUpdateService());

    test('detects newer minor/major/patch version', () {
      expect(service.isUpdateAvailable('1.2.5', 'v1.3.0'), isTrue);
      expect(service.isUpdateAvailable('1.9.9', 'v2.0.0'), isTrue);
      expect(service.isUpdateAvailable('1.2.5', '1.2.6'), isTrue);
    });

    test('returns false when latest tag matches or is older than current version', () {
      expect(service.isUpdateAvailable('1.2.5', '1.2.5'), isFalse);
      expect(service.isUpdateAvailable('1.2.5', 'v1.2.5'), isFalse);
      expect(service.isUpdateAvailable('v1.2.5', '1.2.5'), isFalse);
      expect(service.isUpdateAvailable('1.2.5', 'v1.2.4'), isFalse);
      expect(service.isUpdateAvailable('2.0.0', 'v1.9.9'), isFalse);
    });

    test('handles build suffixes, revisions, and empty strings', () {
      expect(service.isUpdateAvailable('1.2.5+1', 'v1.3.0+2'), isTrue);
      expect(service.isUpdateAvailable('1.2.5+2', 'v1.2.5+1'), isFalse);
      expect(service.isUpdateAvailable('1.2.5', '1.2.5.1'), isTrue);
      expect(service.isUpdateAvailable('1.2.5.2', '1.2.5.1'), isFalse);
      expect(service.isUpdateAvailable('', 'v1.0.0'), isTrue);
      expect(service.isUpdateAvailable('1.0.0', ''), isFalse);
    });
  });

  group('AppUpdateService checkLatestRelease Network Tests', () {
    test('successfully fetches and parses latest release on HTTP 200', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, endsWith('/releases/latest'));
        expect(request.headers['Accept'], equals('application/vnd.github.v3+json'));
        expect(request.headers['User-Agent'], equals('VictorEngineer-FoodTracker'));

        final body = json.encode({
          'tag_name': 'v1.3.0', 'name': 'v1.3.0 - Update', 'body': 'Changelog',
          'html_url': 'https://github.com/release/1.3.0', 'published_at': '2026-10-06T10:00:00Z',
          'assets': [{'name': 'food-tracker.apk', 'browser_download_url': 'https://download.apk', 'size': 12345678}],
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(body)), 200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AppUpdateService(client: mockClient);
      final release = await service.checkLatestRelease();

      expect(release, isNotNull);
      expect(release!.tagName, equals('v1.3.0'));
      expect(release.apkDownloadUrl, equals('https://download.apk'));
    });

    test('returns null when GitHub returns 404 (no releases published)', () async {
      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 404);
      });

      final service = AppUpdateService(client: mockClient);
      final release = await service.checkLatestRelease();

      expect(release, isNull);
    });

    test('throws HttpException on server errors (e.g. HTTP 500)', () async {
      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(Stream.value(utf8.encode('Server Error')), 500);
      });

      final service = AppUpdateService(client: mockClient);

      expect(() => service.checkLatestRelease(), throwsA(isA<HttpException>()));
    });
  });

  group('AppUpdateService downloadApk Streaming Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('app_update_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('streams binary APK chunks and reports progression via onProgress', () async {
      final testData = List.generate(1000, (i) => i % 256);
      final totalSize = testData.length;
      final mockClient = MockHttpClient((request) async {
        expect(request.url.toString(), equals('https://github.com/download/app.apk'));
        final stream = Stream.fromIterable([
          testData.sublist(0, 250), testData.sublist(250, 500),
          testData.sublist(500, 750), testData.sublist(750, 1000),
        ]);
        return http.StreamedResponse(stream, 200, contentLength: totalSize);
      });

      final progressRatios = <double>[];
      final receivedBytesList = <int>[];
      final service = AppUpdateService(client: mockClient, baseDirectoryProvider: () async => tempDir);
      final file = await service.downloadApk(
        downloadUrl: 'https://github.com/download/app.apk',
        versionTag: 'v1.3.0',
        destinationDirectory: tempDir,
        onProgress: (ratio, received, total) {
          progressRatios.add(ratio);
          receivedBytesList.add(received);
          expect(total, equals(totalSize));
        },
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), equals(totalSize));
      expect(file.path, endsWith('update_v1.3.0.apk'));
      expect(progressRatios, isNotEmpty);
      expect(progressRatios.last, equals(1.0));
      expect(receivedBytesList.last, equals(totalSize));
    });

    test('throws HttpException if APK download responds with HTTP error code', () async {
      final mockClient = MockHttpClient((request) async => http.StreamedResponse(Stream.value([]), 403));
      final service = AppUpdateService(client: mockClient);
      expect(
        () => service.downloadApk(
          downloadUrl: 'https://github.com/download/forbidden.apk',
          versionTag: 'v1.3.0',
          destinationDirectory: tempDir,
        ),
        throwsA(isA<HttpException>()),
      );
    });

    test('resumes interrupted download sending Range header and appending on HTTP 206', () async {
      final partFile = File(path.join(tempDir.path, 'update_v1.3.0.apk.part'));
      final initialBytes = List.generate(500, (i) => i % 256);
      await partFile.writeAsBytes(initialBytes);
      final remainingBytes = List.generate(500, (i) => (i + 500) % 256);
      const totalSize = 1000;

      final mockClient = MockHttpClient((request) async {
        expect(request.headers['Range'], equals('bytes=500-'));
        return http.StreamedResponse(
          Stream.value(remainingBytes),
          206,
          contentLength: 500,
          headers: {'content-range': 'bytes 500-999/1000'},
        );
      });

      final service = AppUpdateService(client: mockClient, baseDirectoryProvider: () async => tempDir);
      final file = await service.downloadApk(
        downloadUrl: 'https://github.com/download/app.apk',
        versionTag: 'v1.3.0',
        destinationDirectory: tempDir,
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), equals(totalSize));
      expect(await partFile.exists(), isFalse);
    });

    test('recovers from HTTP 416 Range Not Satisfiable by deleting .part and restarting from 0', () async {
      final partFile = File(path.join(tempDir.path, 'update_v1.3.0.apk.part'));
      await partFile.writeAsBytes(List.generate(2000, (i) => 1));
      int requestCount = 0;
      final fullBytes = List.generate(1000, (i) => i % 256);

      final mockClient = MockHttpClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          expect(request.headers['Range'], equals('bytes=2000-'));
          return http.StreamedResponse(Stream.value([]), 416);
        }
        expect(request.headers.containsKey('Range'), isFalse);
        return http.StreamedResponse(Stream.value(fullBytes), 200, contentLength: 1000);
      });

      final service = AppUpdateService(client: mockClient, baseDirectoryProvider: () async => tempDir);
      final file = await service.downloadApk(
        downloadUrl: 'https://github.com/download/app.apk',
        versionTag: 'v1.3.0',
        destinationDirectory: tempDir,
      );

      expect(requestCount, equals(2));
      expect(await file.exists(), isTrue);
      expect(await file.length(), equals(1000));
      expect(await partFile.exists(), isFalse);
    });

    test('overwrites existing .part file from byte 0 when server ignores Range and responds 200', () async {
      final partFile = File(path.join(tempDir.path, 'update_v1.3.0.apk.part'));
      await partFile.writeAsBytes(List.generate(300, (i) => 99));
      final fullBytes = List.generate(1000, (i) => i % 256);
      final mockClient = MockHttpClient((request) async =>
          http.StreamedResponse(Stream.value(fullBytes), 200, contentLength: 1000));

      final service = AppUpdateService(client: mockClient, baseDirectoryProvider: () async => tempDir);
      final file = await service.downloadApk(
        downloadUrl: 'https://github.com/download/app.apk',
        versionTag: 'v1.3.0',
        destinationDirectory: tempDir,
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), equals(1000));
      expect(await partFile.exists(), isFalse);
    });
  });

  group('AppInstallerService Web Release Fallback Tests', () {
    test('openWebRelease gracefully rejects invalid URIs', () async {
      final installer = AppInstallerService();
      final result = await installer.openWebRelease(':::invalid-uri:::');
      expect(result, isFalse);
    });
  });
}
