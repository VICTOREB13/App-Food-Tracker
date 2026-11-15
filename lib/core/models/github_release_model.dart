import 'package:flutter/foundation.dart';

/// Immutable model representing a release published on GitHub Releases.
@immutable
class GitHubReleaseModel {
  /// The Git tag name associated with the release (e.g. 'v1.3.0').
  final String tagName;

  /// The display title of the release.
  final String title;

  /// Markdown release notes and changelog describing changes.
  final String releaseNotes;

  /// Direct browser download URL for the standalone APK asset, if available.
  final String? apkDownloadUrl;

  /// Size of the APK binary in bytes, if available.
  final int? apkSizeBytes;

  /// Timestamp when the release was published on GitHub.
  final DateTime publishedAt;

  /// Web URL pointing to the release page on GitHub.
  final String htmlUrl;

  const GitHubReleaseModel({
    required this.tagName,
    required this.title,
    required this.releaseNotes,
    this.apkDownloadUrl,
    this.apkSizeBytes,
    required this.publishedAt,
    required this.htmlUrl,
  });

  /// Factory parser for GitHub Releases REST API payload.
  factory GitHubReleaseModel.fromJson(Map<String, dynamic> json) {
    final rawTag = (json['tag_name'] as String?)?.trim() ?? '';
    final rawTitle = (json['name'] as String?)?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty) ? rawTitle : (rawTag.isNotEmpty ? rawTag : 'Release');
    final releaseNotes = (json['body'] as String?) ?? '';
    final htmlUrl = (json['html_url'] as String?) ?? '';
    final publishedAtStr = json['published_at'] as String?;
    final publishedAt = (publishedAtStr != null)
        ? (DateTime.tryParse(publishedAtStr) ?? DateTime.now())
        : DateTime.now();

    String? apkUrl;
    int? apkSize;

    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final assetName = (asset['name'] as String?)?.toLowerCase() ?? '';
          if (assetName.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkSize = asset['size'] as int?;
            break;
          }
        }
      }
    }

    return GitHubReleaseModel(
      tagName: rawTag,
      title: title,
      releaseNotes: releaseNotes,
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      publishedAt: publishedAt,
      htmlUrl: htmlUrl,
    );
  }

  /// Whether an APK asset is available for in-app download and installation.
  bool get hasApk => apkDownloadUrl != null && apkDownloadUrl!.isNotEmpty;

  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson() => {
    'tag_name': tagName,
    'title': title,
    'release_notes': releaseNotes,
    'apk_download_url': apkDownloadUrl,
    'apk_size_bytes': apkSizeBytes,
    'published_at': publishedAt.toIso8601String(),
    'html_url': htmlUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubReleaseModel &&
          runtimeType == other.runtimeType &&
          tagName == other.tagName &&
          apkDownloadUrl == other.apkDownloadUrl;

  @override
  int get hashCode => tagName.hashCode ^ apkDownloadUrl.hashCode;

  @override
  String toString() => 'GitHubReleaseModel(tag: $tagName, title: $title, hasApk: $hasApk)';
}
