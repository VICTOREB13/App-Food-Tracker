import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/github_release_model.dart';

/// Progress callback for binary APK downloads.
/// [ratio] is between 0.0 and 1.0 (or 0.0 if total length is unknown).
typedef UpdateDownloadProgressCallback = void Function(
  double ratio,
  int receivedBytes,
  int totalBytes,
);

/// Interface contract for querying GitHub Releases and downloading app updates.
abstract interface class IAppUpdateService {
  /// Fetches the latest published release metadata from GitHub Releases API.
  /// Returns `null` if the repository has no releases or if network is offline.
  Future<GitHubReleaseModel?> checkLatestRelease();

  /// Compares semantic versions, returning `true` if [latestTag] is newer than [currentVersion].
  /// Cleans leading 'v'/'V' and metadata suffixes like '+1'.
  bool isUpdateAvailable(String currentVersion, String latestTag);

  /// Downloads the standalone APK from [downloadUrl] by streaming into the application's
  /// cache updates directory (`cache/updates/update_vX.Y.Z.apk`).
  /// Reports real-time download progression via [onProgress].
  Future<File> downloadApk({
    required String downloadUrl,
    required String versionTag,
    UpdateDownloadProgressCallback? onProgress,
    http.Client? client,
    Directory? destinationDirectory,
  });
}
