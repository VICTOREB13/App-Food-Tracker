import 'dart:io';
import 'package:food_tracker/features/data_backup/data_backup.controller.dart';

/// Legacy service facade delegating to DataBackupController.
/// Maintained for backwards compatibility across existing controllers and dialogs (< 300 LoC).
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// Resolves the dedicated local directory for JSON backups.
  Future<Directory> getBackupDirectory() =>
      DataBackupController.instance.resolveBackupDirectory();

  /// Exports full database snapshot to an indented JSON string.
  Future<String> exportToJsonString() =>
      DataBackupController.instance.exportToJsonString();

  /// Exports full database snapshot directly into a physical `.json` file.
  Future<File> exportToJsonFile({String? customDirectoryPath}) =>
      DataBackupController.instance.exportBackup(customDirectoryPath: customDirectoryPath);

  /// Lists all `.json` backup files discovered in the default backup locations, sorted newest first.
  Future<List<File>> listAvailableBackups({String? customDirectoryPath}) =>
      DataBackupController.instance.listAvailableBackups(customDirectoryPath: customDirectoryPath);

  /// Inspects a backup file and returns metadata preview map.
  Future<Map<String, dynamic>> inspectBackupFile(File file) async {
    final meta = await DataBackupController.instance.inspectBackupFile(file);
    return meta.toMap();
  }

  /// Restores database content directly from a physical `.json` file.
  Future<Map<String, int>> importFromFile(File file) =>
      DataBackupController.instance.restoreBackup(file: file);

  /// Restores database content from raw JSON string with SQLite transaction guarantees.
  Future<Map<String, int>> importFromJsonString(String jsonContent) =>
      DataBackupController.instance.restoreBackup(jsonContent: jsonContent);
}
