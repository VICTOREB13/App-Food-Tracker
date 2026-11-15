import 'dart:io';
import 'package:flutter/foundation.dart';

/// Status of the data backup and restore operations.
enum BackupStatus {
  idle,
  exporting,
  picking,
  inspecting,
  restoring,
  success,
  error;
}

/// Operation type being executed in the backup pipeline.
enum BackupOperationType {
  none,
  export,
  restore,
  inspect;
}

/// Metadata summary of a backup file or exported snapshot.
@immutable
class BackupMetadata {
  final String path;
  final String filename;
  final int sizeBytes;
  final String? exportDate;
  final int mealsCount;
  final int pantryCount;
  final int weightLogsCount;
  final bool hasUserProfile;

  const BackupMetadata({
    required this.path,
    required this.filename,
    required this.sizeBytes,
    this.exportDate,
    this.mealsCount = 0,
    this.pantryCount = 0,
    this.weightLogsCount = 0,
    this.hasUserProfile = false,
  });

  /// Human-readable file size in Kilobytes.
  String get fileSizeKb => (sizeBytes / 1024).toStringAsFixed(1);

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      path: (map['path'] as String?) ?? '',
      filename: (map['filename'] as String?) ?? '',
      sizeBytes: (map['size_bytes'] as num?)?.toInt() ?? 0,
      exportDate: map['export_date'] as String?,
      mealsCount: (map['meals_count'] as num?)?.toInt() ?? 0,
      pantryCount: (map['pantry_count'] as num?)?.toInt() ?? 0,
      weightLogsCount: (map['weight_logs_count'] as num?)?.toInt() ?? 0,
      hasUserProfile: (map['has_user_profile'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'path': path,
    'filename': filename,
    'size_bytes': sizeBytes,
    'export_date': exportDate,
    'meals_count': mealsCount,
    'pantry_count': pantryCount,
    'weight_logs_count': weightLogsCount,
    'has_user_profile': hasUserProfile,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMetadata &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          filename == other.filename &&
          sizeBytes == other.sizeBytes &&
          exportDate == other.exportDate &&
          mealsCount == other.mealsCount &&
          pantryCount == other.pantryCount &&
          weightLogsCount == other.weightLogsCount &&
          hasUserProfile == other.hasUserProfile;

  @override
  int get hashCode => Object.hash(
        path,
        filename,
        sizeBytes,
        exportDate,
        mealsCount,
        pantryCount,
        weightLogsCount,
        hasUserProfile,
      );
}

/// Immutable state tracking progress of data backup operations.
@immutable
class BackupProgress {
  static const Object _sentinel = Object();

  final BackupStatus status;
  final BackupOperationType operation;
  final File? exportedFile;
  final File? selectedFile;
  final BackupMetadata? metadata;
  final Map<String, int>? restoreResult;
  final String? errorMessage;
  final double progress;

  const BackupProgress({
    this.status = BackupStatus.idle,
    this.operation = BackupOperationType.none,
    this.exportedFile,
    this.selectedFile,
    this.metadata,
    this.restoreResult,
    this.errorMessage,
    this.progress = 0.0,
  });

  static const BackupProgress initial = BackupProgress();

  bool get isIdle => status == BackupStatus.idle;
  bool get isExporting => status == BackupStatus.exporting;
  bool get isPicking => status == BackupStatus.picking;
  bool get isInspecting => status == BackupStatus.inspecting;
  bool get isRestoring => status == BackupStatus.restoring;
  bool get isBusy =>
      status == BackupStatus.exporting ||
      status == BackupStatus.picking ||
      status == BackupStatus.inspecting ||
      status == BackupStatus.restoring;
  bool get hasError => status == BackupStatus.error;
  bool get hasSuccess => status == BackupStatus.success;

  BackupProgress copyWith({
    BackupStatus? status,
    BackupOperationType? operation,
    Object? exportedFile = _sentinel,
    Object? selectedFile = _sentinel,
    Object? metadata = _sentinel,
    Object? restoreResult = _sentinel,
    Object? errorMessage = _sentinel,
    double? progress,
  }) {
    return BackupProgress(
      status: status ?? this.status,
      operation: operation ?? this.operation,
      exportedFile: identical(exportedFile, _sentinel)
          ? this.exportedFile
          : (exportedFile as File?),
      selectedFile: identical(selectedFile, _sentinel)
          ? this.selectedFile
          : (selectedFile as File?),
      metadata: identical(metadata, _sentinel)
          ? this.metadata
          : (metadata as BackupMetadata?),
      restoreResult: identical(restoreResult, _sentinel)
          ? this.restoreResult
          : (restoreResult as Map<String, int>?),
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : (errorMessage as String?),
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupProgress &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          operation == other.operation &&
          exportedFile?.path == other.exportedFile?.path &&
          selectedFile?.path == other.selectedFile?.path &&
          metadata == other.metadata &&
          mapEquals(restoreResult, other.restoreResult) &&
          errorMessage == other.errorMessage &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(
        status,
        operation,
        exportedFile?.path,
        selectedFile?.path,
        metadata,
        restoreResult == null ? null : Object.hashAll(restoreResult!.entries),
        errorMessage,
        progress,
      );
}
