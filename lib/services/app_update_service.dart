import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/interfaces/app_update_service_interface.dart';
import '../models/github_release_model.dart';

/// Service responsible for checking GitHub Releases for updates and
/// streaming binary APK downloads to the local cache directory.
class AppUpdateService implements IAppUpdateService {
  static AppUpdateService? _instance;
  static AppUpdateService get instance => _instance ??= AppUpdateService();

  final http.Client _client;
  final String _repository;
  final Future<Directory> Function()? _baseDirectoryProvider;

  static const String defaultRepository = 'VICTOREB13/App-Food-Tracker';
  static const String defaultUserAgent = 'VictorEngineer-FoodTracker';

  AppUpdateService({
    http.Client? client,
    String repository = defaultRepository,
    Future<Directory> Function()? baseDirectoryProvider,
  })  : _client = client ?? http.Client(),
        _repository = repository,
        _baseDirectoryProvider = baseDirectoryProvider;

  @override
  Future<GitHubReleaseModel?> checkLatestRelease() async {
    final uri = Uri.parse('https://api.github.com/repos/$_repository/releases/latest');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': defaultUserAgent,
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return GitHubReleaseModel.fromJson(decoded);
      }
      return null;
    } else if (response.statusCode == 404) {
      // Repository has no releases published yet
      return null;
    } else {
      throw HttpException(
        'Error al consultar actualizaciones en GitHub (HTTP ${response.statusCode})',
        uri: uri,
      );
    }
  }

  @override
  bool isUpdateAvailable(String currentVersion, String latestTag) {
    final currentSemVer = _parseSemVer(currentVersion);
    final latestSemVer = _parseSemVer(latestTag);

    final length = currentSemVer.length > latestSemVer.length
        ? currentSemVer.length
        : latestSemVer.length;

    for (int i = 0; i < length; i++) {
      final currentPart = i < currentSemVer.length ? currentSemVer[i] : 0;
      final latestPart = i < latestSemVer.length ? latestSemVer[i] : 0;

      if (latestPart > currentPart) {
        return true;
      } else if (latestPart < currentPart) {
        return false;
      }
    }

    return false;
  }

  @override
  Future<File> downloadApk({
    required String downloadUrl,
    required String versionTag,
    UpdateDownloadProgressCallback? onProgress,
    http.Client? client,
    Directory? destinationDirectory,
  }) async {
    final activeClient = client ?? _client;
    final cacheDir = destinationDirectory ?? await _getUpdatesDirectory();
    final sanitizedTag = versionTag.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final fileName = 'update_v$sanitizedTag.apk';
    final targetFile = File(path.join(cacheDir.path, fileName));
    final partFile = File(path.join(cacheDir.path, '$fileName.part'));

    int existingBytes = 0;
    if (await partFile.exists()) {
      existingBytes = await partFile.length();
    }

    final requestUri = Uri.parse(downloadUrl);
    var request = http.Request('GET', requestUri);
    request.headers['User-Agent'] = defaultUserAgent;
    if (existingBytes > 0) {
      request.headers['Range'] = 'bytes=$existingBytes-';
    }

    var streamedResponse = await activeClient.send(request);
    if (streamedResponse.statusCode == 416) {
      if (await partFile.exists()) {
        await partFile.delete();
      }
      existingBytes = 0;
      request = http.Request('GET', requestUri);
      request.headers['User-Agent'] = defaultUserAgent;
      streamedResponse = await activeClient.send(request);
    }

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      throw HttpException(
        'Fallo al descargar el archivo APK (HTTP ${streamedResponse.statusCode})',
        uri: requestUri,
      );
    }

    final isPartial = streamedResponse.statusCode == 206;
    int receivedBytes = isPartial ? existingBytes : 0;
    int totalBytes = 0;

    if (isPartial) {
      final contentRange = streamedResponse.headers['content-range'];
      if (contentRange != null) {
        final slashIndex = contentRange.lastIndexOf('/');
        if (slashIndex != -1) {
          totalBytes = int.tryParse(contentRange.substring(slashIndex + 1).trim()) ?? 0;
        }
      }
      if (totalBytes == 0 && streamedResponse.contentLength != null) {
        totalBytes = existingBytes + streamedResponse.contentLength!;
      }
    } else {
      totalBytes = streamedResponse.contentLength ?? 0;
    }

    final sink = partFile.openWrite(mode: isPartial ? FileMode.append : FileMode.write);

    try {
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (onProgress != null) {
          final ratio = totalBytes > 0
              ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;
          onProgress(ratio, receivedBytes, totalBytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await partFile.rename(targetFile.path);

    return targetFile;
  }

  Future<Directory> _getUpdatesDirectory() async {
    final baseDir = _baseDirectoryProvider != null
        ? await _baseDirectoryProvider()
        : await getTemporaryDirectory();
    final updatesDir = Directory(path.join(baseDir.path, 'updates'));
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    return updatesDir;
  }

  List<int> _parseSemVer(String raw) {
    // Clean leading 'v' or 'V'
    var text = raw.trim();
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1).trim();
    }

    // Strip build identifier suffix (+1, +build123)
    final plusIndex = text.indexOf('+');
    if (plusIndex != -1) {
      text = text.substring(0, plusIndex).trim();
    }

    // Strip pre-release suffix (-alpha, -beta.1)
    final dashIndex = text.indexOf('-');
    if (dashIndex != -1) {
      text = text.substring(0, dashIndex).trim();
    }

    if (text.isEmpty) {
      return [0, 0, 0];
    }

    final parts = text.split('.');
    final numbers = <int>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed != null) {
        numbers.add(parsed);
      } else {
        // Extract leading numeric part if mixed (e.g. '0rc1')
        final numericMatch = RegExp(r'^\d+').firstMatch(part);
        numbers.add(numericMatch != null ? int.parse(numericMatch.group(0)!) : 0);
      }
    }

    while (numbers.length < 3) {
      numbers.add(0);
    }

    return numbers;
  }
}
